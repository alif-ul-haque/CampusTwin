// ignore_for_file: unused_element

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_twin/models/app_models.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/app_widget.dart';
import 'package:campus_twin/twinDashboard.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/services/gemini_service.dart';

// =============================================================================
// DATA MODELS
// =============================================================================

/// Which wellness metric a card / chart refers to.
enum HabitType { sleep, water, exercise, screenTime, score }

/// A single trackable habit (Sleep, Water, Exercise, Screen Time).
class HabitMetric {
  final HabitType type;
  final String title;
  final IconData icon;
  final Color color;
  final double current;
  final double target;
  final String unit;
  final bool lowerIsBetter; // true for Screen Time
  final List<double> weekValues; // Mon..Sun
  final int streak;

  const HabitMetric({
    required this.type,
    required this.title,
    required this.icon,
    required this.color,
    required this.current,
    required this.target,
    required this.unit,
    required this.weekValues,
    required this.streak,
    this.lowerIsBetter = false,
  });

  /// 0..1 progress toward the goal (goal-aware for "lower is better" habits).
  double get progress {
    if (target <= 0) return 0;
    if (lowerIsBetter) {
      final ratio = current / target;
      return (2 - ratio).clamp(0.0, 1.0) / 1.0 > 1 ? 1.0 : (ratio <= 1 ? 1.0 : (2 - ratio).clamp(0.0, 1.0));
    }
    return (current / target).clamp(0.0, 1.0);
  }

  bool get isOnTrack => lowerIsBetter ? current <= target : current >= target * 0.8;

  HabitMetric copyWith({double? current}) => HabitMetric(
        type: type,
        title: title,
        icon: icon,
        color: color,
        current: current ?? this.current,
        target: target,
        unit: unit,
        weekValues: weekValues,
        streak: streak,
        lowerIsBetter: lowerIsBetter,
      );
}

/// A single AI-generated observation shown in the Insights section.
class AIInsight {
  final IconData icon;
  final Color color;
  final String tag;
  final String text;
  const AIInsight({required this.icon, required this.color, required this.tag, required this.text});
}

// =============================================================================
// DATA REPOSITORY (Firestore-backed)
// =============================================================================

class HabitRepository {
  static bool checkedInToday = false;
  static int checkInStreak = 0;

