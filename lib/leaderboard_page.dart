import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/leaderboard_scoring.dart';

// =============================================================================
// LEADERBOARD PAGE
// A single, unified leaderboard ranking real registered users by a single
// Overall point value (Planner + Habits activity). No category tabs, no
// sensitive info — just names, avatars and one overall point per user.
// =============================================================================

String get _meId => FirebaseAuth.instance.currentUser?.uid ?? '';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});
  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool get _isBn => AppSettings.instance.locale.languageCode == 'bn';
  late Future<List<LeaderboardScore>> _entriesFuture = loadLeaderboardScores();

  Color _avatarColor(LeaderboardScore e) => Color(e.avatarColor.value);

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
        child: FutureBuilder<List<LeaderboardScore>>(
          future: _entriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _empty(
                icon: Icons.error_outline_rounded,
                message: _isBn
                    ? 'লিডারবোর্ড লোড করা যায়নি। আবার চেষ্টা করুন।'
                    : 'Could not load the leaderboard. Pull to retry.',
              );
            }
            final scores = snapshot.data ?? const <LeaderboardScore>[];
            if (scores.isEmpty) {
              return _empty(
                icon: Icons.emoji_events_outlined,
                message: _isBn
                    ? 'এখনো কোনো ব্যবহারকারী র‍্যাংকড নয়।'
                    : 'No ranked users yet.',
              );
            }
            final sorted = scores;
            final myRank = sorted.indexWhere((e) => e.id == _meId) + 1;
            return RefreshIndicator(
              color: AppColors.purple,
              onRefresh: _refresh,
              child: Column(
                children: [
                  _header(myRank, sorted),
                  Expanded(child: _list(sorted)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _empty({required IconData icon, required String message}) {
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(icon,
                    size: 44,
                    color: AppPalette.textSecondary(context)
                        .withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  message,
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

  Future<void> _refresh() async {
    final future = loadLeaderboardScores();
    setState(() => _entriesFuture = future);
    await future.catchError((_) => <LeaderboardScore>[]);
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _header(int myRank, List<LeaderboardScore> sorted) {
    final top3 = sorted.take(3).toList();
    return Container(
      width: double.infinity,
      color: AppPalette.card(context),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  AppStrings.pointsLeaders,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.textSecondary(context),
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            ],
          ),
          const SizedBox(height: 14),
          if (top3.length >= 3) _Podium(top3: top3),
        ],
      ),
    );
  }

  // ── List ─────────────────────────────────────────────────────────────────

  Widget _list(List<LeaderboardScore> sorted) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _LeaderboardRow(
        entry: sorted[i],
        rank: i + 1,
        isMe: sorted[i].id == _meId,
        avatarColor: _avatarColor(sorted[i]),
      ),
    );
  }
}

// =============================================================================
// PODIUM (top 3)
// =============================================================================

class _Podium extends StatelessWidget {
  final List<LeaderboardScore> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final entries = [top3[1], top3[0], top3[2]];
    final barHeights = [72.0, 96.0, 56.0];
    final ranks = [2, 1, 3];
    final medals = ['🥈', '🥇', '🥉'];
    final barColors = [
      [const Color(0xFF94A3B8), const Color(0xFF64748B)], // silver
      [const Color(0xFFFBBF24), const Color(0xFFF59E0B)], // gold
      [const Color(0xFFCD7C2F), const Color(0xFFA0522D)], // bronze
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
              Text(medals[i], style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(e.avatarColor.value),
                  borderRadius: BorderRadius.circular(13),
                  border: isMe
                      ? Border.all(color: AppColors.purple, width: 2.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                        color: Color(e.avatarColor.value).withValues(alpha: 0.35),
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
              Text(
                e.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isMe
                        ? AppColors.purple
                        : AppPalette.textPrimary(context)),
              ),
              Text(
                '${e.overallScore} ${AppStrings.points}',
                style: TextStyle(
                    fontSize: 10,
                    color: AppPalette.textSecondary(context),
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
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
// ROW
// =============================================================================

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardScore entry;
  final int rank;
  final bool isMe;
  final Color avatarColor;

  const _LeaderboardRow({
    required this.entry,
    required this.rank,
    required this.isMe,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1
        ? '🥇'
        : rank == 2
            ? '🥈'
            : rank == 3
                ? '🥉'
                : null;
    const trophy = AppColors.purple;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.purple.withValues(alpha: 0.06)
              : AppPalette.card(context),
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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: avatarColor,
              borderRadius: BorderRadius.circular(13),
              border: isMe
                  ? Border.all(color: AppColors.purple, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                    color: avatarColor.withValues(alpha: 0.3),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: trophy.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: trophy.withValues(alpha: 0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.emoji_events_rounded, color: trophy, size: 12),
              const SizedBox(width: 4),
              Text('${entry.overallScore}',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: trophy)),
            ]),
          ),
        ]),
      ),
    );
  }
}
