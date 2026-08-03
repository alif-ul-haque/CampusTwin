import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';

// =============================================================================
// LEADERBOARD PAGE
// Three categories: Planner Stars | Habit Score | Screen Time (less = better)
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

// ── Mock data (replace with Firestore fetch) ──────────────────────────────────
const _mockUsers = [
  LeaderboardEntry(id: 'u1', name: 'Abu Salah Md. Jamil', avatar: 'AJ',
      avatarColor: Color(0xFF4F46E5), plannerStars: 42, habitScore: 88, screenMinutes: 95),
  LeaderboardEntry(id: 'u2', name: 'Riya Sharma', avatar: 'RS',
      avatarColor: Color(0xFF0891B2), plannerStars: 38, habitScore: 92, screenMinutes: 72),
  LeaderboardEntry(id: 'u3', name: 'Tanvir Ahmed', avatar: 'TA',
      avatarColor: Color(0xFF059669), plannerStars: 55, habitScore: 76, screenMinutes: 140),
  LeaderboardEntry(id: 'u4', name: 'Mehrin Noor', avatar: 'MN',
      avatarColor: Color(0xFFD97706), plannerStars: 60, habitScore: 95, screenMinutes: 60),
  LeaderboardEntry(id: 'u5', name: 'Sabbir Hossain', avatar: 'SH',
      avatarColor: Color(0xFFDC2626), plannerStars: 30, habitScore: 65, screenMinutes: 200),
  LeaderboardEntry(id: 'u6', name: 'Priya Das', avatar: 'PD',
      avatarColor: Color(0xFF7C3AED), plannerStars: 48, habitScore: 80, screenMinutes: 110),
  LeaderboardEntry(id: 'u7', name: 'Karim Uddin', avatar: 'KU',
      avatarColor: Color(0xFF0284C7), plannerStars: 22, habitScore: 55, screenMinutes: 170),
  LeaderboardEntry(id: 'u8', name: 'Nadia Islam', avatar: 'NI',
      avatarColor: Color(0xFF16A34A), plannerStars: 50, habitScore: 83, screenMinutes: 85),
];

const String _meId = 'u1';

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

  List<LeaderboardEntry> _sorted() {
    final list = List<LeaderboardEntry>.from(_mockUsers);
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
    final sorted = _sorted();
    final myRank = sorted.indexWhere((e) => e.id == _meId) + 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── White header + podium
            _buildHeader(myRank, sorted),
            // ── Tab bar
            _buildTabBar(),
            // ── Scrollable list
            Expanded(
              child: _buildList(sorted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(int myRank, List<LeaderboardEntry> sorted) {
    final top3 = sorted.take(3).toList();
    return Container(
      width: double.infinity,
      color: Colors.white,
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
              Text('Rank #$myRank',
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tab,
        tabs: const [
          Tab(text: '⭐  Planner'),
          Tab(text: '🔥  Habits'),
          Tab(text: '📱  Screen Time'),
        ],
        labelColor: AppColors.purple,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        indicatorColor: AppColors.purple,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.border,
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
        LeaderboardCategory.habit => '${e.habitScore} pts',
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
                    color: isMe ? AppColors.purple : AppColors.textPrimary),
              ),
              // Score
              Text(
                _value(e),
                style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
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
        LeaderboardCategory.planner => '${entry.plannerStars} stars',
        LeaderboardCategory.habit => '${entry.habitScore} pts',
        LeaderboardCategory.screenTime => '${entry.screenMinutes} min/day',
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
      '⭐${entry.plannerStars}  🔥${entry.habitScore}pts  📱${entry.screenMinutes}m';

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
          color: isMe ? AppColors.purple.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? AppColors.purple.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.5),
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
                            : AppColors.textSecondary)),
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
                                : AppColors.textPrimary)),
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
                      child: const Text('You',
                          style: TextStyle(
                              color: AppColors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(_scoreSummary(),
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textSecondary)),
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
