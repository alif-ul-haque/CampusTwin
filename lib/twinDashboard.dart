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

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;

  String _studentName = 'Alif';
  StressLevel _stressLevel = StressLevel.medium;
  double _attendancePercent = 87;
  int _habitStreak = 5;
  double _budgetRemaining = 2400;
  List<ScheduleItem> _todaySchedule = [];
  List<DeadlineItem> _deadlines = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : SafeArea(
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to AI Assistant chat screen
          // Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantPage()));
        },
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text(
          'Ask Twinny',
          style: TextStyle(fontWeight: FontWeight.w700),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  _studentName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateStr,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stressColor.withValues(alpha: 0.10),
                    border: Border.all(color: stressColor, width: 2.4),
                  ),
                  child: Icon(Icons.bolt_rounded, color: stressColor, size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_stressLabel(_stressLevel)} stress',
                  style: TextStyle(color: stressColor, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
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
    );
  }

  // ---------------- Section title ----------------
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
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
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: urgent ? urgentColor.withValues(alpha: 0.06) : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: urgent ? urgentColor.withValues(alpha: 0.35) : AppColors.border,
            ),
          ),
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
        );
      }).toList(),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
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