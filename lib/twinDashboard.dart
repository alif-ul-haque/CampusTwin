import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';

/// ============================================================
/// TWIN DASHBOARD — CampusTwin
/// ============================================================
/// Home screen shown right after login. Matches the app's existing
/// visual language (AppColors, rounded 16/28 cards, soft borders,
/// purple/cyan accents) rather than default Material styling.
///
/// Wired with MOCK DATA for now — replace the block inside
/// `_loadDashboardData()` with real FastAPI calls. Every spot to hook
/// up is marked with // TODO.
/// ============================================================

enum StressLevel { low, medium, high }

class ScheduleItem {
  final String title;
  final TimeOfDay time;
  final String type; // "Class" or "Study Block"

  ScheduleItem({required this.title, required this.time, required this.type});
}

class DeadlineItem {
  final String title;
  final String course;
  final DateTime dueDate;

  DeadlineItem({required this.title, required this.course, required this.dueDate});

  int get daysLeft => dueDate.difference(DateTime.now()).inDays;
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  late final AnimationController _borderAnimController;

  String _studentName = 'Alif';
  StressLevel _stressLevel = StressLevel.medium;
  double _attendancePercent = 87;
  int _habitStreak = 5;
  double _budgetRemaining = 2400;
  List<ScheduleItem> _todaySchedule = [];
  List<DeadlineItem> _deadlines = [];

  final List<_DashboardTabItem> _tabs = const [
    _DashboardTabItem(label: 'Home', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
    _DashboardTabItem(label: 'Planner', icon: Icons.edit_calendar_outlined, activeIcon: Icons.edit_calendar_rounded),
    _DashboardTabItem(label: 'Habits', icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department_rounded),
    _DashboardTabItem(label: 'Budget', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded),
    _DashboardTabItem(label: 'Assistant', icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _borderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _borderAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    // TODO: Replace with real API calls, e.g.:
    //   final schedule   = await ApiService.getTodaySchedule(userId);
    //   final stress     = await ApiService.getStressPrediction(userId);
    //   final stats      = await ApiService.getQuickStats(userId);
    //   final deadlines  = await ApiService.getUpcomingDeadlines(userId);
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _todaySchedule = [
        ScheduleItem(title: 'Database Systems Lecture', time: const TimeOfDay(hour: 9, minute: 0), type: 'Class'),
        ScheduleItem(title: 'Study Block: Data Mining', time: const TimeOfDay(hour: 11, minute: 30), type: 'Study Block'),
        ScheduleItem(title: 'Software Engineering Lab', time: const TimeOfDay(hour: 14, minute: 0), type: 'Class'),
        ScheduleItem(title: 'Study Block: ML Assignment', time: const TimeOfDay(hour: 17, minute: 0), type: 'Study Block'),
      ];

      _deadlines = [
        DeadlineItem(title: 'ML Assignment 02 Submission', course: 'Machine Learning', dueDate: DateTime.now().add(const Duration(days: 1))),
        DeadlineItem(title: 'SDP Progress Report', course: 'Software Engineering', dueDate: DateTime.now().add(const Duration(days: 3))),
        DeadlineItem(title: 'ISO 27001 Audit Draft', course: 'Internship', dueDate: DateTime.now().add(const Duration(days: 6))),
      ]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

      _isLoading = false;
    });
  }

  Color _stressColor(StressLevel level) {
    switch (level) {
      case StressLevel.low:
        return const Color(0xFF16A34A);
      case StressLevel.medium:
        return const Color(0xFFD97706);
      case StressLevel.high:
        return const Color(0xFFDC2626);
    }
  }

  String _stressLabel(StressLevel level) {
    switch (level) {
      case StressLevel.low:
        return 'Low';
      case StressLevel.medium:
        return 'Medium';
      case StressLevel.high:
        return 'High';
    }
  }