  static List<HabitMetric> metrics = [
    HabitMetric(
      type: HabitType.sleep,
      title: AppStrings.habitSleep,
      icon: Icons.bedtime_rounded,
      color: Color(0xFF6366F1),
      current: 0,
      target: 8,
      unit: 'hrs',
      weekValues: [0, 0, 0, 0, 0, 0, 0],
      streak: 0,
    ),
    HabitMetric(
      type: HabitType.water,
      title: AppStrings.habitWaterIntake,
      icon: Icons.water_drop_rounded,
      color: Color(0xFF06B6D4),
      current: 0,
      target: 3,
      unit: 'L',
      weekValues: [0, 0, 0, 0, 0, 0, 0],
      streak: 0,
    ),
    HabitMetric(
      type: HabitType.exercise,
      title: AppStrings.habitExercise,
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF10B981),
      current: 0,
      target: 45,
      unit: 'min',
      weekValues: [0, 0, 0, 0, 0, 0, 0],
      streak: 0,
    ),
    HabitMetric(
      type: HabitType.screenTime,
      title: AppStrings.habitScreenTime,
      icon: Icons.smartphone_rounded,
      color: Color(0xFFF59E0B),
      current: 0,
      target: 4,
      unit: 'hrs',
      weekValues: [0, 0, 0, 0, 0, 0, 0],
      streak: 0,
      lowerIsBetter: true,
    ),
  ];

  static List<double> scoreWeek = [0, 0, 0, 0, 0, 0, 0];

  /// true for each Mon–Sun slot that has a real Firestore log
  static List<bool> weekHasData = [false, false, false, false, false, false, false];

  static int habitScore = 0;

  // ── Native channel ───────────────────────────────────────────────────────
  static const _usageChannel = MethodChannel('campus_twin/usage_access');

  static Future<double> fetchRealScreenTime() async {
    try {
      final raw = await _usageChannel.invokeMethod<double>('getScreenTimeHours');
      return raw ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  // ── Habit score: Sleep 30% | Water 25% | Exercise 25% | Screen 20% ───────
  static int _computeHabitScore() {
    double score = 0;
    for (final m in metrics) {
      final weight = switch (m.type) {
        HabitType.sleep => 0.30,
        HabitType.water => 0.25,
        HabitType.exercise => 0.25,
        HabitType.screenTime => 0.20,
        HabitType.score => 0.0,
      };
      score += m.progress * weight * 100;
    }
    return score.round().clamp(0, 100);
  }

  static List<AIInsight> insights = [];
  static bool insightsLoaded = false;

  static Future<void> loadInsights() async {
    insights = _staticInsights();
    insightsLoaded = true;
    await _restoreFromDb();
  }

  static Future<void> generateInsightsFromAi() async {
    final data = metrics
        .map((m) => {
              'title': m.title,
              'current': m.current,
              'target': m.target,
              'unit': m.unit,
              'lower_is_better': m.lowerIsBetter,
              'week_values': m.weekValues,
              'streak': m.streak,
            })
        .toList();

    final prompt = '''
You are a wellness coach analyzing a student's weekly habit data (JSON below).
Return a JSON array of exactly 3 short insights. Each item must have:
tag (a short 1-2 word category, e.g. "Sleep Pattern"), text (one encouraging
or corrective sentence, under 25 words), icon (one of: sleep, water, exercise,
screen, stress, general).

Habit data: ${jsonEncode(data)}

Respond with ONLY the JSON array.
''';

    final raw = await GeminiService.instance.generateJson(prompt);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        insights = list.map((item) {
          final map = item as Map<String, dynamic>;
          final iconKey = map['icon'] as String? ?? 'general';
          return AIInsight(
            icon: _iconFor(iconKey),
            color: _colorFor(iconKey),
            tag: map['tag'] as String? ?? '',
            text: map['text'] as String? ?? '',
          );
        }).toList();
        await _savePrediction(insights);
      } catch (_) {}
    }
    if (insights.isEmpty) {
      insights = _staticInsights();
    }
    insightsLoaded = true;
  }

  static List<AIInsight> _staticInsights() => [
    AIInsight(
      icon: Icons.nightlight_round,
      color: const Color(0xFF6366F1),
      tag: AppStrings.sleepInsightTag,
      text: AppStrings.sleepInsight,
    ),
    AIInsight(
      icon: Icons.trending_up_rounded,
      color: const Color(0xFFF59E0B),
      tag: AppStrings.screenInsightTag,
      text: AppStrings.screenInsight,
    ),
    AIInsight(
      icon: Icons.self_improvement_rounded,
      color: const Color(0xFF10B981),
      tag: AppStrings.stressInsightTag,
      text: AppStrings.stressInsight,
    ),
  ];

  static int _derivedStressScore() {
    if (metrics.isEmpty) return 50;
    var total = 0.0;
    for (final m in metrics) {
      final ratio = m.target > 0 ? m.current / m.target : 0;
      total += ratio.clamp(0.0, 2.0);
    }
    final avg = total / metrics.length;
    return ((avg / 2) * 100).round().clamp(0, 100);
  }

  static String _levelFor(int score) {
    if (score < 40) return 'low';
    if (score <= 70) return 'moderate';
    return 'high';
  }

  static Future<void> _savePrediction(List<AIInsight> result) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || result.isEmpty) return;
      final score = _derivedStressScore();
      await FirebaseFirestore.instance.collection('stress_predictions').add({
        'user_id': uid,
        'score': score,
        'level': _levelFor(score),
        'explanation': result.map((i) => '${i.tag}: ${i.text}').join(' | '),
        'predicted_at': Timestamp.now(),
      });
    } catch (_) {}
  }

  static Future<void> _restoreFromDb() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('stress_predictions')
          .where('user_id', isEqualTo: uid)
          .orderBy('predicted_at', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;
      final explanation = snap.docs.first.data()['explanation'] as String?;
      if (explanation == null || explanation.trim().isEmpty) return;
      insights = explanation
          .split(' | ')
          .where((s) => s.trim().isNotEmpty)
          .map((s) {
            final parts = s.split(': ');
            if (parts.length == 1) {
              return AIInsight(
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.purple,
                  tag: 'Insight',
                  text: s);
            }
            return AIInsight(
              icon: Icons.auto_awesome_rounded,
              color: AppColors.purple,
              tag: parts.first,
              text: parts.skip(1).join(': '),
            );
          })
          .toList();
    } catch (_) {}
  }

  static IconData _iconFor(String key) => switch (key) {
        'sleep' => Icons.nightlight_round,
        'water' => Icons.water_drop_rounded,
        'exercise' => Icons.fitness_center_rounded,
        'screen' => Icons.smartphone_rounded,
        'stress' => Icons.self_improvement_rounded,
        _ => Icons.auto_awesome_rounded,
      };

  static Color _colorFor(String key) => switch (key) {
        'sleep' => const Color(0xFF6366F1),
        'water' => const Color(0xFF06B6D4),
        'exercise' => const Color(0xFF10B981),
        'screen' => const Color(0xFFF59E0B),
        'stress' => const Color(0xFF10B981),
        _ => AppColors.purple,
      };

  static double _valueOf(HabitType type) {
    final i = metrics.indexWhere((m) => m.type == type);
    if (i == -1) return 0;
    return metrics[i].current; // always return raw value, not ratio
  }

  static void updateMetric(HabitType type, double value) {
    final i = metrics.indexWhere((m) => m.type == type);
    if (i == -1) return;
    metrics[i] = metrics[i].copyWith(current: value);
    habitScore = _computeHabitScore();
  }

  static Future<void> persistToday() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final logDate = DateTime(now.year, now.month, now.day);
      final logs = FirebaseFirestore.instance.collection('habit_logs');
      // Merge manual screen time with real phone data
      final realScreen = await fetchRealScreenTime();
      final manualScreen = _valueOf(HabitType.screenTime);
      final screenToSave = manualScreen > 0 ? manualScreen : realScreen;
      final score = _computeHabitScore();
      final data = {
        'user_id': uid,
        'log_date': Timestamp.fromDate(logDate),
        'sleep_hours': _valueOf(HabitType.sleep),
        'exercise_minutes': _valueOf(HabitType.exercise).round(),
        'water_intake_liter': _valueOf(HabitType.water),
        'screen_time_hours': double.parse(screenToSave.toStringAsFixed(2)),
        'habit_score': score,
        'updated_at': Timestamp.now(),
      };
      final existing = await logs
          .where('user_id', isEqualTo: uid)
          .where('log_date', isEqualTo: Timestamp.fromDate(logDate))
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update(data);
      } else {
        await logs.add(data);
      }
    } catch (_) {}
  }


  static void checkIn() {
    checkedInToday = true;
    checkInStreak += 1;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Returns true when the user actually logged data for [type] that day
  /// (any non-zero entry counts — streak is about LOGGING, not goal-meeting).
  static bool _hasLoggedData(HabitType type, HabitLog log) {
    switch (type) {
      case HabitType.sleep:
        return log.sleepHours > 0;
      case HabitType.water:
        return log.waterIntakeLiter > 0;
      case HabitType.exercise:
        return log.exerciseMinutes > 0;
      case HabitType.screenTime:
        return log.screenTimeHours > 0;
      case HabitType.score:
        return true;
    }
  }

  /// Counts consecutive days going back from today where the user logged
  /// data for [type] (any non-zero value). Resets if a day is missing.
  static int _streakForType(HabitType type, List<HabitLog> sortedDesc) {
    if (sortedDesc.isEmpty) return 0;
    final todayDate = DateTime.now();
    final today = DateTime(todayDate.year, todayDate.month, todayDate.day);
    
    final todayLog = sortedDesc.firstWhere(
      (l) => _sameDay(l.logDate, today),
      orElse: () => HabitLog(
        id: '', userId: '', logDate: DateTime(1970),
        sleepHours: 0, exerciseMinutes: 0,
        waterIntakeLiter: 0, screenTimeHours: 0,
      ),
    );

    int streak = 0;
    DateTime check;
    if (todayLog.id.isNotEmpty && _hasLoggedData(type, todayLog)) {
      check = today;
    } else {
      check = today.subtract(const Duration(days: 1));
    }

    for (int i = 0; i <= sortedDesc.length; i++) {
      final log = sortedDesc.firstWhere(
        (l) => _sameDay(l.logDate, check),
        orElse: () => HabitLog(
          id: '', userId: '', logDate: DateTime(1970),
          sleepHours: 0, exerciseMinutes: 0,
          waterIntakeLiter: 0, screenTimeHours: 0,
        ),
      );
      if (log.id.isEmpty || !_hasLoggedData(type, log)) break;
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Loads last 30 days from Firestore, computes streaks per habit,
  /// week values for current Mon–Sun, habit score, and real screen time.
  static Future<void> loadFromDb() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Fetch screen time and logs in parallel
      final screenFuture = fetchRealScreenTime();
      final snap = await FirebaseFirestore.instance
          .collection('habit_logs')
          .where('user_id', isEqualTo: uid)
          .orderBy('log_date', descending: true)
          .limit(30)
          .get();
      final realScreen = await screenFuture;

      if (snap.docs.isNotEmpty) {
        final allLogs = snap.docs.map((d) => HabitLog.fromMap(d.id, d.data())).toList();
        final byDate = <String, HabitLog>{};
        for (final log in allLogs) {
          final k = '${log.logDate.year}-${log.logDate.month}-${log.logDate.day}';
          byDate.putIfAbsent(k, () => log);
        }

        // Current week Mon–Sun
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final weekLogs = List.generate(7, (i) {
          final d = monday.add(Duration(days: i));
          return byDate['${d.year}-${d.month}-${d.day}'];
        });

        final todayKey = '${today.year}-${today.month}-${today.day}';
        final todayLog = byDate[todayKey] ?? allLogs.first;

        final streaks = <HabitType, int>{};
        for (final t in [HabitType.sleep, HabitType.water, HabitType.exercise, HabitType.screenTime]) {
          streaks[t] = _streakForType(t, allLogs);
        }

        double valueFor(HabitType type, HabitLog log) {
          if (type == HabitType.screenTime && _sameDay(log.logDate, today) && realScreen > 0) {
            return realScreen;
          }
          return switch (type) {
            HabitType.sleep => log.sleepHours,
            HabitType.water => log.waterIntakeLiter,
            HabitType.exercise => log.exerciseMinutes.toDouble(),
            HabitType.screenTime => log.screenTimeHours,
            HabitType.score => 1.0,
          };
        }

        // Track which week slots have real data
        weekHasData = weekLogs.map((log) => log != null).toList();

        metrics = [
          for (final m in metrics)
            HabitMetric(
              type: m.type,
              title: m.title,
              icon: m.icon,
              color: m.color,
              current: valueFor(m.type, todayLog),
              target: m.target,
              unit: m.unit,
              weekValues: [
                for (final log in weekLogs)
                  log != null ? valueFor(m.type, log) : 0.0,
              ],
              streak: streaks[m.type] ?? 0,
              lowerIsBetter: m.lowerIsBetter,
            ),
        ];

        scoreWeek = weekLogs.map((log) {
          if (log == null) return 0.0;
          return _logScore(log);
        }).toList();

        habitScore = _computeHabitScore();
      } else {
        // No DB data yet (new user) — zero everything, auto-fill screen time only
        weekHasData = List.filled(7, false);
        scoreWeek = List.filled(7, 0.0);
        if (realScreen > 0) {
          final i = metrics.indexWhere((m) => m.type == HabitType.screenTime);
          if (i != -1) metrics[i] = metrics[i].copyWith(current: realScreen);
        }
        habitScore = 0;
      }

      // Check-in state
      final ciSnap = await FirebaseFirestore.instance
          .collection('daily_checkins')
          .where('user_id', isEqualTo: uid)
          .orderBy('checkin_date', descending: true)
          .limit(1)
          .get();
      if (ciSnap.docs.isNotEmpty) {
        final ci = DailyCheckIn.fromMap(ciSnap.docs.first.id, ciSnap.docs.first.data());
        checkedInToday = !ci.checkinDate.isBefore(today);
        checkInStreak = ci.dayNumber;
      }
    } catch (_) {}
  }

  /// Computes a 0–100 score for a stored log using the weighted formula.
  static double _logScore(HabitLog log) {
    final targets = {HabitType.sleep: 8.0, HabitType.water: 3.0, HabitType.exercise: 45.0, HabitType.screenTime: 4.0};
    final weights = {HabitType.sleep: 0.30, HabitType.water: 0.25, HabitType.exercise: 0.25, HabitType.screenTime: 0.20};
    double score = 0;
    final values = {HabitType.sleep: log.sleepHours, HabitType.water: log.waterIntakeLiter, HabitType.exercise: log.exerciseMinutes.toDouble(), HabitType.screenTime: log.screenTimeHours};
    for (final t in targets.keys) {
      final v = values[t]!;
      final tgt = targets[t]!;
      final w = weights[t]!;
      final progress = t == HabitType.screenTime
          ? (v <= tgt ? 1.0 : (2 - v / tgt).clamp(0.0, 1.0))
          : (v / tgt).clamp(0.0, 1.0);
      score += progress * w * 100;
    }
    return score;
  }

  static double _averageProgress() {
    if (metrics.isEmpty) return 0;
    return metrics.map((m) => m.progress).reduce((a, b) => a + b) / metrics.length;
  }
}

