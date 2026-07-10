import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/app_widget.dart';
import 'package:campus_twin/twinDashboard.dart';

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
// MOCK DATA REPOSITORY
//
// TODO: Replace with real endpoints, e.g.
//   GET  /habits/{userId}/today        -> today's HabitLog snapshot
//   GET  /habits/{userId}/week         -> last 7 HabitLog rows for charts
//   POST /habits/{userId}/log          -> body: { sleepHours, exerciseMinutes,
//                                                  waterIntakeLiter, screenTimeHours }
//   GET  /stress-prediction/{userId}/latest -> drives the AI Insights copy
//   POST /daily-checkin/{userId}       -> creates a DailyCheckIn row + streak
// =============================================================================

class _HabitRepository {
  static int habitScore = 78;
  static bool checkedInToday = false;
  static int checkInStreak = 5;

  static List<HabitMetric> metrics = [
    const HabitMetric(
      type: HabitType.sleep,
      title: 'Sleep',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF6366F1),
      current: 6.5,
      target: 8,
      unit: 'hrs',
      weekValues: [7.2, 6.8, 5.5, 6.0, 7.5, 8.1, 6.5],
      streak: 4,
    ),
    const HabitMetric(
      type: HabitType.water,
      title: 'Water Intake',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF06B6D4),
      current: 1.8,
      target: 3,
      unit: 'L',
      weekValues: [2.5, 2.8, 1.9, 2.2, 3.0, 2.6, 1.8],
      streak: 7,
    ),
    const HabitMetric(
      type: HabitType.exercise,
      title: 'Exercise',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF10B981),
      current: 25,
      target: 45,
      unit: 'min',
      weekValues: [30, 45, 0, 20, 40, 50, 25],
      streak: 2,
    ),
    const HabitMetric(
      type: HabitType.screenTime,
      title: 'Screen Time',
      icon: Icons.smartphone_rounded,
      color: Color(0xFFF59E0B),
      current: 5.4,
      target: 4,
      unit: 'hrs',
      weekValues: [4.5, 5.0, 6.2, 5.8, 4.9, 4.2, 5.4],
      streak: 0,
      lowerIsBetter: true,
    ),
  ];

  static const List<double> scoreWeek = [66, 71, 58, 69, 74, 82, 78];

  static const List<AIInsight> insights = [
    AIInsight(
      icon: Icons.nightlight_round,
      color: Color(0xFF6366F1),
      tag: 'Sleep pattern',
      text: 'You slept below 6 hours for 3 consecutive days. Try winding down 30 minutes earlier tonight.',
    ),
    AIInsight(
      icon: Icons.trending_up_rounded,
      color: Color(0xFFF59E0B),
      tag: 'Screen time',
      text: 'Your screen time increased noticeably this week, especially around exam days.',
    ),
    AIInsight(
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF10B981),
      tag: 'Stress & exercise',
      text: 'Staying consistent with exercise this week helped lower your predicted stress score.',
    ),
  ];

  static void updateMetric(HabitType type, double value) {
    final i = metrics.indexWhere((m) => m.type == type);
    if (i == -1) return;
    metrics[i] = metrics[i].copyWith(current: value);
  }

  static void checkIn() {
    checkedInToday = true;
    checkInStreak += 1;
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
  
  late final AnimationController _checkInPulseController;
  HabitType _selectedChart = HabitType.sleep;
  final int _navIndex = 2; // Habits tab selected

  static const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    
    _checkInPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    
    _checkInPulseController.dispose();
    super.dispose();
  }

  HabitMetric _metric(HabitType t) => _HabitRepository.metrics.firstWhere((m) => m.type == t);

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
            decoration: const BoxDecoration(
              color: AppColors.card,
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
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4)),
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
                    Text('Log ${metric.title}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 20),
                AppFieldLabel('Today\'s value (${metric.unit})'),
                const SizedBox(height: 10),
                AppTextField(
                  controller: controller,
                  hint: 'e.g. ${metric.target}',
                  icon: metric.icon,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 20),
                AppPrimaryButton(
                  label: 'Save entry',
                  onPressed: () {
                    final v = double.tryParse(controller.text.trim());
                    if (v != null) {
                      setState(() => _HabitRepository.updateMetric(metric.type, v));
                    }
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleCheckIn() {
    if (_HabitRepository.checkedInToday) return;
    setState(() => _HabitRepository.checkIn());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 8),
            Text('Checked in! Day ${_HabitRepository.checkInStreak} streak · +10 pts',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ── Shared visual helpers (mirrors app-wide section style) ──────────────
  Widget _sectionTitle(String title, {String? trailing, IconData? leadingIcon}) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        if (leadingIcon != null) ...[
          const SizedBox(width: 6),
          Icon(leadingIcon, size: 15, color: AppColors.purple),
        ],
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _HabitRepository.checkedInToday ? null : _buildCheckInButton(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF6F9FF), Colors.white],
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
              _sectionTitle('Your Habits'),
              const SizedBox(height: 12),
              _buildHabitCardsGrid(),
              const SizedBox(height: 24),
              _sectionTitle('Habit Streaks', leadingIcon: Icons.local_fire_department_rounded),
              const SizedBox(height: 12),
              _buildStreakSection(),
              const SizedBox(height: 24),
              _sectionTitle('Weekly Analytics'),
              const SizedBox(height: 12),
              _buildAnalyticsCard(),
              const SizedBox(height: 24),
              _sectionTitle('AI Insights', leadingIcon: Icons.auto_awesome_rounded),
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
              const Text('Habit Tracker',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Small daily habits, a stronger you.',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85), fontSize: 13.5)),
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
                  painter: _RingProgressPainter(progress: _HabitRepository.habitScore / 100, trackColor: Colors.white.withValues(alpha: 0.22), progressColor: Colors.white),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${_HabitRepository.habitScore}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const Text('Score', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
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
                    const Text("Today's Habit Summary",
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                    const SizedBox(height: 6),
                    Text(
                      _HabitRepository.habitScore >= 75
                          ? 'Great job — you\'re on track today!'
                          : 'A little more effort keeps your streak alive.',
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
              Expanded(child: _summaryChip(Icons.bedtime_rounded, '${sleep.current}h', 'Sleep')),
              const SizedBox(width: 10),
              Expanded(child: _summaryChip(Icons.water_drop_rounded, '${water.current}L', 'Water')),
              const SizedBox(width: 10),
              Expanded(child: _summaryChip(Icons.fitness_center_rounded, '${exercise.current.toInt()}m', 'Exercise')),
              const SizedBox(width: 10),
              Expanded(child: _summaryChip(Icons.smartphone_rounded, '${screen.current}h', 'Screen')),
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
      children: _HabitRepository.metrics.map((m) => Padding(
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
        Expanded(child: _StreakTile(title: 'Sleep', streak: sleep.streak, color: sleep.color)),
        const SizedBox(width: 10),
        Expanded(child: _StreakTile(title: 'Hydration', streak: water.streak, color: water.color)),
        const SizedBox(width: 10),
        Expanded(child: _StreakTile(title: 'Exercise', streak: exercise.streak, color: exercise.color)),
      ],
    );
  }

  // ── 5. Weekly analytics ───────────────────────────────────────────────
  Widget _buildAnalyticsCard() {
    final chips = <(HabitType, String)>[
      (HabitType.sleep, 'Sleep'),
      (HabitType.exercise, 'Exercise'),
      (HabitType.screenTime, 'Screen Time'),
      (HabitType.score, 'Habit Score'),
    ];

    List<double> values;
    Color color;
    String unit;
    bool lowerIsBetter;
    double standard;

    if (_selectedChart == HabitType.score) {
      values = _HabitRepository.scoreWeek;
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

    // Whether a given day's value meets the standard.
    bool meetsStandard(double v) =>
        lowerIsBetter ? v <= standard : v >= standard * 0.8;

    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return _GlowCard(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        color: selected ? AppColors.purple : AppColors.inputFill,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? AppColors.purple : AppColors.border),
                      ),
                      child: Text(chips[i].$2,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (i) {
                  final ratio = maxVal == 0 ? 0.0 : values[i] / maxVal;
                  final isLast = i == values.length - 1;
                  final met = meetsStandard(values[i]);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ── Emoji indicator ──────────────────────────
                          Text(
                            met ? '😊' : '😞',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          // ── Value label ──────────────────────────────
                          Text(
                            values[i] % 1 == 0
                                ? values[i].toInt().toString()
                                : values[i].toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 9.5,
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // ── Animated bar ──────────────────────────────
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: 88 * ratio.clamp(0.04, 1.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  isLast ? color : color.withValues(alpha: 0.55),
                                  isLast ? color.withValues(alpha: 0.7) : color.withValues(alpha: 0.25),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          // ── Day label ────────────────────────────────
                          Text(
                            _weekdayLabels[i],
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            // ── Legend row ─────────────────────────────────────────
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(
                  'This week · avg ${(values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1)} $unit',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Text('😊', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                const Text('met  ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const Text('😞', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                const Text('below', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. AI insights ────────────────────────────────────────────────────
  Widget _buildInsightsSection() {
    return Column(
      children: _HabitRepository.insights.map((insight) => Padding(
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
                        Text(insight.text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
    );
  }

  // ── Daily check-in button ─────────────────────────────────────────────
  Widget _buildCheckInButton() {
    final done = _HabitRepository.checkedInToday;
    return AnimatedBuilder(
      animation: _checkInPulseController,
      builder: (context, child) {
        final glow = done ? 0.0 : (0.15 + 0.15 * _checkInPulseController.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: (done ? const Color(0xFF10B981) : AppColors.purple).withValues(alpha: 0.35 + glow),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _handleCheckIn,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: done
                  ? [const Color(0xFF10B981), const Color(0xFF06B6D4)]
                  : [AppColors.purple, const Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(done ? Icons.check_circle_rounded : Icons.local_fire_department_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                done ? 'Checked in · Day ${_HabitRepository.checkInStreak}' : 'Daily Check-In',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom navigation (visual match with rest of the app) ─────────────
  Widget _buildBottomNav() {
    const tabs = [
      (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
      (Icons.edit_calendar_outlined, Icons.edit_calendar_rounded, 'Planner'),
      (Icons.local_fire_department_outlined, Icons.local_fire_department_rounded, 'Habits'),
      (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Budget'),
      (Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'Assistant'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
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
              return TextStyle(fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? AppColors.purple : AppColors.textSecondary);
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
                        child: Text(metric.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                        child: Text(metric.isOnTrack ? 'On track' : 'Needs focus',
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
                      Text('${metric.unit} / ${metric.target.toInt()}${metric.unit} goal',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: metric.progress,
                      minHeight: 7,
                      backgroundColor: AppColors.inputFill,
                      valueColor: AlwaysStoppedAnimation(metric.color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$pct% of daily goal', style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8))),
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
                color: active ? null : AppColors.inputFill,
              ),
              child: Icon(Icons.local_fire_department_rounded, color: active ? Colors.white : AppColors.textSecondary.withValues(alpha: 0.4), size: 22),
            ),
            const SizedBox(height: 8),
            Text('$streak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const Text('day streak', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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

/// Soft-shadow card wrapper — visual match with the rest of CampusTwin.
class _GlowCard extends StatelessWidget {
  final Widget child;
  final double radius;
  const _GlowCard({required this.child, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
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
    this.colors = const [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF1E40AF)],
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