import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';

// =============================================================================
// DATA MODEL
// =============================================================================

class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  const AssistantMessage({
    required this.id, required this.text, required this.isUser, required this.timestamp,
  });
}

// =============================================================================
// MOCK REPOSITORY — Assistant chat
//
// Every method body should be replaced with a real API call. The public method
// signatures stay the same so the UI never changes.
//
// TODO: Replace with real backend:
//   GET  /assistant/{userId}/messages   → List<AssistantMessage>
//   POST /assistant/{userId}/messages   → { text }  →  AssistantMessage (bot reply)
// =============================================================================

class _AssistantRepository {
  static List<AssistantMessage> chatMessages = [];

  static void initChat() {
    if (chatMessages.isNotEmpty) return;
    chatMessages = [
      AssistantMessage(
        id: 'a1',
        text: 'Hi Alif! I\'m your Twinny assistant. How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  static void sendMessage(String text) {
    initChat();
    chatMessages.add(AssistantMessage(
      id: 'a${chatMessages.length + 1}', text: text, isUser: true, timestamp: DateTime.now(),
    ));
    final replies = [
      'Great question! Based on your upcoming deadlines, I\'d suggest focusing on your ML Assignment first — it\'s due tomorrow.',
      'I noticed your stress level is medium. A 15-minute break can help. Why not take a short walk?',
      'You\'re making good progress this week. Keep up the consistency!',
      'Good progress on Database Systems! You\'re at 72% of your weekly study target.',
      'Don\'t forget to review your study plan for tomorrow. I can help you reschedule if needed.',
    ];
    Future.delayed(const Duration(milliseconds: 600), () {
      chatMessages.add(AssistantMessage(
        id: 'a${chatMessages.length + 1}',
        text: replies[(chatMessages.length ~/ 2) % replies.length],
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
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

  @override
  void initState() {
    super.initState();
    _AssistantRepository.initChat();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _sendChat(String text) {
    if (text.trim().isEmpty) return;
    _AssistantRepository.sendMessage(text.trim());
    _chatController.clear();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.purple, AppColors.purpleLight],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Twinny Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          SizedBox(height: 2),
                          Text('Ask me anything about your studies', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
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
                ? _emptyChat()
                : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!m.isUser) ...[
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [AppColors.purple, AppColors.purpleLight],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                                  color: m.isUser ? AppColors.purple : AppColors.card,
                                  borderRadius: BorderRadius.circular(16).copyWith(
                                    bottomRight: m.isUser ? const Radius.circular(4) : null,
                                    bottomLeft: !m.isUser ? const Radius.circular(4) : null,
                                  ),
                                  border: m.isUser ? null : Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                                  boxShadow: m.isUser
                                      ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))]
                                      : null,
                                ),
                                child: Text(m.text, style: TextStyle(
                                  color: m.isUser ? Colors.white : AppColors.textPrimary,
                                  fontSize: 13.5, height: 1.35)),
                              ),
                            ),
                            if (m.isUser) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 32, height: 32,
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
              color: AppColors.card,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask Twinny...',
                      filled: true,
                      fillColor: AppColors.inputFill,
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
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.purple, AppColors.purpleLight],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text('Ask Twinny anything!', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Study tips, deadline help, stress advice…',
            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12.5)),
        ],
      ),
    );
  }
}

// =============================================================================
// GLOW CARD (same visual wrapper used across CampusTwin pages)
// =============================================================================

class _GlowCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double strokeWidth;
  const _GlowCard({required this.child, this.radius = 16, this.strokeWidth = 1.6});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: _StaticBorderBox(borderRadius: radius, strokeWidth: strokeWidth, child: child),
    );
  }
}

class _StaticBorderBox extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  const _StaticBorderBox({required this.child, this.borderRadius = 16, this.strokeWidth = 1.6});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BorderPainter(radius: borderRadius, strokeWidth: strokeWidth),
      child: Padding(
        padding: EdgeInsets.all(strokeWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((borderRadius - strokeWidth).clamp(0, borderRadius)),
          child: ColoredBox(color: AppColors.card, child: child),
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  _BorderPainter({required this.radius, required this.strokeWidth});

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
  bool shouldRepaint(covariant _BorderPainter old) => old.radius != radius || old.strokeWidth != strokeWidth;
}