// =============================================================================
// HABIT TRACKER PAGE
// =============================================================================

class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage> with TickerProviderStateMixin {
  
  HabitType _selectedChart = HabitType.sleep;
  final int _navIndex = 2; // Habits tab selected

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    
    HabitRepository.loadFromDb().then((_) {
      HabitRepository.loadInsights();
      if (mounted) {
        setState(() {});
        if (!HabitRepository.checkedInToday) {
          _handleCheckIn();
        }
      }
    });
  }

  HabitMetric _metric(HabitType t) => HabitRepository.metrics.firstWhere((m) => m.type == t);

  // ── Log / edit bottom sheet ──────────────────────────────────────────────
  void _openLogSheet(HabitMetric metric) {
    final controller = TextEditingController(text: metric.current.toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
            decoration: BoxDecoration(
              color: AppPalette.card(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppPalette.border(context), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: metric.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(metric.icon, color: metric.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(AppStrings.logTitle(metric.title),
                        style: TextStyle(color: AppPalette.textPrimary(context), fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 20),
                AppFieldLabel(AppStrings.todaysValue(metric.unit)),
                const SizedBox(height: 10),
                AppTextField(
                  controller: controller,
                  hint: AppStrings.egValue(metric.target.toString()),
                  icon: metric.icon,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: AppStrings.saveEntry,
                  onPressed: () async {
                    final v = double.tryParse(controller.text.trim());
                    if (v == null) return;

                    // ── Threshold validation ──────────────────────────
                    final error = _validateThreshold(metric.type, v);
                    if (error != null) {
                      await showDialog<void>(
                        context: sheetContext,
                        builder: (ctx) => _ThresholdWarningDialog(
                          metricTitle: metric.title,
                          metricIcon: metric.icon,
                          metricColor: metric.color,
                          message: error,
                        ),
                      );
                      return; // do not save; keep sheet open for correction
                    }

                    Navigator.of(sheetContext).pop();
                    setState(() => HabitRepository.updateMetric(metric.type, v));
                    await HabitRepository.persistToday();
                    await HabitRepository.loadFromDb(); // Reload to update weekly charts & streaks
                    HabitRepository.loadInsights().then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns a human-readable error string if [value] exceeds the safe
  /// threshold for [type], or null if the value is acceptable.
  String? _validateThreshold(HabitType type, double value) {
    switch (type) {
      case HabitType.sleep:
        if (value > 15) {
          return 'Sleep duration of ${value.toStringAsFixed(1)} hrs is too high.\n\n'
              'Sleeping more than 15 hours a day may indicate hypersomnia or an '
              'underlying health condition. Please enter a realistic value (max 15 hrs).';
        }
        if (value < 0) return 'Sleep hours cannot be negative.';
        return null;
      case HabitType.water:
        if (value > 7) {
          return 'Water intake of ${value.toStringAsFixed(1)} L is dangerously high.\n\n'
              'Drinking more than 7 litres per day can cause hyponatraemia (water '
              'intoxication), which is a serious medical risk. Please enter a realistic '
              'value (max 7 L).';
        }
        if (value < 0) return 'Water intake cannot be negative.';
        return null;
      case HabitType.exercise:
        if (value > 180) {
          return 'Exercise of ${value.toInt()} minutes is above the safe limit.\n\n'
              'More than 180 minutes (3 hours) of continuous exercise per day '
              'increases injury risk and can lead to overtraining syndrome. '
              'Please enter a realistic value (max 180 min).';
        }
        if (value < 0) return 'Exercise minutes cannot be negative.';
        return null;
      case HabitType.screenTime:
        if (value < 0) return 'Screen time cannot be negative.';
        return null; // Screen time has no hard upper cap in the app
      case HabitType.score:
        return null;
    }
  }

  Future<void> _handleCheckIn() async {
    if (HabitRepository.checkedInToday) return;
    setState(() => HabitRepository.checkIn());
    // Persist check-in to Firestore
    await _persistCheckIn();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              const Text("Today's checkin done",
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }
  }

  // ── Shared visual helpers (mirrors app-wide section style) ──────────────

  Future<void> _persistCheckIn() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Find the previous check-in to calculate streak
      final prev = await FirebaseFirestore.instance
          .collection('daily_checkins')
          .where('user_id', isEqualTo: uid)
          .orderBy('checkin_date', descending: true)
          .limit(1)
          .get();

      int dayNumber = 1;
      if (prev.docs.isNotEmpty) {
        final lastDate = (prev.docs.first.data()['checkin_date'] as Timestamp).toDate();
        final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final yesterday = today.subtract(const Duration(days: 1));
        final prevStreak = prev.docs.first.data()['day_number'] as int? ?? 1;
        // Extend streak only if last check-in was yesterday
        if (lastDay == yesterday) {
          dayNumber = prevStreak + 1;
        } else if (lastDay == today) {
          return; // Already checked in today
        }
        // else streak resets to 1
      }

      await FirebaseFirestore.instance.collection('daily_checkins').add({
        'user_id': uid,
        'checkin_date': Timestamp.fromDate(today),
        'day_number': dayNumber,
        'reward_points': dayNumber * 10,
        'completed': true,
      });

      if (mounted) setState(() => HabitRepository.checkInStreak = dayNumber);
    } catch (_) {}
  }

  Widget _sectionTitle(String title, {String? trailing, IconData? leadingIcon}) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: AppPalette.textPrimary(context), fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        if (leadingIcon != null) ...[
          const SizedBox(width: 6),
          Icon(leadingIcon, size: 15, color: AppColors.purple),
        ],
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing, style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPalette.card(context),
              AppPalette.isDark(context)
                  ? AppPalette.darkBackground
                  : const Color(0xFFF6F9FF),
              AppPalette.card(context),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.yourHabits),
              const SizedBox(height: 12),
              _buildHabitCardsGrid(),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.habitStreaks, leadingIcon: Icons.local_fire_department_rounded),
              const SizedBox(height: 12),
              _buildStreakSection(),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.weeklyAnalytics),
              const SizedBox(height: 12),
              _buildAnalyticsCard(),
              const SizedBox(height: 24),
              _sectionTitle(AppStrings.aiInsights, leadingIcon: Icons.auto_awesome_rounded),
              const SizedBox(height: 12),
              _buildInsightsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── 1. Header ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.habitPageTitle,
                  style: TextStyle(color: AppPalette.textPrimary(context), fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text(AppStrings.habitSubtitle,
                  style: TextStyle(color: AppPalette.textSecondary(context).withValues(alpha: 0.85), fontSize: 13.5)),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.purple, AppColors.purpleLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  // ── 2. Today's Habit Summary ─────────────────────────────────────────
  Widget _buildSummaryCard() {
    final sleep = _metric(HabitType.sleep);
    final water = _metric(HabitType.water);
    final exercise = _metric(HabitType.exercise);
    final screen = _metric(HabitType.screenTime);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF163DDB), Color(0xFF2563EB), Color(0xFF22C1C3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 14))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(
                  painter: _RingProgressPainter(progress: HabitRepository.habitScore / 100, trackColor: Colors.white.withValues(alpha: 0.22), progressColor: Colors.white),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${HabitRepository.habitScore}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(AppStrings.score, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppStrings.todaysHabitSummary,
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                    const SizedBox(height: 6),
                    Text(
                      HabitRepository.habitScore >= 75 ? AppStrings.onTrackToday : AppStrings.keepStreakAlive,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _summaryChip(Icons.bedtime_rounded, '${sleep.current}h', AppStrings.habitSleep)),
              const SizedBox(width: 10),
              Expanded(child: _summaryChip(Icons.water_drop_rounded, '${water.current}L', AppStrings.habitWater)),
              const SizedBox(width: 10),
              Expanded(child: _summaryChip(Icons.fitness_center_rounded, '${exercise.current.toInt()}m', AppStrings.habitExercise)),
              const SizedBox(width: 10),
              Expanded(child: _summaryChip(Icons.smartphone_rounded, '${screen.current}h', AppStrings.habitScreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10.5)),
        ],
      ),
    );
  }

  // ── 3. Individual habit cards ─────────────────────────────────────────
  Widget _buildHabitCardsGrid() {
    return Column(
      children: HabitRepository.metrics.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HabitCard(metric: m, onEdit: () => _openLogSheet(m)),
          )).toList(),
    );
  }

  // ── 4. Habit streaks ─────────────────────────────────────────────────
  Widget _buildStreakSection() {
    final sleep = _metric(HabitType.sleep);
    final water = _metric(HabitType.water);
    final exercise = _metric(HabitType.exercise);
    return Row(
      children: [
        Expanded(child: _StreakTile(title: AppStrings.habitSleep, streak: sleep.streak, color: sleep.color)),
        const SizedBox(width: 10),
        Expanded(child: _StreakTile(title: AppStrings.hydration, streak: water.streak, color: water.color)),
        const SizedBox(width: 10),
        Expanded(child: _StreakTile(title: AppStrings.habitExercise, streak: exercise.streak, color: exercise.color)),
      ],
    );
  }

  // ── 5. Weekly analytics ───────────────────────────────────────────────
  Widget _buildAnalyticsCard() {
    final chips = <(HabitType, String)>[
      (HabitType.sleep, AppStrings.habitSleep),
      (HabitType.exercise, AppStrings.habitExercise),
      (HabitType.screenTime, AppStrings.habitScreenTime),
      (HabitType.score, AppStrings.score),
    ];

    List<double> values;
    Color color;
    String unit;
    bool lowerIsBetter;
    double standard;

    if (_selectedChart == HabitType.score) {
      values = HabitRepository.scoreWeek;
      color = AppColors.purple;
      unit = '%';
      lowerIsBetter = false;
      standard = 70; // ≥70% habit score is considered on-track
    } else {
      final m = _metric(_selectedChart);
      values = m.weekValues;
      color = m.color;
      unit = m.unit;
      lowerIsBetter = m.lowerIsBetter;
      standard = m.target;
    }

    // Only consider days that actually have a log
    final hasData = HabitRepository.weekHasData;
    final daysWithData = hasData.where((b) => b).length;

    // Max over days-with-data only (avoid dividing by empty)
    final dataValues = [for (int i = 0; i < values.length; i++) if (hasData[i]) values[i]];
    final maxVal = dataValues.isEmpty ? 1.0 : dataValues.reduce((a, b) => a > b ? a : b).clamp(0.001, double.infinity);

    // Average only over days with real data
    final avg = daysWithData == 0 ? 0.0 : dataValues.reduce((a, b) => a + b) / daysWithData;

    bool meetsStandard(double v) =>
        lowerIsBetter ? v <= standard : v >= standard * 0.8;

    return _GlowCard(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Chip selector ───────────────────────────────────────
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = chips[i].$1 == _selectedChart;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedChart = chips[i].$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.purple : AppPalette.inputFill(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? AppColors.purple : AppPalette.border(context)),
                      ),
                      child: Text(chips[i].$2,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppPalette.textSecondary(context))),
                    ),
                  );
                },
              ),
            ),
            // ── Days logged subtitle ────────────────────────────────
            if (daysWithData < 7) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: AppPalette.textSecondary(context).withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    daysWithData == 0
                        ? 'No entries yet — start logging to see your chart'
                        : '$daysWithData of 7 days logged this week',
                    style: TextStyle(fontSize: 11, color: AppPalette.textSecondary(context).withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // ── Bar chart ───────────────────────────────────────────
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (i) {
                  final logged = hasData[i];
                  final ratio = logged ? (values[i] / maxVal).clamp(0.0, 1.0) : 0.0;
                  final today = DateTime.now();
                  final monday = today.subtract(Duration(days: today.weekday - 1));
                  final isToday = DateTime(monday.add(Duration(days: i)).year,
                          monday.add(Duration(days: i)).month,
                          monday.add(Duration(days: i)).day) ==
                      DateTime(today.year, today.month, today.day);
                  final met = logged && meetsStandard(values[i]);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ── Indicator ────────────────────────────────
                          if (logged)
                            Text(met ? '😊' : '😞', style: const TextStyle(fontSize: 14))
                          else
                            Text('—',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppPalette.textSecondary(context).withValues(alpha: 0.35),
                                    fontWeight: FontWeight.w700)),
                          const SizedBox(height: 3),
                          // ── Value label ──────────────────────────────
                          Text(
                            logged
                                ? (values[i] % 1 == 0
                                    ? values[i].toInt().toString()
                                    : values[i].toStringAsFixed(1))
                                : '',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppPalette.textSecondary(context).withValues(alpha: 0.65),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // ── Bar ──────────────────────────────────────
                          logged
                              ? AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutCubic,
                                  height: (88 * ratio).clamp(4.0, 88.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        isToday ? color : color.withValues(alpha: 0.55),
                                        isToday
                                            ? color.withValues(alpha: 0.75)
                                            : color.withValues(alpha: 0.25),
                                      ],
                                    ),
                                    boxShadow: isToday
                                        ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                        : null,
                                  ),
                                )
                              // No-data placeholder bar
                              : Container(
                                  height: 20,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppPalette.border(context).withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 6),
                          // ── Day label ────────────────────────────────
                          Text(
                            _weekdayLabels[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday
                                  ? color
                                  : AppPalette.textSecondary(context),
                              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            // ── Legend / average row ────────────────────────────────
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  daysWithData == 0
                      ? 'No data yet'
                      : AppStrings.thisWeekAvg(avg.toStringAsFixed(1), unit),
                  style: TextStyle(fontSize: 11.5, color: AppPalette.textSecondary(context)),
                ),
                const Spacer(),
                if (daysWithData > 0) ...[
                  const Text('😊', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(AppStrings.metLabel,
                      style: TextStyle(fontSize: 11, color: AppPalette.textSecondary(context))),
                  const Text('😞', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  Text(AppStrings.belowLabel,
                      style: TextStyle(fontSize: 11, color: AppPalette.textSecondary(context))),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. AI insights ────────────────────────────────────────────────────
  Widget _buildInsightsSection() {
    if (!HabitRepository.insightsLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }
    if (HabitRepository.insights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          AppSettings.instance.locale.languageCode == 'bn'
              ? 'এই মুহূর্তে কোনো ইনসাইট পাওয়া যাচ্ছে না।'
              : 'No insights available right now.',
          style: TextStyle(
            color: AppPalette.textSecondary(context),
            fontSize: 12.5,
          ),
        ),
      );
    }
    return Column(
      children: HabitRepository.insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [insight.color.withValues(alpha: 0.10), insight.color.withValues(alpha: 0.02)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: insight.color.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: insight.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                    child: Icon(insight.icon, color: insight.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 12, color: insight.color.withValues(alpha: 0.85)),
                            const SizedBox(width: 4),
                            Text(insight.tag.toUpperCase(),
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: insight.color, letterSpacing: 0.4)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(insight.text, style: TextStyle(fontSize: 13, color: AppPalette.textPrimary(context), height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
    );
  }

  // ── Bottom navigation (visual match with rest of the app) ─────────────
  Widget _buildBottomNav() {
    final tabs = [
      (Icons.dashboard_outlined, Icons.dashboard_rounded, AppStrings.tabHome),
      (Icons.edit_calendar_outlined, Icons.edit_calendar_rounded, AppStrings.tabPlanner),
      (Icons.local_fire_department_outlined, Icons.local_fire_department_rounded, AppStrings.tabHabits),
      (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, AppStrings.tabBudget),
      (Icons.smart_toy_outlined, Icons.smart_toy_rounded, AppStrings.tabAssistant),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        border: Border(
          top: BorderSide(color: AppPalette.border(context), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final sel = states.contains(WidgetState.selected);
              return TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? AppColors.purple : AppPalette.textSecondary(context));
            }),
          ),
          child: NavigationBar(
            height: 68,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppColors.purple.withValues(alpha: 0.12),
            indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            selectedIndex: _navIndex,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              if (i == 0) {
                Navigator.of(context).maybePop();
                return;
              }
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => DashboardPage(initialTabIndex: i)),
              );
            },
            destinations: tabs
                .map((t) => NavigationDestination(icon: Icon(t.$1), selectedIcon: Icon(t.$2, color: AppColors.purple), label: t.$3))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE COMPONENTS
// =============================================================================

/// One habit row-card: icon, progress bar, value, edit button.
class _HabitCard extends StatelessWidget {
  final HabitMetric metric;
  final VoidCallback onEdit;
  const _HabitCard({required this.metric, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final pct = (metric.progress * 100).round();
    final statusColor = metric.isOnTrack ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return _GlowCard(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [metric.color.withValues(alpha: 0.18), metric.color.withValues(alpha: 0.06)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(metric.icon, color: metric.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(metric.title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppPalette.textPrimary(context))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                        child: Text(metric.isOnTrack ? AppStrings.onTrack : AppStrings.needsFocus,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${metric.current}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: metric.color)),
                      const SizedBox(width: 3),
                      Text(
                        AppSettings.instance.locale.languageCode == 'bn'
                            ? '${metric.unit} / ${metric.target.toInt()}${metric.unit} লক্ষ্য'
                            : '${metric.unit} / ${metric.target.toInt()}${metric.unit} goal',
                        style: TextStyle(fontSize: 12, color: AppPalette.textSecondary(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: metric.progress,
                      minHeight: 7,
                      backgroundColor: AppPalette.inputFill(context),
                      valueColor: AlwaysStoppedAnimation(metric.color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(AppStrings.dailyGoal(pct), style: TextStyle(fontSize: 11, color: AppPalette.textSecondary(context).withValues(alpha: 0.8))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: metric.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.add_rounded, color: metric.color, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gamified streak tile with a flame + streak count.
class _StreakTile extends StatelessWidget {
  final String title;
  final int streak;
  final Color color;
  const _StreakTile({required this.title, required this.streak, required this.color});

  @override
  Widget build(BuildContext context) {
    final active = streak > 0;
    return _GlowCard(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active
                    ? LinearGradient(colors: [color, color.withValues(alpha: 0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: active ? null : AppPalette.inputFill(context),
              ),
              child: Icon(Icons.local_fire_department_rounded, color: active ? Colors.white : AppPalette.textSecondary(context).withValues(alpha: 0.4), size: 22),
            ),
            const SizedBox(height: 8),
            Text('$streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppPalette.textPrimary(context))),
            Text(AppStrings.dayStreak, style: TextStyle(fontSize: 10, color: AppPalette.textSecondary(context))),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

/// Circular ring progress used by the summary card's habit score.
class _RingProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  _RingProgressPainter({required this.progress, required this.trackColor, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = progressColor;
    canvas.drawCircle(center, radius, track);
    const start = -1.5708; // -90deg
    final sweep = 6.28318 * progress.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingProgressPainter old) => old.progress != progress || old.progressColor != progressColor;
}

/// Styled alert shown when a logged value exceeds a safety threshold.
class _ThresholdWarningDialog extends StatelessWidget {
  final String metricTitle;
  final IconData metricIcon;
  final Color metricColor;
  final String message;

  const _ThresholdWarningDialog({
    required this.metricTitle,
    required this.metricIcon,
    required this.metricColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppPalette.card(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.12),
              blurRadius: 24, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon row ─────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Value Out of Range',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626))),
                      Row(
                        children: [
                          Icon(metricIcon, size: 13, color: metricColor),
                          const SizedBox(width: 4),
                          Text(metricTitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: metricColor)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.15)),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppPalette.textPrimary(context),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('OK, fix it',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft-shadow card wrapper — visual match with the rest of CampusTwin.
class _GlowCard extends StatelessWidget {
  final Widget child;
  final double radius;
  const _GlowCard({required this.child, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

/// Animated gradient-bordered box — same treatment as the app's bottom nav.
class _AnimatedBorderBox extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final Color fillColor;
  final List<Color> colors;

    const _AnimatedBorderBox({
    required this.animation,
    required this.child,
    this.borderRadius = 16,
    this.strokeWidth = 1.6,
    this.fillColor = AppColors.card,
    this.colors = const [
      Color(0xFFF1E40AF),
      Color(0xFFF3B82F6),
      Color(0xFFF1E40AF),
    ],
  });
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => CustomPaint(
        painter: _RotatingBorderPainter(t: animation.value, radius: borderRadius, strokeWidth: strokeWidth, colors: colors),
        child: Padding(
          padding: EdgeInsets.all(strokeWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular((borderRadius - strokeWidth).clamp(0, borderRadius)),
            child: ColoredBox(color: fillColor, child: child),
          ),
        ),
      ),
    );
  }
}

class _RotatingBorderPainter extends CustomPainter {
  final double t;
  final double radius;
  final double strokeWidth;
  final List<Color> colors;

  _RotatingBorderPainter({required this.t, required this.radius, required this.strokeWidth, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final sweepColors = [...colors, colors.first];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(colors: sweepColors, transform: GradientRotation(t * 2 * 3.14159265)).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RotatingBorderPainter old) => old.t != t || old.colors != colors;
}