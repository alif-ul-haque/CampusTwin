import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/planner_page.dart';
import 'package:campus_twin/welcome_page.dart';

// =============================================================================
// DATA MODELS
// =============================================================================

enum StressLevel { low, medium, high }

class UserProfile {
  final String id;
  final String name;
  final String nickname;
  final String email;
  final String department;
  final String semester;
  final String session;
  final String phone;
  final List<String> enrolledCourses;

  const UserProfile({
    required this.id, required this.name, required this.nickname, required this.email,
    required this.department, required this.semester,
    this.session = '2022-2026', this.phone = '+880 1XXX-XXXXXX',
    this.enrolledCourses = const [],
  });
}

class ScheduleItem {
  final String id;
  final String title;
  final TimeOfDay time;
  final TimeOfDay endTime;
  final String type;
  final String? location;
  final bool isCompleted;
  const ScheduleItem({
    required this.id, required this.title, required this.time, required this.endTime,
    required this.type, this.location, this.isCompleted = false,
  });
  ScheduleItem copyWith({bool? isCompleted}) => ScheduleItem(
    id: id, title: title, time: time, endTime: endTime, type: type,
    location: location, isCompleted: isCompleted ?? this.isCompleted,
  );
}

class DeadlineItem {
  final String id;
  final String title;
  final String course;
  final DateTime dueDate;
  final String? courseCode;
  const DeadlineItem({
    required this.id, required this.title, required this.course,
    required this.dueDate, this.courseCode,
  });
  int get daysLeft => dueDate.difference(DateTime.now()).inDays;
  bool get isUrgent => daysLeft <= 2;
  bool get isOverdue => daysLeft < 0;
}

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
// MOCK DATA REPOSITORY
//
// SEMESTER TRANSITION — How subjects update when a new semester starts:
//
//   Step 1  User updates their courses in  Profile & Settings.
//           PUT /profile/update/{userId}   body: { enrolledCourses: [...] }
//
//   Step 2  Backend replaces  enrolledCourses  with the new semester's subjects.
//           Old study blocks from the planner are archived (not deleted).
//
//   Step 3  Frontend re-fetches:
//              GET /profile/{userId}              → updated UserProfile
//              GET /study-planner/{userId}         → new empty/archived plan
//              GET /dashboard/{userId}             → updated stats
//
//   No front-end code changes needed — the same models and widgets work with
//   the new data automatically.
// =============================================================================

class _DashboardRepository {
  // ── Profile ──────────────────────────────────────────────────────────
  // TODO: GET /profile/{userId}  →  UserProfile
  //       enrolledCourses drives what the Planner tab displays.
  static UserProfile get profile => const UserProfile(
    id: 'u1', name: 'Abu Salah Md. Jamil', nickname: 'Jamil',
    email: 'jamil@student.campustwin.edu',
    department: 'Computer Science & Engineering', semester: '6th Semester',
    session: '2022-2026', phone: '+880 1700-000001',
    enrolledCourses: ['CSE301', 'CSE302', 'CSE303', 'CSE402', 'CSE501', 'INT401'],
  );

  // ── Home tab ─────────────────────────────────────────────────────────
  static StressLevel stressLevel = StressLevel.medium;
  static double attendancePercent = 87;
  static int habitStreak = 5;
  static double budgetRemaining = 2400;
  static List<ScheduleItem> schedule = [];
  static List<DeadlineItem> deadlines = [];

  // ── Chart data ──────────────────────────────────────────────────────
  static List<double> weeklyHours = []; // Mon-Sun
  static Map<String, double> subjectDistribution = {};

  static void _initCharts() {
    if (weeklyHours.isNotEmpty) return;
    weeklyHours = [4, 6, 5, 3, 7, 2, 0];
    subjectDistribution = {
      'CSE301': 0.30, 'CSE402': 0.20, 'CSE501': 0.15,
      'CSE303': 0.25, 'CSE302': 0.10,
    };
  }

