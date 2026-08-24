import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/theme.dart';

// =============================================================================
// LEADERBOARD PAGE
// Three categories: Planner Stars | Habit Score | Screen Time (less = better)
// All data is fetched from Firestore:
//   users           -> name / avatar
//   study_sessions  -> completed sessions -> planner streak (consecutive days)
//   habit_logs      -> habit_score + screen_time_hours (latest log per user)
// =============================================================================

enum LeaderboardCategory { planner, habit, screenTime }

class LeaderboardEntry {
  final String id;
  final String name;
  final String avatar;
  final Color avatarColor;
  final int plannerStars;
  final int habitScore;
  final int screenMinutes;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatar,
    required this.avatarColor,
    required this.plannerStars,
    required this.habitScore,
    required this.screenMinutes,
  });
}

// Ranking uses ONLY real registered users from Firestore — no mock data.
// When nothing can be loaded (signed out / offline) an empty state is shown.

String get _meId => FirebaseAuth.instance.currentUser?.uid ?? '';

// =============================================================================
// FIRESTORE LOADER
// =============================================================================

final _avatarPalette = [
  const Color(0xFF4F46E5), const Color(0xFF0891B2), const Color(0xFF059669),
  const Color(0xFFD97706), const Color(0xFFDC2626), const Color(0xFF7C3AED),
  const Color(0xFF0284C7), const Color(0xFF16A34A),
];

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

