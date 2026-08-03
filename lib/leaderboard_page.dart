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
  final String avatar; // initials
  final Color avatarColor;
  final int plannerStars;   // tasks completed across days
  final int habitScore;     // streak × completion %
  final int screenMinutes;  // daily avg screen time in minutes (less = better)

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

// ── Mock data (replace with Firestore fetch) ─────────────────────────────────
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

const String _meId = 'u1'; // current logged-in user

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
  late TabController _tab;
  LeaderboardCategory _cat = LeaderboardCategory.planner;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) {
        setState(() => _cat = LeaderboardCategory.values[_tab.index]);
      }
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  List<LeaderboardEntry> _sorted() {
    final list = List<LeaderboardEntry>.from(_mockUsers);
    switch (_cat) {
      case LeaderboardCategory.planner:
        list.sort((a, b) => b.plannerStars.compareTo(a.plannerStars));
      case LeaderboardCategory.habit:
        list.sort((a, b) => b.habitScore.compareTo(a.habitScore));
      case LeaderboardCategory.screenTime:
        list.sort((a, b) => a.screenMinutes.compareTo(b.screenMinutes)); // less = better
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted();
    final myRank = sorted.indexWhere((e) => e.id == _meId) + 1;
    final me = sorted.firstWhere((e) => e.id == _meId);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _buildHeader(myRank, me),
          _buildTabBar(),
          Expanded(child: _buildList(sorted)),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(int myRank, LeaderboardEntry me) {
    final top3 = _sorted().take(3).toList();
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Leaderboard', style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900,
                color: AppColors.textPrimary, letterSpacing: -0.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.purple, Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 5),
                Text('Rank #$myRank',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          // Podium (top 3)
          if (top3.length >= 3) _Podium(top3: top3, cat: _cat),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Tab bar ──────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    const labels = ['⭐ Planner', '🔥 Habits', '📱 Screen Time'];
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tab,
        tabs: labels.map((l) => Tab(text: l)).toList(),
        labelColor: AppColors.purple,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final e = sorted[i];
        final rank = i + 1;
        final isMe = e.id == _meId;
        return _LeaderboardRow(
          entry: e, rank: rank, isMe: isMe, cat: _cat,
        );
      },
    );
  }
}

// =============================================================================
// PODIUM WIDGET (top 3)
// =============================================================================

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;
  final LeaderboardCategory cat;
  const _Podium({required this.top3, required this.cat});

  String _value(LeaderboardEntry e) => switch (cat) {
    LeaderboardCategory.planner   => '${e.plannerStars}⭐',
    LeaderboardCategory.habit     => '${e.habitScore}pts',
    LeaderboardCategory.screenTime => '${e.screenMinutes}m',
  };

  @override
  Widget build(BuildContext context) {
    // order: 2nd, 1st, 3rd
    final order = [top3[1], top3[0], top3[2]];
    final heights = [80.0, 100.0, 65.0];
    final ranks = [2, 1, 3];
    final medals = ['🥈', '🥇', '🥉'];

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final e = order[i];
          final isMe = e.id == _meId;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(medals[i], style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: e.avatarColor,
                    borderRadius: BorderRadius.circular(14),
                    border: isMe ? Border.all(color: AppColors.purple, width: 2.5) : null,
                    boxShadow: [BoxShadow(
                        color: e.avatarColor.withValues(alpha: 0.35),
                        blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Text(e.avatar,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(height: 4),
                Text(e.name.split(' ').first,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: isMe ? AppColors.purple : AppColors.textPrimary)),
                Text(_value(e),
                    style: const TextStyle(fontSize: 10,
                        color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  height: heights[i],
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ranks[i] == 1
                          ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                          : ranks[i] == 2
                          ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
                          : [const Color(0xFFCD7C2F), const Color(0xFFA0522D)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Center(child: Text('${ranks[i]}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 18, fontWeight: FontWeight.w900))),
                ),
              ],
            ),
          );
        }),
      ),
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
    required this.entry, required this.rank,
    required this.isMe, required this.cat,
  });

  String _value() => switch (cat) {
    LeaderboardCategory.planner   => '${entry.plannerStars} stars',
    LeaderboardCategory.habit     => '${entry.habitScore} pts',
    LeaderboardCategory.screenTime => '${entry.screenMinutes} min/day',
  };

  Color _valueColor() => switch (cat) {
    LeaderboardCategory.planner   => const Color(0xFFF59E0B),
    LeaderboardCategory.habit     => const Color(0xFF10B981),
    LeaderboardCategory.screenTime => entry.screenMinutes < 90
        ? const Color(0xFF10B981) : entry.screenMinutes < 150
        ? const Color(0xFFD97706) : const Color(0xFFDC2626),
  };

  IconData _valueIcon() => switch (cat) {
    LeaderboardCategory.planner   => Icons.star_rounded,
    LeaderboardCategory.habit     => Icons.local_fire_department_rounded,
    LeaderboardCategory.screenTime => Icons.phone_android_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.purple.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe
                ? AppColors.purple.withValues(alpha: 0.3)
                : AppColors.border.withValues(alpha: 0.5),
            width: isMe ? 1.8 : 1,
          ),
          boxShadow: [BoxShadow(
            color: isMe
                ? AppColors.purple.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 3),
          )],
        ),
        child: Row(children: [
          // Rank
          SizedBox(width: 36,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 22), textAlign: TextAlign.center)
                : Text('#$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                        color: isMe ? AppColors.purple : AppColors.textSecondary)),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: entry.avatarColor,
              borderRadius: BorderRadius.circular(13),
              border: isMe ? Border.all(color: AppColors.purple, width: 2) : null,
              boxShadow: [BoxShadow(
                  color: entry.avatarColor.withValues(alpha: 0.3),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Center(child: Text(entry.avatar,
                style: const TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(entry.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                      color: isMe ? AppColors.purple : AppColors.textPrimary))),
              if (isMe) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('You',
                      style: TextStyle(color: AppColors.purple,
                          fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text(_scoreSummary(), style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
          ])),
          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _valueColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _valueColor().withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_valueIcon(), color: _valueColor(), size: 13),
              const SizedBox(width: 4),
              Text(_value(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                      color: _valueColor())),
            ]),
          ),
        ]),
      ),
    );
  }

  String _scoreSummary() {
    return '⭐${entry.plannerStars}  🔥${entry.habitScore}pts  📱${entry.screenMinutes}m';
  }
}