  // ---------------- Animated gradient border wrapper ----------------
  // Wraps any card content with a slowly rotating multi-color border and
  // a matching soft glow shadow. All cards share `_borderAnimController`
  // so the color sweep stays perfectly in sync across the whole screen.
  Widget _animatedGlowCard({
    required Widget child,
    double radius = 16,
    double strokeWidth = 1.6,
    Color shadowColor = const Color(0xFF2563EB),
    List<Color> colors = const [
      Color(0xFF1E40AF),
      Color(0xFF3B82F6),
      Color(0xFF7DB4FF),
      Color(0xFF1E40AF),
    ],
  }) {
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
      child: _AnimatedBorderBox(
        animation: _borderAnimController,
        borderRadius: radius,
        strokeWidth: strokeWidth,
        colors: colors,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTwinnyButton = _selectedTabIndex != 4;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF6F9FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildCurrentTabBody(),
      ),
      floatingActionButton: showTwinnyButton
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Navigate to AI Assistant chat screen
                // Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantPage()));
              },
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.smart_toy_outlined),
              label: const Text(
                'Ask Twinny',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: _AnimatedBorderBox(
            animation: _borderAnimController,
            borderRadius: 32,
            strokeWidth: 2,
            fillColor: AppColors.card,
            colors: const [
              Color(0xFF4F46E5),
              Color(0xFF06B6D4),
              Color(0xFF7C3AED),
              Color(0xFF4F46E5),
            ],
            child: SizedBox(
              height: 68,
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.purple : AppColors.textSecondary,
                    );
                  }),
                ),
                child: NavigationBar(
                  height: 68,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: AppColors.purple.withValues(alpha: 0.12),
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  selectedIndex: _selectedTabIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  destinations: _tabs
                      .map(
                        (tab) => NavigationDestination(
                          icon: Icon(tab.icon),
                          selectedIcon: Icon(tab.activeIcon, color: AppColors.purple),
                          label: tab.label,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }

    switch (_selectedTabIndex) {
      case 0:
        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.purple,
            onRefresh: _loadDashboardData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 18),
                _buildQuickStats(),
                const SizedBox(height: 26),
                _buildSectionTitle("Today's Schedule"),
                const SizedBox(height: 10),
                _buildTodaySchedule(),
                const SizedBox(height: 26),
                _buildSectionTitle('Upcoming Deadlines'),
                const SizedBox(height: 10),
                _buildDeadlines(),
              ],
            ),
          ),
        );
      case 1:
        return _buildFeatureScreen(
          title: 'Study Planner',
          subtitle: 'Organize classes, revision slots, and assignment plans.',
          icon: Icons.edit_calendar_rounded,
          highlights: const [
            'Create weekly study blocks',
            'Track subject-wise progress',
            'Sync planner with class routine',
          ],
        );
      case 2:
        return _buildFeatureScreen(
          title: 'Habit Tracker',
          subtitle: 'Build consistent routines to improve focus and wellness.',
          icon: Icons.local_fire_department_rounded,
          highlights: const [
            'Add daily habits and reminders',
            'Track streaks and consistency',
            'See missed habits quickly',
          ],
        );
      case 3:
        return _buildFeatureScreen(
          title: 'Budget Tracker',
          subtitle: 'Manage your campus expenses and monthly budget goals.',
          icon: Icons.account_balance_wallet_rounded,
          highlights: const [
            'Log spending by category',
            'Set monthly budget caps',
            'Monitor remaining balance',
          ],
        );
      case 4:
        return _buildFeatureScreen(
          title: 'Twinny Assistant',
          subtitle: 'Ask for study help, reminders, and personalized suggestions.',
          icon: Icons.smart_toy_rounded,
          highlights: const [
            'Instant study support',
            'Smart schedule suggestions',
            'Stress-aware recommendations',
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFeatureScreen({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> highlights,
  }) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _animatedGlowCard(
            radius: 24,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.purple.withValues(alpha: 0.18),
                          AppColors.purpleLight.withValues(alpha: 0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.purple, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
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
            ),
          ),
          const SizedBox(height: 18),
          _buildSectionTitle('What you can do here'),
          const SizedBox(height: 10),
          ...highlights.map((point) => _buildFeaturePoint(point)),
          const SizedBox(height: 12),
          _emptyState('Feature screen ready. Connect this tab with your backend or detailed page next.'),
        ],
      ),
    );
  }

  Widget _buildFeaturePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _animatedGlowCard(
        radius: 16,
        strokeWidth: 1.2,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Header: Greeting + Date + Stress badge ----------------
  Widget _buildHeaderCard() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final dateStr = '${_weekdayName(now.weekday)}, ${_monthName(now.month)} ${now.day}';
    final stressColor = _stressColor(_stressLevel);

    return _animatedGlowCard(
      radius: 28,
      strokeWidth: 1.8,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            // Subtle decorative orbs — softened for a white card instead
            // of the vivid version used on the auth hero backdrop.
            Positioned(
              top: -30,
              right: -30,
              child: _orb(size: 110, color: const Color(0xFF3B82F6).withValues(alpha: 0.06)),
            ),
            Positioned(
              bottom: -34,
              left: -18,
              child: _orb(size: 90, color: const Color(0xFF3B82F6).withValues(alpha: 0.05)),
            ),
            Positioned(
              top: 18,
              left: 130,
              child: _orb(size: 20, color: const Color(0xFF3B82F6).withValues(alpha: 0.10)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.18)),
                        ),
                        child: const Text(
                          'CampusTwin',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$greeting,',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _studentName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            dateStr,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to Stress Detail View
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stressColor.withValues(alpha: 0.10),
                          border: Border.all(color: stressColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: stressColor.withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(Icons.bolt_rounded, color: stressColor, size: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_stressLabel(_stressLevel)} stress',
                        style: TextStyle(
                          color: stressColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // ---------------- Quick Stats Row ----------------
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.event_available_outlined,
            label: 'Attendance',
            value: '${_attendancePercent.toStringAsFixed(0)}%',
            accent: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.local_fire_department_outlined,
            label: 'Habit Streak',
            value: '$_habitStreak days',
            accent: AppColors.purpleLight,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Budget Left',
            value: '৳${_budgetRemaining.toStringAsFixed(0)}',
            accent: AppColors.purple,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return _animatedGlowCard(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.18), accent.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Section title ----------------
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

  // ---------------- Today's Schedule ----------------
  Widget _buildTodaySchedule() {
    if (_todaySchedule.isEmpty) {
      return _emptyState('No classes or study blocks today. Enjoy the free time!');
    }
    return Column(
      children: _todaySchedule.map((item) {
        final isClass = item.type == 'Class';
        final accent = isClass ? AppColors.purple : AppColors.purpleLight;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _animatedGlowCard(
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.5)],
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
                        const SizedBox(height: 2),
                        Text(
                          item.type,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.time.format(context),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------- Upcoming Deadlines ----------------
  Widget _buildDeadlines() {
    if (_deadlines.isEmpty) {
      return _emptyState("No upcoming deadlines. You're all caught up!");
    }
    return Column(
      children: _deadlines.map((d) {
        final urgent = d.daysLeft <= 2;
        final urgentColor = const Color(0xFFDC2626);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _animatedGlowCard(
            radius: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              color: urgent ? urgentColor.withValues(alpha: 0.06) : Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    urgent ? Icons.warning_amber_rounded : Icons.event_note_outlined,
                    color: urgent ? urgentColor : AppColors.purple,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          d.course,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    d.daysLeft <= 0 ? 'Due today' : '${d.daysLeft}d left',
                    style: TextStyle(
                      color: urgent ? urgentColor : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyState(String message) {
    return _animatedGlowCard(
      radius: 16,
      strokeWidth: 1.2,
      child: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}

class _DashboardTabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _DashboardTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Wraps [child] in a slowly rotating multi-color gradient border.
/// Pass a shared [animation] (0..1, repeating) so many boxes on screen
/// stay perfectly synchronized instead of drifting independently.
class _AnimatedBorderBox extends StatelessWidget {
  const _AnimatedBorderBox({
    required this.animation,
    required this.child,
    this.borderRadius = 16,
    this.strokeWidth = 1.6,
    this.fillColor = AppColors.card,
    this.colors = const [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF1E40AF)],
  });

  final Animation<double> animation;
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final Color fillColor;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return CustomPaint(
          painter: _RotatingBorderPainter(
            t: animation.value,
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
      },
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