/// Current planner streak for [userId]: number of consecutive days ending at
/// the most recent day that has at least one completed study session.
int _plannerStreak(Set<String> completedDayKeys) {
  if (completedDayKeys.isEmpty) return 0;
  final now = DateTime.now();
  var day = DateTime(now.year, now.month, now.day);
  String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  // Streak may end today or yesterday (today's tasks may not be done yet)
  if (!completedDayKeys.contains(key(day))) {
    day = day.subtract(const Duration(days: 1));
    if (!completedDayKeys.contains(key(day))) return 0;
  }
  var streak = 0;
  while (completedDayKeys.contains(key(day))) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

Future<List<LeaderboardEntry>> loadLeaderboardFromDb() async {
  final db = FirebaseFirestore.instance;
  try {
    // 1. All registered users
    final usersSnap = await db.collection('users').limit(200).get();
    

    // 2. Completed study sessions per user -> planner streak
    final sessionsSnap = await db
        .collection('study_sessions')
        .where('completed', isEqualTo: true)
        .get();
    final completedDaysByUser = <String, Set<String>>{};
    for (final doc in sessionsSnap.docs) {
      final uid = doc.data()['user_id'] as String?;
      final date = (doc.data()['session_date'] as Timestamp?)?.toDate();
      if (uid == null || date == null) continue;
      final d = DateTime(date.year, date.month, date.day);
      completedDaysByUser.putIfAbsent(uid, () => {}).add(
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
          );
    }

    // 3. Latest habit log per user -> habit score & screen time
    final logsSnap = await db
        .collection('habit_logs')
        .orderBy('log_date', descending: true)
        .limit(500)
        .get();
    final latestHabitByUser = <String, Map<String, dynamic>>{};
    for (final doc in logsSnap.docs) {
      final uid = doc.data()['user_id'] as String?;
      if (uid == null || latestHabitByUser.containsKey(uid)) continue;
      latestHabitByUser[uid] = doc.data();
    }

    final entries = <LeaderboardEntry>[];
    for (final doc in usersSnap.docs) {
      final uid = doc.id;
      final name =
          (doc.data()['full_name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;

      final streak = _plannerStreak(completedDaysByUser[uid] ?? {});
      final habit = latestHabitByUser[uid];
      final habitScore =
          (habit?['habit_score'] as num?)?.toInt() ?? 0;
      final screenMinutes = (((habit?['screen_time_hours'] as num?)
                      ?.toDouble() ??
                  0) *
              60)
          .round();

      entries.add(LeaderboardEntry(
        id: uid,
        name: name,
        avatar: _initials(name),
        avatarColor: _avatarPalette[uid.hashCode.abs() % _avatarPalette.length],
        plannerStars: streak,
        habitScore: habitScore,
        screenMinutes: screenMinutes,
      ));
    }
    return entries;
  } catch (_) {
    return const [];
  }
}

// =============================================================================
// PAGE
// =============================================================================

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  LeaderboardCategory _cat = LeaderboardCategory.planner;
  bool get _isBn => AppSettings.instance.locale.languageCode == 'bn';
  Future<List<LeaderboardEntry>> load() => loadLeaderboardFromDb();
  late Future<List<LeaderboardEntry>> _entriesFuture = load();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    // Only fire when the tab has fully settled
    if (_tab.indexIsChanging) return;
    setState(() => _cat = LeaderboardCategory.values[_tab.index]);
  }

  @override
  void dispose() {
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    super.dispose();
  }

  List<LeaderboardEntry> _sorted(List<LeaderboardEntry> users) {
    final list = List<LeaderboardEntry>.from(users);
    switch (_cat) {
      case LeaderboardCategory.planner:
        list.sort((a, b) => b.plannerStars.compareTo(a.plannerStars));
      case LeaderboardCategory.habit:
        list.sort((a, b) => b.habitScore.compareTo(a.habitScore));
      case LeaderboardCategory.screenTime:
        list.sort((a, b) => a.screenMinutes.compareTo(b.screenMinutes));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background(context),
      appBar: AppBar(
        backgroundColor: AppPalette.background(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppPalette.textPrimary(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.leaderboardTitle,
          style: TextStyle(
            color: AppPalette.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<LeaderboardEntry>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data!;
            if (users.isEmpty) {
              return RefreshIndicator(
                color: AppColors.purple,
                onRefresh: () async {
                  final future = load();
                  setState(() => _entriesFuture = future);
                  await future;
                },
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        children: [
                          Icon(Icons.emoji_events_outlined,
                              size: 44,
                              color: AppPalette.textSecondary(context)
                                  .withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            _isBn
                                ? 'এখনো কোনো ব্যবহারকারী র‍্যাংকড নয়।'
                                : 'No ranked users yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppPalette.textSecondary(context),
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            final sorted = _sorted(users);
            final myRank = sorted.indexWhere((e) => e.id == _meId) + 1;
            return RefreshIndicator(
              color: AppColors.purple,
              onRefresh: () async {
                final future = loadLeaderboardFromDb();
                setState(() => _entriesFuture = future);
                await future;
              },
              child: Column(
                children: [
                  _buildHeader(myRank, sorted),
                  _buildTabBar(context),
                  Expanded(child: _buildList(sorted)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(int myRank, List<LeaderboardEntry> sorted) {
    final top3 = sorted.take(3).toList();
    return Container(
      width: double.infinity,
      color: AppPalette.card(context),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.purple, Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 14),
              const SizedBox(width: 5),
              Text(AppStrings.rankBadge(myRank),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 16),
          // Podium
          if (top3.length >= 3) _Podium(top3: top3, cat: _cat),
        ],
      ),
    );
  }


  // ── Tab bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: AppPalette.card(context),
      child: TabBar(
        controller: _tab,
        tabs: [
          Tab(text: AppStrings.plannerTab),
          Tab(text: AppStrings.habitsTab),
          Tab(text: AppStrings.screenTimeTab),
        ],
        labelColor: AppColors.purple,
        unselectedLabelColor: AppPalette.textSecondary(context),
        labelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.purple,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppPalette.border(context),
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────

  Widget _buildList(List<LeaderboardEntry> sorted) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _LeaderboardRow(
        entry: sorted[i],
        rank: i + 1,
        isMe: sorted[i].id == _meId,
        cat: _cat,
      ),
    );
  }
}

// =============================================================================
// PODIUM  (top 3)  –  fixed overflow by using IntrinsicHeight + flexible layout
// =============================================================================

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final LeaderboardCategory cat;
  const _Podium({required this.top3, required this.cat});

  String _value(LeaderboardEntry e) => switch (cat) {
        LeaderboardCategory.planner => '${e.plannerStars}⭐',
        LeaderboardCategory.habit => AppStrings.pts(e.habitScore),
        LeaderboardCategory.screenTime => '${e.screenMinutes}m',
      };

  @override
  Widget build(BuildContext context) {
    // Display order: 2nd | 1st | 3rd
    final entries = [top3[1], top3[0], top3[2]];
    final barHeights = [72.0, 96.0, 56.0];
    final ranks = [2, 1, 3];
    final medals = ['🥈', '🥇', '🥉'];
    final barColors = [
      [const Color(0xFF94A3B8), const Color(0xFF64748B)],   // silver
      [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],   // gold
      [const Color(0xFFCD7C2F), const Color(0xFFA0522D)],   // bronze
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final e = entries[i];
        final isMe = e.id == _meId;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Medal emoji
              Text(medals[i], style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: e.avatarColor,
                  borderRadius: BorderRadius.circular(13),
                  border: isMe
                      ? Border.all(color: AppColors.purple, width: 2.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: e.avatarColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Center(
                  child: Text(e.avatar,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 4),
              // Name
              Text(
                e.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe ? AppColors.purple : AppPalette.textPrimary(context)),
              ),
              // Score
              Text(
                _value(e),
                style: TextStyle(
                    fontSize: 10,
                    color: AppPalette.textSecondary(context),
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              // Bar
              Container(
                height: barHeights[i],
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: barColors[i],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Center(
                  child: Text('${ranks[i]}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// =============================================================================
// ROW WIDGET
// =============================================================================

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isMe;
  final LeaderboardCategory cat;

  const _LeaderboardRow({
    required this.entry,
    required this.rank,
    required this.isMe,
    required this.cat,
  });

  String _value() => switch (cat) {
        LeaderboardCategory.planner => AppStrings.stars(entry.plannerStars),
        LeaderboardCategory.habit => AppStrings.pts(entry.habitScore),
        LeaderboardCategory.screenTime => AppStrings.minPerDay(entry.screenMinutes),
      };

  Color _valueColor() => switch (cat) {
        LeaderboardCategory.planner => const Color(0xFFF59E0B),
        LeaderboardCategory.habit => const Color(0xFF10B981),
        LeaderboardCategory.screenTime => entry.screenMinutes < 90
            ? const Color(0xFF10B981)
            : entry.screenMinutes < 150
                ? const Color(0xFFD97706)
                : const Color(0xFFDC2626),
      };

  IconData _valueIcon() => switch (cat) {
        LeaderboardCategory.planner => Icons.star_rounded,
        LeaderboardCategory.habit => Icons.local_fire_department_rounded,
        LeaderboardCategory.screenTime => Icons.phone_android_rounded,
      };

  String _scoreSummary() =>
      AppStrings.streakSummary(entry.plannerStars, entry.habitScore, entry.screenMinutes);

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.purple.withValues(alpha: 0.06) : AppPalette.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? AppColors.purple.withValues(alpha: 0.3)
                : AppPalette.border(context).withValues(alpha: 0.5),
            width: isMe ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppColors.purple.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(children: [
          // Rank / medal
          SizedBox(
            width: 36,
            child: medal != null
                ? Text(medal,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22))
                : Text('#$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isMe
                            ? AppColors.purple
                            : AppPalette.textSecondary(context))),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: entry.avatarColor,
              borderRadius: BorderRadius.circular(13),
              border:
                  isMe ? Border.all(color: AppColors.purple, width: 2) : null,
              boxShadow: [
                BoxShadow(
                    color: entry.avatarColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Center(
              child: Text(entry.avatar,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          // Name + summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(entry.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isMe
                                ? AppColors.purple
                                : AppPalette.textPrimary(context))),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(AppStrings.you,
                          style: const TextStyle(
                              color: AppColors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(_scoreSummary(),
                    style: TextStyle(
                        fontSize: 10.5, color: AppPalette.textSecondary(context))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Score badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _valueColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _valueColor().withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_valueIcon(), color: _valueColor(), size: 12),
              const SizedBox(width: 4),
              Text(_value(),
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _valueColor())),
            ]),
          ),
        ]),
      ),
    );
  }
}
