import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/models/app_models.dart';
import 'package:campus_twin/repositories/app_repositories.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/services/gemini_service.dart';
import 'package:campus_twin/theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// =============================================================================
// DATA MODEL
// =============================================================================

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
}

// =============================================================================
// ASSISTANT REPOSITORY — Gemini-backed chat
//
// The public method signatures stay the same so the UI never changes.
// Replies are generated live via GeminiService (gemini-2.0-flash).
// =============================================================================

class _AssistantRepository {
  static List<AssistantMessage> chatMessages = [];
  static bool _historyLoaded = false;

  /// Role + behaviour rules for Twinny. The per-user data snapshot built by
  /// [_userContext] is appended after this before every Gemini call, so every
  /// answer is grounded in this user's live system state.
  static const _twinnyIdentity =
      'You are Twinny, a friendly campus assistant built into the CampusTwin '
      'app for this student. Below is the user\'s current live system data '
      '(profile, courses, assignments, budget, study plan, habits, stress). '
      'Rules:\n'
      '- When the question is about the user\'s own life, schedule, money or '
      'habits, answer from THIS data only and cite the actual numbers.\n'
      '- If a section is empty or missing, say you don\'t have that info yet '
      'instead of inventing it.\n'
      '- Be concise, warm and practical.\n'
      '- Answer in the same language the user writes in.';

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _money(double v) => v.round().toString();