  static void loadDashboard() {
    _initCharts();
    if (schedule.isEmpty) {
      schedule = [
        const ScheduleItem(id: 's1', title: 'Database Systems Lecture', time: TimeOfDay(hour: 9, minute: 0), endTime: TimeOfDay(hour: 10, minute: 30), type: 'Class', location: 'Room 401'),
        const ScheduleItem(id: 's2', title: 'Data Mining Study Block', time: TimeOfDay(hour: 11, minute: 30), endTime: TimeOfDay(hour: 13, minute: 0), type: 'Study Block'),
        const ScheduleItem(id: 's3', title: 'Software Engineering Lab', time: TimeOfDay(hour: 14, minute: 0), endTime: TimeOfDay(hour: 15, minute: 30), type: 'Lab', location: 'Lab 3'),
        const ScheduleItem(id: 's4', title: 'ML Assignment Work', time: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 30), type: 'Study Block'),
      ];
    }
    if (deadlines.isEmpty) {
      final now = DateTime.now();
      deadlines = [
        DeadlineItem(id: 'd1', title: 'ML Assignment 02', course: 'Machine Learning', dueDate: now.add(const Duration(days: 1)), courseCode: 'CSE501'),
        DeadlineItem(id: 'd2', title: 'SDP Progress Report', course: 'Software Engineering', dueDate: now.add(const Duration(days: 3)), courseCode: 'CSE303'),
        DeadlineItem(id: 'd3', title: 'ISO 27001 Audit Draft', course: 'Internship', dueDate: now.add(const Duration(days: 6)), courseCode: 'INT401'),
        DeadlineItem(id: 'd4', title: 'Data Mining Quiz', course: 'Data Mining', dueDate: now.add(const Duration(days: 4)), courseCode: 'CSE402'),
      ]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    }
  }

  static void toggleScheduleComplete(String id) {
    final i = schedule.indexWhere((s) => s.id == id);
    if (i == -1) return;
    schedule[i] = schedule[i].copyWith(isCompleted: !schedule[i].isCompleted);
  }

  static void cycleStress() {
    stressLevel = switch (stressLevel) {
      StressLevel.low => StressLevel.medium,
      StressLevel.medium => StressLevel.high,
      StressLevel.high => StressLevel.low,
    };
  }

  // ── Assistant tab ────────────────────────────────────────────────────
  static List<AssistantMessage> chatMessages = [];

  static void initChat() {
    if (chatMessages.isNotEmpty) return;
    chatMessages = [AssistantMessage(id: 'a1', text: 'Hi Alif! I\'m your Twinny assistant. How can I help you today?', isUser: false, timestamp: DateTime.now())];
  }


  static void sendMessage(String text) {
    initChat();
    chatMessages.add(AssistantMessage(id: 'a${chatMessages.length + 1}', text: text, isUser: true, timestamp: DateTime.now()));
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
// DASHBOARD PAGE
// =============================================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  late final AnimationController _borderAnimController;
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _borderAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _borderAnimController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _DashboardRepository.loadDashboard();
    _DashboardRepository.initChat();
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _isLoading = false);
  }

  void _showProfile() {
    final p = _DashboardRepository.profile;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(
        profile: p,
        onSignOut: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
            (_) => false,
          );
        },
        onNavigateToPlanner: () {
          Navigator.of(context).pop();
          setState(() => _selectedTabIndex = 1);
        },
        onNavigateToHabits: () {
          Navigator.of(context).pop();
          setState(() => _selectedTabIndex = 2);
        },
        onNavigateToBudget: () {
          Navigator.of(context).pop();
          setState(() => _selectedTabIndex = 3);
        },
      ),
    );
  }

  // ── Tab items ────────────────────────────────────────────────────────
  static const _tabs = [
    _TabItem(label: 'Home', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded),
    _TabItem(label: 'Planner', icon: Icons.edit_calendar_outlined, activeIcon: Icons.edit_calendar_rounded),
    _TabItem(label: 'Habits', icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department_rounded),
    _TabItem(label: 'Budget', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded),
    _TabItem(label: 'Assistant', icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy_rounded),
  ];

  // ── Helpers ──────────────────────────────────────────────────────────
  String _wd(int w) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  String _mn(int m) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];

  Color _stressColor(StressLevel l) => switch (l) {
    StressLevel.low => const Color(0xFF16A34A),
    StressLevel.medium => const Color(0xFFD97706),
    StressLevel.high => const Color(0xFFDC2626),
  };

  String _stressLabel(StressLevel l) => switch (l) {
    StressLevel.low => 'Low', StressLevel.medium => 'Medium', StressLevel.high => 'High',
  };

  Widget _sectionTitle(String title, {String? trailing}) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(
          color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
          color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
        if (trailing != null) ...[
          const Spacer(),
          Text(trailing, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _emptyCard(IconData icon, String msg) {
    return _GlowCard(
      radius: 14, strokeWidth: 1.2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(msg, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFF6F9FF), Colors.white],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        )),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
            : _buildCurrentTab(),
      ),
      bottomNavigationBar: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
          child: _AnimatedBorderBox(
            animation: _borderAnimController,
            borderRadius: 32, strokeWidth: 2, fillColor: AppColors.card,
            colors: const [Color(0xFF4F46E5), Color(0xFF06B6D4), Color(0xFF7C3AED), Color(0xFF4F46E5)],
            child: SizedBox(
              height: 68,
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final sel = states.contains(WidgetState.selected);
                    return TextStyle(fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? AppColors.purple : AppColors.textSecondary);
                  }),
                ),
                child: NavigationBar(
                  height: 68, backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
                  elevation: 0, indicatorColor: AppColors.purple.withValues(alpha: 0.12),
                  indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  selectedIndex: _selectedTabIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (i) => setState(() => _selectedTabIndex = i),
                  destinations: _tabs.map((t) => NavigationDestination(
                    icon: Icon(t.icon), selectedIcon: Icon(t.activeIcon, color: AppColors.purple), label: t.label,
                  )).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTabIndex) {
      case 0: return _buildHomeTab();
      case 1: return const PlannerPage();
      case 2: return _buildHabitsTab();
      case 3: return _buildBudgetTab();
      case 4: return _buildAssistantTab();
      default: return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // HOME TAB
  // =========================================================================

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildQuickStats(),
            const SizedBox(height: 20),
            _buildVisualizationSection(),
            const SizedBox(height: 22),
            _sectionTitle('Today\'s Schedule', trailing: '${_DashboardRepository.schedule.where((s) => s.isCompleted).length}/${_DashboardRepository.schedule.length}'),
            const SizedBox(height: 10),
            _buildScheduleList(),
            const SizedBox(height: 22),
            _sectionTitle('Upcoming Deadlines'),
            const SizedBox(height: 10),
            _buildDeadlineList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final p = _DashboardRepository.profile;
    final sc = _stressColor(_DashboardRepository.stressLevel);
    final sl = _stressLabel(_DashboardRepository.stressLevel);

    return _GlowCard(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$greeting,', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(p.nickname,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: AppColors.textSecondary.withValues(alpha: 0.7), size: 11),
                      const SizedBox(width: 4),
                      Text('${_wd(now.weekday)}, ${_mn(now.month)} ${now.day}',
                        style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 11.5)),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () { _DashboardRepository.cycleStress(); setState(() {}); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: sc.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: sc, size: 11),
                              const SizedBox(width: 2),
                              Text(sl, style: TextStyle(color: sc, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Avatar — top right, tap → profile
            GestureDetector(
              onTap: _showProfile,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.purple, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: Text(p.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _StatTile(
          icon: Icons.event_available_outlined, label: 'Attendance',
          value: '${_DashboardRepository.attendancePercent.toStringAsFixed(0)}%',
          accent: AppColors.purple, onTap: () {},
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(
          icon: Icons.local_fire_department_outlined, label: 'Streak',
          value: '${_DashboardRepository.habitStreak} days',
          accent: const Color(0xFF06B6D4), onTap: () => setState(() => _selectedTabIndex = 2),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(
          icon: Icons.account_balance_wallet_outlined, label: 'Budget Left',
          value: '৳${_DashboardRepository.budgetRemaining.toStringAsFixed(0)}',
          accent: const Color(0xFF10B981), onTap: () => setState(() => _selectedTabIndex = 3),
        )),
      ],
    );
  }

  // ── Visualization section: bar chart + donut chart ───────────────────

  Widget _buildVisualizationSection() {
    final hours = _DashboardRepository.weeklyHours;
    final maxH = hours.reduce((a, b) => a > b ? a : b);
    final totalH = hours.fold<double>(0, (s, h) => s + h);
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dist = _DashboardRepository.subjectDistribution;
    final distColors = [const Color(0xFF4F46E5), const Color(0xFF06B6D4), const Color(0xFFF59E0B), const Color(0xFF10B981), const Color(0xFF3B82F6)];

    return Column(
      children: [
        // Weekly hours bar chart
        _GlowCard(
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: AppColors.purple, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Weekly Study Hours', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text('$totalH hrs', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.purple)),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final h = hours[i];
                      final pct = maxH > 0 ? h / maxH : 0.0;
                      final isToday = DateTime.now().weekday - 1 == i;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(h == 0 ? '' : '${h.toInt()}h',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                  color: isToday ? AppColors.purple : AppColors.textSecondary.withValues(alpha: 0.6))),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: pct * 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [isToday ? AppColors.purple : AppColors.purple.withValues(alpha: 0.4),
                                      isToday ? const Color(0xFF7C3AED) : AppColors.purpleLight.withValues(alpha: 0.3)],
                                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: isToday
                                      ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(labels[i],
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600,
                                  color: isToday ? AppColors.purple : AppColors.textSecondary.withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Subject distribution donut chart
        _GlowCard(
          radius: 20,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF06B6D4), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Subject Distribution', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Donut
                    SizedBox(
                      width: 100, height: 100,
                      child: CustomPaint(
                        painter: _DonutChartPainter(
                          values: dist.values.toList(),
                          colors: distColors,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${totalH.toInt()}h', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              Text('total', style: TextStyle(fontSize: 9, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Legend
                    Expanded(
                      child: Column(
                        children: dist.entries.toList().asMap().entries.map((e) {
                          final i = e.key;
                          final entry = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(width: 10, height: 10,
                                  decoration: BoxDecoration(
                                    color: distColors[i % distColors.length],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(entry.key,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                ),
                                Text('${(entry.value * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleList() {
    final items = _DashboardRepository.schedule;
    if (items.isEmpty) return _emptyCard(Icons.event_available_rounded, 'No schedule today.');
    if (items.every((s) => s.isCompleted)) return _emptyCard(Icons.task_alt_rounded, 'All done for today!');
    return Column(
      children: items.map((item) {
        final isClass = item.type == 'Class' || item.type == 'Lab';
        final accent = isClass ? AppColors.purple : const Color(0xFF06B6D4);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () { _DashboardRepository.toggleScheduleComplete(item.id); setState(() {}); },
            child: _GlowCard(
              radius: 14,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: item.isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.04) : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Text(item.time.format(context),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                              color: item.isCompleted ? AppColors.textSecondary.withValues(alpha: 0.5) : AppColors.textPrimary)),
                          Text(item.endTime.format(context),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary.withValues(alpha: item.isCompleted ? 0.3 : 0.6))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 3, height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          item.isCompleted ? const Color(0xFF10B981) : accent,
                          item.isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.4) : accent.withValues(alpha: 0.4),
                        ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                              color: item.isCompleted ? AppColors.textSecondary.withValues(alpha: 0.6) : AppColors.textPrimary,
                              decoration: item.isCompleted ? TextDecoration.lineThrough : null)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(item.type, style: TextStyle(fontSize: 11.5, color: accent.withValues(alpha: 0.8))),
                              if (item.location != null) ...[
                                Text(' · ', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary.withValues(alpha: 0.5))),
                                Icon(Icons.location_on_outlined, size: 11, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                const SizedBox(width: 2),
                                Text(item.location!, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                        border: Border.all(color: item.isCompleted ? const Color(0xFF10B981) : AppColors.border, width: 2),
                      ),
                      child: item.isCompleted ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeadlineList() {
    final items = _DashboardRepository.deadlines;
    if (items.isEmpty) return _emptyCard(Icons.event_note_rounded, 'No upcoming deadlines.');
    return Column(
      children: items.map((d) {
        final urgent = d.isUrgent;
        final overdue = d.isOverdue;
        final urgColor = overdue ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _GlowCard(
            radius: 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: urgent ? urgColor.withValues(alpha: 0.05) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: urgent ? urgColor.withValues(alpha: 0.12) : AppColors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      overdue ? Icons.error_outline_rounded : urgent ? Icons.warning_amber_rounded : Icons.event_note_outlined,
                      color: urgent ? urgColor : AppColors.purple, size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(d.course, style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8))),
                            if (d.courseCode != null)
                              Text(' · ${d.courseCode}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.5))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: urgent ? urgColor.withValues(alpha: 0.1) : AppColors.purple.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      overdue ? 'Overdue!' : d.daysLeft == 0 ? 'Today' : '${d.daysLeft}d',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: urgent ? urgColor : AppColors.purple),
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

  // =========================================================================
  // HABITS TAB
  // =========================================================================

  Widget _buildHabitsTab() {
    return _buildPlaceholderTab(
      title: 'Habit Tracker',
      subtitle: 'Build consistent routines to improve focus and wellness.',
      icon: Icons.local_fire_department_rounded,
      highlights: const [
        'Add daily habits and reminders',
        'Track streaks and consistency',
        'See missed habits quickly',
      ],
    );
  }

  // =========================================================================
  // BUDGET TAB
  // =========================================================================

  Widget _buildBudgetTab() {
    return _buildPlaceholderTab(
      title: 'Expense Manager',
      subtitle: 'Manage your campus expenses and monthly budget goals.',
      icon: Icons.account_balance_wallet_rounded,
      highlights: const [
        'Log spending by category',
        'Set monthly budget caps',
        'Monitor remaining balance',
      ],
    );
  }

  // =========================================================================
  // ASSISTANT TAB
  // =========================================================================

  Widget _buildAssistantTab() {
    final msgs = _DashboardRepository.chatMessages;
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

  void _sendChat(String text) {
    if (text.trim().isEmpty) return;
    _DashboardRepository.sendMessage(text.trim());
    _chatController.clear();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(_chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Widget _buildPlaceholderTab({
    required String title, required String subtitle,
    required IconData icon, required List<String> highlights,
  }) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          _GlowCard(
            radius: 24,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purple.withValues(alpha: 0.18), AppColors.purpleLight.withValues(alpha: 0.12)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.purple, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('What you can do here'),
          const SizedBox(height: 10),
          ...highlights.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _GlowCard(
              radius: 14, strokeWidth: 1.2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text(point, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 12),
          _emptyCard(Icons.construction_rounded, 'Feature coming soon. Connect this tab with your backend next.'),
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
// PROFILE BOTTOM SHEET
// =============================================================================

class _ProfileSheet extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onSignOut;
  final VoidCallback onNavigateToPlanner;
  final VoidCallback onNavigateToHabits;
  final VoidCallback onNavigateToBudget;

  const _ProfileSheet({
    required this.profile,
    required this.onSignOut,
    required this.onNavigateToPlanner,
    required this.onNavigateToHabits,
    required this.onNavigateToBudget,
  });

  @override
  Widget build(BuildContext context) {
    final initial = profile.name.split(' ').where((w) => w.isNotEmpty && w.length > 1).map((e) => e[0]).take(2).join();
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
        shrinkWrap: true,
        children: [
          Center(child: Container(width: 40, height: 5,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 16),
          // Avatar + name
          Center(
            child: Column(
              children: [
                Container(
                  width: 74, height: 74,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.purple, Color(0xFF7C3AED)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 6))],
                  ),
                  child: Center(
                    child: Text(initial,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(profile.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(profile.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Info cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                _infoRow(Icons.school_rounded, 'Department', profile.department),
                const Divider(height: 20, color: AppColors.border),
                _infoRow(Icons.auto_stories_rounded, 'Semester', '${profile.semester} · ${profile.session}'),
                const Divider(height: 20, color: AppColors.border),
                _infoRow(Icons.badge_outlined, 'Student ID', profile.id.toUpperCase()),
                const Divider(height: 20, color: AppColors.border),
                _infoRow(Icons.phone_rounded, 'Phone', profile.phone),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Enrolled courses (relates to Planner)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: AppColors.purple, size: 18),
                    const SizedBox(width: 8),
                    const Text('Enrolled Courses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text('${profile.enrolledCourses.length} subjects',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: profile.enrolledCourses.map((code) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.purple.withValues(alpha: 0.15)),
                    ),
                    child: Text(code, style: const TextStyle(color: AppColors.purple, fontSize: 12, fontWeight: FontWeight.w700)),
                  )).toList(),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onNavigateToPlanner,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('View in Planner', style: TextStyle(color: AppColors.purple, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: AppColors.purple, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Quick links to other pages
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.explore_outlined, color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 8),
                    Text('Quick Access', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                _quickLink(Icons.local_fire_department_rounded, 'Habit Tracker', 'Check today\'s progress', const Color(0xFFF59E0B), onNavigateToHabits),
                const SizedBox(height: 8),
                _quickLink(Icons.account_balance_wallet_rounded, 'Expense Manager', 'View budget & spending', const Color(0xFF10B981), onNavigateToBudget),
                const SizedBox(height: 8),
                _quickLink(Icons.dashboard_rounded, 'Twin Dashboard', 'Back to home overview', AppColors.purple, () {}),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 8),
                    Text('Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                _settingRow(Icons.palette_outlined, 'App Theme', 'Light', () {}),
                const SizedBox(height: 4),
                _settingRow(Icons.notifications_outlined, 'Notifications', 'On', () {}),
                const SizedBox(height: 4),
                _settingRow(Icons.language_outlined, 'Language', 'English', () {}),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Sign Out
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: BorderSide(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.purple, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickLink(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _settingRow(IconData icon, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500))),
            Text(value, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE COMPONENTS
// =============================================================================

class _TabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabItem({required this.label, required this.icon, required this.activeIcon});
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;
  const _StatTile({required this.icon, required this.label, required this.value, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _GlowCard(
        radius: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0.06)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 1),
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

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
        boxShadow: [BoxShadow(color: Color(0xFF2563EB).withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
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

class _AnimatedBorderBox extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final Color fillColor;
  final List<Color> colors;

  const _AnimatedBorderBox({
    required this.animation, required this.child,
    this.borderRadius = 16, this.strokeWidth = 1.6,
    this.fillColor = AppColors.card, this.colors = const [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF1E40AF)],
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

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final strokeWidth = 18.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var start = -1.5708; // start from top
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.2832;
      paint.color = colors[i % colors.length];
      paint.shader = null;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter old) =>
      old.values != values || old.colors != colors;
}
