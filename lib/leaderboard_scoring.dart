// =============================================================================
// LEADERBOARD SCORING
//
// Client-side aggregation into a SINGLE overall score per user (no category
// breakdown, no tabs). The overall is computed from two non-monetary sources,
// so NO budget / expense / amount data is ever read — other users' finances
// stay private.
//
//   Planner = streak (cap 30, 40%) + completed tasks 30d (cap 40, 35%)
//             + study minutes 30d (cap 2400, 25%)
//   Habits  = avg recent habit_score (85%) + check-in streak bonus (15%)
//
//   Overall = Planner*0.55 + Habits*0.45
//
// Data sources (read-only, no amounts):
//   users           -> name
//   study_sessions  -> planner streak / tasks / minutes
//   habit_logs      -> daily habit_score (already 0–100)
//   daily_checkins  -> check-in streak
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// One entry on the leaderboard: a single overall 0–100 point value.
class LeaderboardScore {
  final String id;
  final String name;
  final String avatar;
  final ColorValue avatarColor;
  final int overallScore;

  const LeaderboardScore({
    required this.id,
    required this.name,
    required this.avatar,
    required this.avatarColor,
    required this.overallScore,
  });
}

/// Minimal color holder so we don't depend on the UI palette here.
class ColorValue {
  final int value;
  const ColorValue(this.value);
}

// =============================================================================
// Ranking sort (by overall score)
// =============================================================================

int compareBy(LeaderboardScore a, LeaderboardScore b) {
  final v = b.overallScore.compareTo(a.overallScore);
  if (v != 0) return v;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

// =============================================================================
// Loader — computes the single overall score for every registered user
// =============================================================================

final _avatarPalette = [
  const ColorValue(0xFF4F46E5), const ColorValue(0xFF0891B2),
  const ColorValue(0xFF059669), const ColorValue(0xFFD97706),
  const ColorValue(0xFFDC2626), const ColorValue(0xFF7C3AED),
  const ColorValue(0xFF0284C7), const ColorValue(0xFF16A34A),
];

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String _dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Consecutive days (ending today or yesterday) that have at least one
/// completed study session.
int _streak(Set<String> completedDayKeys) {
  if (completedDayKeys.isEmpty) return 0;
  final now = DateTime.now();
  var day = DateTime(now.year, now.month, now.day);
  if (!completedDayKeys.contains(_dayKey(day))) {
    day = day.subtract(const Duration(days: 1));
    if (!completedDayKeys.contains(_dayKey(day))) return 0;
  }
  var streak = 0;
  while (completedDayKeys.contains(_dayKey(day))) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

int _plannerScore(int streak, int tasks, int minutes) {
  final s = (streak.clamp(0, 30) / 30) * 40;
  final t = (tasks.clamp(0, 40) / 40) * 35;
  final m = (minutes.clamp(0, 2400) / 2400) * 25;
  return (s + t + m).round().clamp(0, 100);
}

int _habitScore(int avgHabit, int checkInStreak) {
  final base = (avgHabit * 0.85);
  final streakBonus = (checkInStreak.clamp(0, 30) / 30) * 15;
  return (base + streakBonus).round().clamp(0, 100);
}

int _overallScore(int planner, int habit) =>
    (planner * 0.55 + habit * 0.45).round().clamp(0, 100);

/// Runs a Firestore query and returns its docs, or an empty list if the
/// query fails (permission denied, missing collection, or missing index).
Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _guarded(
    Future<QuerySnapshot<Map<String, dynamic>>> Function() run) async {
  try {
    final snap = await run();
    return snap.docs;
  } catch (e) {
    // ignore: avoid_print
    print('Leaderboard query skipped (${e.runtimeType}): $e');
    return const [];
  }
}

Future<List<LeaderboardScore>> loadLeaderboardScores() async {
  final db = FirebaseFirestore.instance;

  // 1. All registered users -> names
  final users = await _guarded(() => db.collection('users').limit(200).get());
  final names = <String, String>{};
  for (final doc in users) {
    final n = (doc.data()['full_name'] as String?)?.trim() ?? '';
    if (n.isNotEmpty) names[doc.id] = n;
  }
  if (names.isEmpty) return const [];

  // 2. Planner: completed sessions per user (30-day window for tasks/minutes)
  final since = DateTime.now().subtract(const Duration(days: 30));
  final streakSince = DateTime.now().subtract(const Duration(days: 60));
  final daysByUser = <String, Set<String>>{};
  final tasksByUser = <String, int>{};
  final minutesByUser = <String, int>{};
  final sessions = await _guarded(
      () => db.collection('study_sessions').where('completed', isEqualTo: true).get());
  for (final doc in sessions) {
    final uid = doc.data()['user_id'] as String?;
    if (uid == null || !names.containsKey(uid)) continue;
    final date = (doc.data()['session_date'] as Timestamp?)?.toDate();
    if (date == null) continue;
    if (!date.isBefore(streakSince)) {
      daysByUser.putIfAbsent(uid, () => {}).add(_dayKey(date));
    }
    if (!date.isBefore(since)) {
      tasksByUser[uid] = (tasksByUser[uid] ?? 0) + 1;
      final mins = (doc.data()['duration_minutes'] as num?)?.toInt() ?? 0;
      minutesByUser[uid] = (minutesByUser[uid] ?? 0) + mins;
    }
  }

  // 3. Habits: latest N habit logs per user (avg score)
  final recentScores = <String, List<int>>{};
  final logs = await _guarded(
      () => db.collection('habit_logs').orderBy('log_date', descending: true).limit(2000).get());
  for (final doc in logs) {
    final uid = doc.data()['user_id'] as String?;
    if (uid == null || !names.containsKey(uid)) continue;
    final list = recentScores.putIfAbsent(uid, () => []);
    if (list.length < 7) {
      list.add((doc.data()['habit_score'] as num?)?.toInt() ?? 0);
    }
  }

  // 4. Habits: check-in streak from daily_checkins
  final checkinByUser = <String, int>{};
  final checkins = await _guarded(
      () => db.collection('daily_checkins').orderBy('checkin_date', descending: true).limit(2000).get());
  for (final doc in checkins) {
    final uid = doc.data()['user_id'] as String?;
    if (uid == null || checkinByUser.containsKey(uid)) continue;
    checkinByUser[uid] = doc.data()['day_number'] as int? ?? 0;
  }

  // 5. Assemble a single overall score per user
  final entries = <LeaderboardScore>[];
  for (final uid in names.keys) {
    final planner = _plannerScore(
      _streak(daysByUser[uid] ?? {}),
      tasksByUser[uid] ?? 0,
      minutesByUser[uid] ?? 0,
    );

    final scores = recentScores[uid] ?? const [];
    final avgHabit = scores.isEmpty
        ? 0
        : (scores.reduce((a, b) => a + b) / scores.length).round();
    final checkIn = checkinByUser[uid] ?? 0;
    final habit = scores.isEmpty && checkIn == 0
        ? 0
        : _habitScore(avgHabit, checkIn);

    entries.add(LeaderboardScore(
      id: uid,
      name: names[uid] ?? '',
      avatar: _initials(names[uid] ?? ''),
      avatarColor: _avatarPalette[uid.hashCode.abs() % _avatarPalette.length],
      overallScore: _overallScore(planner, habit),
    ));
  }

  entries.sort(compareBy);
  return entries;
}