  /// Snapshots this user's whole system state from Firestore into a compact,
  /// markdown-ish summary the Gemini system prompt can reference. Every domain
  /// is fetched independently and fails silently (offline) so one bad query
  /// never blocks a chat reply.
  static Future<String> _userContext() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return '[Not signed in — no user data available.]';
    final sb = StringBuffer();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (snap.exists) {
        final u = AppUser.fromMap(uid, snap.data() ?? {});
        sb.writeln('[PROFILE]');
        sb.writeln(
            'Name: ${u.fullName.trim() == '' ? 'unknown' : u.fullName.trim()}');
        sb.writeln(
            'Department: ${u.department.isEmpty ? 'not set' : u.department}');
        sb.writeln(
            'Semester: ${u.semester}${u.academicLevel != null ? ' · academic level ${u.academicLevel}' : ''}');
        sb.writeln(
            'Student ID: ${u.studentId.isEmpty ? 'not set' : u.studentId}');
        sb.writeln('Email: ${u.email}');
        sb.writeln('');
      }
    } catch (_) {}

    try {
      final courses = await CourseRepository().fetchByUser(uid);
      if (courses.isNotEmpty) {
        sb.writeln('[COURSES]');
        for (final c in courses) {
          sb.writeln(
              '- ${c.courseCode} ${c.courseTitle} · ${c.credit} cr · ${c.instructor} · attendance ${c.attendancePercent.toStringAsFixed(1)}%');
        }
        final assignments = await AssignmentRepository()
            .fetchForCourses(courses.map((c) => c.id).toList());
        final active = assignments
            .where((a) => a.status != AssignmentStatus.done)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        sb.writeln('');
        sb.writeln('[ASSIGNMENTS]');
        if (active.isEmpty) {
          sb.writeln('None pending right now.');
        } else {
          for (final a in active.take(12)) {
            final code = courses
                .where((c) => c.id == a.courseId)
                .map((c) => c.courseCode)
                .firstOrNull ??
                a.courseId;
            final d = a.dueDate;
            sb.writeln(
                '- [$code] ${a.title} · due ${d.year}-${_two(d.month)}-${_two(d.day)} · ${a.difficulty.name} · ${a.status.name}');
          }
        }
        sb.writeln('');
      }
    } catch (_) {}

    try {
      final now = DateTime.now();
      final month = '${now.year}-${_two(now.month)}';
      final budget = await BudgetRepository().fetchForMonth(uid, month);
      final expenses = await ExpenseRepository().fetchForMonth(uid, month);
      sb.writeln('[BUDGET — $month]');
      if (budget != null) {
        final spent =
            (budget.totalBudget - budget.remainingBudget).clamp(0.0, budget.totalBudget);
        sb.writeln(
            'Monthly budget: ${_money(budget.totalBudget)} · spent: ${_money(spent)} · remaining: ${_money(budget.remainingBudget)}');
      } else {
        sb.writeln('No budget set for this month yet.');
      }
      if (expenses.isNotEmpty) {
        final cats = await ExpenseCategoryRepository().fetchByUser(uid);
        sb.writeln('Recent transactions:');
        for (final e in expenses.take(8)) {
          final name = cats
              .where((c) => c.id == e.categoryId)
              .map((c) => c.categoryName)
              .firstOrNull ??
              e.categoryId;
          final d = e.expenseDate;
          final sign = e.type == 'income' ? '+' : '-';
          sb.writeln(
              '- $sign${_money(e.amount)} · $name · ${d.year}-${_two(d.month)}-${_two(d.day)}${(e.note ?? '').isNotEmpty ? ' (${e.note})' : ''}');
        }
      }
      sb.writeln('');
    } catch (_) {}

    try {
      final plans = await StudyPlanRepository()
          .fetchByUser(uid, orderBy: 'generated_date', descending: true, limit: 5);
      sb.writeln('[STUDY PLAN]');
      if (plans.isEmpty) {
        sb.writeln('No study plan generated yet.');
      } else {
        for (final p in plans) {
          final d = p.generatedDate;
          sb.writeln(
              '- Plan of ${d.year}-${_two(d.month)}-${_two(d.day)} · ${p.totalHours.toStringAsFixed(1)}h total · ${p.status.name}');
        }
      }
      sb.writeln('');
    } catch (_) {}

    try {
      final logs = await HabitLogRepository().fetchRecent(uid, days: 7);
      final goals = await FirebaseFirestore.instance
          .collection('habit_goals')
          .doc(uid)
          .get();
      sb.writeln('[HABITS — last 7 days]');
      if (goals.exists) {
        final g = goals.data() ?? {};
        sb.writeln(
            'Goals: sleep ${(g['sleep_hours'] as num?)?.toStringAsFixed(1) ?? '7.5'}h · water ${(g['water_liters'] as num?)?.toStringAsFixed(1) ?? '2.5'}L · exercise ${(g['exercise_minutes'] as num?) ?? 30}min · screen ≤ ${(g['screen_time_hours'] as num?)?.toStringAsFixed(1) ?? '3.0'}h');
      }
      if (logs.isEmpty) {
        sb.writeln('No habit logs yet.');
      } else {
        for (final l in logs.reversed) {
          final d = l.logDate;
          sb.writeln(
              '- ${d.year}-${_two(d.month)}-${_two(d.day)}: sleep ${l.sleepHours.toStringAsFixed(1)}h · water ${l.waterIntakeLiter.toStringAsFixed(1)}L · exercise ${l.exerciseMinutes}min · screen ${l.screenTimeHours.toStringAsFixed(2)}h');
        }
      }
      sb.writeln('');
    } catch (_) {}

    try {
      final p = await StressPredictionRepository().fetchLatest(uid);
      sb.writeln('[STRESS]');
      if (p == null) {
        sb.writeln('No stress prediction yet (computed from habit scores and on-device ML).');
      } else {
        final d = p.predictedAt;
        sb.writeln(
            'Latest: ${p.level} · score ${p.score}/100 · ${d.year}-${_two(d.month)}-${_two(d.day)}');
        if (p.explanation.isNotEmpty) sb.writeln('Explanation: ${p.explanation}');
      }
    } catch (_) {}

    final out = sb.toString().trim();
    return out.isEmpty ? '[No user data available.]' : out;
  }

  static String _greetingText() {
    final name = AppSettings.instance.profile.name.trim();
    return AppStrings.assistantGreeting(name.isEmpty ? 'Alif' : name);
  }

  /// Loads the user's chat history from `ai_chats` once per session.
  /// Falls back to a greeting bubble when the user has no history yet or the
  /// request fails (offline).
  static Future<void> initChat() async {
    if (_historyLoaded) return;
    _historyLoaded = true;
    if (chatMessages.isEmpty) {
      chatMessages = [
        AssistantMessage(
          id: 'greeting',
          text: _greetingText(),
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ];
    }
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('ai_chats')
          .where('user_id', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();
      if (snap.docs.isEmpty) return;
      final msgs = <AssistantMessage>[];
      for (final doc in snap.docs.reversed) {
        final chat = AIChat.fromMap(doc.id, doc.data());
        msgs.add(AssistantMessage(
          id: '${doc.id}-q',
          text: chat.question,
          isUser: true,
          timestamp: chat.createdAt,
        ));
        msgs.add(AssistantMessage(
          id: '${doc.id}-a',
          text: chat.response,
          isUser: false,
          timestamp: chat.createdAt,
        ));
      }
      chatMessages = msgs;
    } catch (_) {
      // Offline — keep the greeting bubble.
    }
  }

  /// Persists one Q&A turn as a single `ai_chats` document.
  static Future<void> _persistTurn(String question, String response) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('ai_chats').add({
        'user_id': uid,
        'question': question,
        'response': response,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Offline — the turn still shows in the session chat.
    }
  }

  static Future<void> sendMessage(String text, VoidCallback onUpdate) async {
    await initChat();
    chatMessages.add(AssistantMessage(
      id: 'a${chatMessages.length + 1}',
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    onUpdate();

    final context = await _userContext();
    final reply = await GeminiService.instance.sendMessage(
      text,
      systemPrompt: '$_twinnyIdentity\n\n'
          '=== THIS USER\'S CURRENT SYSTEM DATA ===\n'
          '$context',
    );

    chatMessages.add(AssistantMessage(
      id: 'a${chatMessages.length + 1}',
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
    ));
    onUpdate();

    await _persistTurn(text, reply);
  }
}

// =============================================================================
// ASSISTANT TAB
//
// Drop-in replacement for DashboardPage's old Assistant tab. Fully self
// contained — owns its own controllers, its own state, and its own mock
// repository, so it can be embedded anywhere with:
//
//   case 4: return const AssistantTab();
// =============================================================================

class AssistantTab extends StatefulWidget {
  const AssistantTab({super.key});

  @override
  State<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<AssistantTab> {
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _AssistantRepository.initChat().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _sendChat(String text) async {
    if (text.trim().isEmpty || _isSending) return;
    _isSending = true;
    _chatController.clear();
    setState(() {});

    await _AssistantRepository.sendMessage(text.trim(), () {
      if (mounted) setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollController.hasClients) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    _isSending = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final msgs = _AssistantRepository.chatMessages;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: _GlowCard(
              radius: 24,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.purple, AppColors.purpleLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.assistantTitle,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppPalette.textPrimary(context)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            AppStrings.assistantSubtitle,
                            style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: msgs.isEmpty
                ? _emptyChat(context)
                : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: msgs.length + (_isSending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == msgs.length) return _typingIndicator(context);
                      final m = msgs[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!m.isUser) ...[
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.purple, AppColors.purpleLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: m.isUser ? AppColors.purple : AppPalette.card(context),
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: m.isUser ? const Radius.circular(4) : null,
                                    bottomLeft: !m.isUser ? const Radius.circular(4) : null,
                                  ),
                                  border: m.isUser ? null : Border.all(color: AppPalette.border(context).withValues(alpha: 0.5)),
                                  boxShadow: m.isUser
                                      ? [
                                          BoxShadow(
                                            color: AppColors.purple.withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: MarkdownBody(
                                  data: m.text,
                                  selectable: true,
                                  styleSheet:
                                      _markdownStyle(context, _messageColor(m, context)),
                                ),
                              ),
                            ),
                            if (m.isUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_rounded, color: AppColors.purple, size: 18),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            decoration: BoxDecoration(
              color: AppPalette.card(context),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: AppStrings.askTwinnyHint,
                      filled: true,
                      fillColor: AppPalette.inputFill(context),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: _sendChat,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendChat(_chatController.text),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.purpleLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _messageColor(AssistantMessage m, BuildContext context) {
    if (m.isUser) return Colors.white;
    if (m.text.startsWith('Error:')) return const Color(0xFFDC2626);
    return AppPalette.textPrimary(context);
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context, Color base) {
    final isUser = base == Colors.white;
    final linkColor = isUser ? Colors.white : const Color(0xFF3B82F6);
    final codeBg = isUser
        ? Colors.white.withValues(alpha: 0.22)
        : AppPalette.inputFill(context);
    final borderColor = isUser
        ? Colors.white.withValues(alpha: 0.35)
        : AppPalette.border(context).withValues(alpha: 0.6);
    final baseStyle = TextStyle(color: base, fontSize: 13.5, height: 1.35);

    return MarkdownStyleSheet(
      a: baseStyle.copyWith(
        color: linkColor,
        decoration: TextDecoration.underline,
      ),
      p: baseStyle,
      strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      del: baseStyle.copyWith(decoration: TextDecoration.lineThrough),
      code: baseStyle.copyWith(
        fontSize: 12.5,
        fontFamily: 'monospace',
        backgroundColor: codeBg,
      ),
      codeblockPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      blockquote: baseStyle.copyWith(fontStyle: FontStyle.italic),
      blockquoteDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      listBullet: baseStyle,
      h1: baseStyle.copyWith(fontSize: 16.5, fontWeight: FontWeight.w800),
      h2: baseStyle.copyWith(fontSize: 15.5, fontWeight: FontWeight.w800),
      h3: baseStyle.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
      h4: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
      blockSpacing: 6,
      listIndent: 16,
      tableHead: baseStyle.copyWith(fontWeight: FontWeight.w700),
      tableBody: baseStyle,
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      tableCellsDecoration: BoxDecoration(
        border: Border.all(color: borderColor),
      ),
    );
  }

  Widget _typingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.purple, AppColors.purpleLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppPalette.card(context),
              borderRadius:
                  BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
              border: Border.all(
                color: AppPalette.border(context).withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '...',
              style: TextStyle(
                color: AppPalette.textSecondary(context),
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChat(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_outlined, size: 48, color: AppPalette.textSecondary(context).withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(AppStrings.askAnythingTitle, style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            AppStrings.askAnythingSubtitle,
            style: TextStyle(color: AppPalette.textSecondary(context).withValues(alpha: 0.6), fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// GLOW CARD (same visual wrapper used across CampusTwin pages)
// =============================================================================

class _GlowCard extends StatelessWidget {
  const _GlowCard({required this.child, this.radius = 16});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: _StaticBorderBox(borderRadius: radius, child: child),
    );
  }
}

class _StaticBorderBox extends StatelessWidget {
  const _StaticBorderBox({required this.child, this.borderRadius = 16});

  static const double _strokeWidth = 1.6;

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BorderPainter(radius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(_strokeWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((borderRadius - _strokeWidth).clamp(0, borderRadius)),
          child: ColoredBox(color: AppPalette.card(context), child: child),
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({required this.radius});

  static const double strokeWidth = 1.6;

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = const SweepGradient(
        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF7DB4FF), Color(0xFF1E40AF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter old) => old.radius != radius;
}