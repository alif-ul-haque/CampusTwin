import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plannerItems = [
      const _PlannerItem(
        title: 'Database Systems lecture review',
        timeRange: '8:30 AM - 9:00 AM',
        type: 'Warm-up',
        note: 'Scan lecture slides before class starts.',
        accent: AppColors.purple,
      ),
      const _PlannerItem(
        title: 'Data Mining study block',
        timeRange: '11:30 AM - 1:00 PM',
        type: 'Focus block',
        note: 'Finish chapter summary and solve 2 practice problems.',
        accent: AppColors.purpleLight,
      ),
      const _PlannerItem(
        title: 'ML assignment sprint',
        timeRange: '5:00 PM - 6:15 PM',
        type: 'Assignment',
        note: 'Draft the solution outline and set next checkpoint.',
        accent: Color(0xFF0EA5E9),
      ),
    ];

    final plannerGoals = [
      const _PlannerGoal(
        label: 'Weekly target',
        detail: '12 focused study hours',
        progress: 0.72,
        icon: Icons.timer_outlined,
      ),
      const _PlannerGoal(
        label: 'Assignments',
        detail: '2 tasks due this week',
        progress: 0.45,
        icon: Icons.assignment_outlined,
      ),
      const _PlannerGoal(
        label: 'Revision',
        detail: '4 subjects queued',
        progress: 0.6,
        icon: Icons.menu_book_outlined,
      ),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _AnimatedGlowCard(
            radius: 28,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.purple.withValues(alpha: 0.18),
                              AppColors.purpleLight.withValues(alpha: 0.16),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.edit_calendar_rounded, color: AppColors.purple, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Study Planner',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Plan classes, revision, and assignment work in one place.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _PlannerBadge(label: 'Auto-scheduled'),
                      _PlannerBadge(label: 'Deadline aware'),
                      _PlannerBadge(label: 'Study focus'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('Planner overview'),
          const SizedBox(height: 10),
          Row(
            children: plannerGoals
                .map(
                  (goal) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _AnimatedGlowCard(
                        radius: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.purple.withValues(alpha: 0.16),
                                      AppColors.purpleLight.withValues(alpha: 0.10),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(goal.icon, color: AppColors.purple, size: 20),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                goal.label,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                goal.detail,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: goal.progress,
                                  minHeight: 6,
                                  backgroundColor: AppColors.border.withValues(alpha: 0.45),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('Today\'s plan'),
          const SizedBox(height: 10),
          ...plannerItems.map(_buildPlannerItemCard),
          const SizedBox(height: 18),
          _buildSectionTitle('Quick actions'),
          const SizedBox(height: 10),
          _AnimatedGlowCard(
            radius: 18,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add_task_rounded),
                          label: const Text('Add task'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.alarm_add_rounded),
                          label: const Text('Set reminder'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Generate study plan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerItemCard(_PlannerItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _AnimatedGlowCard(
        radius: 16,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [item.accent, item.accent.withValues(alpha: 0.45)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.note,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PlannerTag(label: item.type, color: item.accent),
                        _PlannerTag(label: item.timeRange, color: const Color(0xFF0EA5E9)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _PlannerItem {
  final String title;
  final String timeRange;
  final String type;
  final String note;
  final Color accent;

  const _PlannerItem({
    required this.title,
    required this.timeRange,
    required this.type,
    required this.note,
    required this.accent,
  });
}

class _PlannerGoal {
  final String label;
  final String detail;
  final double progress;
  final IconData icon;

  const _PlannerGoal({
    required this.label,
    required this.detail,
    required this.progress,
    required this.icon,
  });
}

class _PlannerBadge extends StatelessWidget {
  const _PlannerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlannerTag extends StatelessWidget {
  const _PlannerTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AnimatedGlowCard extends StatelessWidget {
  const _AnimatedGlowCard({
    required this.child,
    this.radius = 16,
    this.strokeWidth = 1.6,
    this.shadowColor = const Color(0xFF2563EB),
    this.colors = const [
      Color(0xFF1E40AF),
      Color(0xFF3B82F6),
      Color(0xFF7DB4FF),
      Color(0xFF1E40AF),
    ],
  });

  final Widget child;
  final double radius;
  final double strokeWidth;
  final Color shadowColor;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _StaticBorderBox(
        borderRadius: radius,
        strokeWidth: strokeWidth,
        colors: colors,
        child: child,
      ),
    );
  }
}

class _StaticBorderBox extends StatelessWidget {
  const _StaticBorderBox({
    required this.child,
    this.borderRadius = 16,
    this.strokeWidth = 1.6,
    this.fillColor = AppColors.card,
    this.colors = const [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF1E40AF)],
  });

  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final Color fillColor;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RotatingBorderPainter(
        t: 0,
        radius: borderRadius,
        strokeWidth: strokeWidth,
        colors: colors,
      ),
      child: Padding(
        padding: EdgeInsets.all(strokeWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((borderRadius - strokeWidth).clamp(0, borderRadius)),
          child: ColoredBox(
            color: fillColor,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _RotatingBorderPainter extends CustomPainter {
  _RotatingBorderPainter({
    required this.t,
    required this.radius,
    required this.strokeWidth,
    required this.colors,
  });

  final double t;
  final double radius;
  final double strokeWidth;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final sweepColors = [...colors, colors.first];
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        colors: sweepColors,
        transform: GradientRotation(t * 2 * 3.14159265),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RotatingBorderPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.colors != colors;
  }
}
