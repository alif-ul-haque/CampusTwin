import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/planner_page.dart';
import 'package:campus_twin/habitTracker.dart';
import 'package:campus_twin/welcome_page.dart';
import 'package:campus_twin/assistant.dart';
import 'package:campus_twin/budget_page.dart' as budget;
import 'package:campus_twin/app_blocker_page.dart';
import 'package:campus_twin/leaderboard_page.dart';
import 'package:campus_twin/leaderboard_scoring.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/notifications_page.dart';
import 'package:campus_twin/profile_edit_sheet.dart';
import 'package:campus_twin/repositories/app_repositories.dart';
import 'package:campus_twin/course_setup_page.dart';

// =============================================================================
// DATA MODELS
// =============================================================================

/// "Level 4 · Term 1" == 7th semester (2 semesters per academic year).
String semesterLabel(int? level, int? term, bool isBn) {
  if (level == null || term == null) return AppStrings.notSet;
  final n = (level - 1) * 2 + term;
  if (n <= 0) return AppStrings.notSet;
  if (isBn) {
    const bnOrdinals = ['১ম', '২য়', '৩য়', '৪র্থ', '৫ম', '৬ষ্ঠ', '৭ম', '৮ম'];
    final word = n <= bnOrdinals.length ? bnOrdinals[n - 1] : '${n}তম';
    return '$word সেমিস্টার';
  }
  const suffixes = ['th', 'st', 'nd', 'rd'];
  final suffix =
      (n % 100 >= 11 && n % 100 <= 13) ? 'th' : suffixes[n % 10 > 3 ? 0 : n % 10];
  return '$n$suffix Semester';
}

enum StressLevel { low, medium, high }

class ScheduleItem {
  final String id;
  final String title;
  final TimeOfDay time;
  final TimeOfDay endTime;
  final String type;
  final String? location;
  final bool isCompleted;
  const ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.endTime,
    required this.type,
    this.location,
    this.isCompleted = false,
  });
  ScheduleItem copyWith({bool? isCompleted}) => ScheduleItem(
    id: id,
    title: title,
    time: time,
    endTime: endTime,
    type: type,
    location: location,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

class DeadlineItem {
  final String id;
  final String title;
  final String course;
  final DateTime dueDate;
  final String? courseCode;
  final String? description;
  const DeadlineItem({
    required this.id,
    required this.title,
    required this.course,
    required this.dueDate,
    this.courseCode,
    this.description,
  });
  int get daysLeft => dueDate.difference(DateTime.now()).inDays;
  bool get isUrgent => daysLeft <= 2;
  bool get isOverdue => daysLeft < 0;
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
  static UserProfile get profile => AppSettings.instance.profile;

  // ── Home tab ─────────────────────────────────────────────────────────
  static StressLevel stressLevel = StressLevel.medium;
  static double attendancePercent = 87;
  static int habitStreak = 5;
  static double budgetRemaining = 2400;
  static List<ScheduleItem> schedule = [];
  static List<DeadlineItem> deadlines = [];

  // Leaderboard (my own public score/rank from leaderboard_scores)
  static int myOverallScore = 0;
  static int myRank = 0;
  static int rankCount = 0;

  // ── Chart data ──────────────────────────────────────────────────────
  static List<double> weeklyHours = []; // Mon-Sun
  static Map<String, double> subjectDistribution = {};

  static void _initCharts() {
    if (weeklyHours.isNotEmpty) return;
    weeklyHours = [4, 6, 5, 3, 7, 2, 0];
    subjectDistribution = {
      'CSE301': 0.30,
      'CSE402': 0.20,
      'CSE501': 0.15,
      'CSE303': 0.25,
      'CSE302': 0.10,
    };
  }

  static void loadDashboard() {
    _initCharts();
    if (schedule.isEmpty) {
      schedule = [
        const ScheduleItem(
          id: 's1',
          title: 'Database Systems Lecture',
          time: TimeOfDay(hour: 9, minute: 0),
          endTime: TimeOfDay(hour: 10, minute: 30),
          type: 'Class',
          location: 'Room 401',
        ),
        const ScheduleItem(
          id: 's2',
          title: 'Data Mining Study Block',
          time: TimeOfDay(hour: 11, minute: 30),
          endTime: TimeOfDay(hour: 13, minute: 0),
          type: 'Study Block',
        ),
        const ScheduleItem(
          id: 's3',
          title: 'Software Engineering Lab',
          time: TimeOfDay(hour: 14, minute: 0),
          endTime: TimeOfDay(hour: 15, minute: 30),
          type: 'Lab',
          location: 'Lab 3',
        ),
        const ScheduleItem(
          id: 's4',
          title: 'ML Assignment Work',
          time: TimeOfDay(hour: 17, minute: 0),
          endTime: TimeOfDay(hour: 18, minute: 30),
          type: 'Study Block',
        ),
      ];
    }
    if (deadlines.isEmpty) {
      final now = DateTime.now();
      deadlines = [
        DeadlineItem(
          id: 'd1',
          title: 'ML Assignment 02',
          course: 'Machine Learning',
          dueDate: now.add(const Duration(days: 1)),
          courseCode: 'CSE501',
          description:
              'Implement a decision tree classifier from scratch and evaluate '
              'it on the provided dataset. Submit code + a 2-page report '
              'covering accuracy, precision, and recall.',
        ),
        DeadlineItem(
          id: 'd2',
          title: 'SDP Progress Report',
          course: 'Software Engineering',
          dueDate: now.add(const Duration(days: 3)),
          courseCode: 'CSE303',
          description:
              'Document sprint progress: completed user stories, blockers, '
              'and updated Gantt chart. Include screenshots of the current build.',
        ),
        DeadlineItem(
          id: 'd3',
          title: 'ISO 27001 Audit Draft',
          course: 'Internship',
          dueDate: now.add(const Duration(days: 6)),
          courseCode: 'INT401',
          description:
              'Draft the internal audit checklist for the ISMS scope review. '
              'Cross-check against last quarter\'s findings before submitting.',
        ),
        DeadlineItem(
          id: 'd4',
          title: 'Data Mining Quiz',
          course: 'Data Mining',
          dueDate: now.add(const Duration(days: 4)),
          courseCode: 'CSE402',
          description:
              'Covers clustering (k-means, DBSCAN) and association rule mining. '
              'Review lecture slides 8–11.',
        ),
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
}

// =============================================================================
// DASHBOARD PAGE
// =============================================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late int _selectedTabIndex;
  late final AnimationController _borderAnimController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex.clamp(0, 4);
    _borderAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _borderAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadProfileFromDb();

    _DashboardRepository.loadDashboard();
    await _loadMyLeaderboard();
    await _loadWeeklyHoursFromDb();
    await _loadUserCoursesForSubjectDistribution();
    await _loadBudgetLeft();
    await _loadStreak();
    if (mounted) setState(() => _isLoading = false);
  }

  /// Loads the signed-in user's real monthly budget left (income - expense
  /// for the current month) from the Firestore-backed BudgetRepository.
  Future<void> _loadBudgetLeft() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await budget.BudgetRepository.loadFromDb();
      final now = DateTime.now();
      final monthTxns = budget.BudgetRepository.inMonth(now);
      final income =
          budget.BudgetRepository.totalOf(monthTxns, budget.TxnType.income);
      final expense =
          budget.BudgetRepository.totalOf(monthTxns, budget.TxnType.expense);
      if (!mounted) return;
      setState(() {
        _DashboardRepository.budgetRemaining = income - expense;
      });
    } catch (_) {
      // Leave the previous value if the read fails.
    }
  }

  /// Loads the signed-in user's real daily check-in streak from the
  /// `daily_checkins` collection (consecutive `day_number`, reset to 1 on a
  /// missed day).
  Future<void> _loadStreak() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('daily_checkins')
          .where('user_id', isEqualTo: uid)
          .orderBy('checkin_date', descending: true)
          .limit(1)
          .get();
      final streak = snap.docs.isEmpty
          ? 0
          : (snap.docs.first.data()['day_number'] as int? ?? 0);
      if (!mounted) return;
      setState(() {
        _DashboardRepository.habitStreak = streak;
      });
    } catch (_) {
      // Leave the previous value if the read fails.
    }
  }

  /// Loads my own public leaderboard score/rank from the `leaderboard_scores`
  /// collection (safe aggregate scores only) and refreshes the dashboard.
  Future<void> _loadMyLeaderboard() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final scores = await loadLeaderboardScores();
      final me = scores.where((e) => e.id == uid).firstOrNull;
      if (!mounted) return;
      setState(() {
        _DashboardRepository.myOverallScore = me?.overallScore ?? 0;
        _DashboardRepository.myRank =
            me == null ? 0 : scores.indexOf(me) + 1;
        _DashboardRepository.rankCount = scores.length;
      });
    } catch (_) {
      // Leave previous values if the read fails.
    }
  }

  /// Builds the Subject Distribution chart from completed `study_sessions`:
  /// total completed study time per course, converted to percentages —
  /// top 5 courses, highest first. Uses user-owned courses.
  Future<void> _loadUserCoursesForSubjectDistribution() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      // Load user's courses
      final coursesSnap = await FirebaseFirestore.instance
          .collection('courses')
          .where('user_id', isEqualTo: uid)
          .get();
      final userCourses = <Map<String, String>>[];
      for (final doc in coursesSnap.docs) {
        userCourses.add({
          'id': doc.id,
          'code': (doc.data()['course_code'] as String?) ?? '',
          'name': (doc.data()['course_title'] as String?) ?? '',
        });
      }

      if (userCourses.isEmpty) {
        if (!mounted) return;
        setState(() {
          _DashboardRepository.subjectDistribution = {};
        });
        return;
      }

      // Completed study minutes per course
      final snap = await FirebaseFirestore.instance
          .collection('study_sessions')
          .where('user_id', isEqualTo: uid)
          .where('completed', isEqualTo: true)
          .get();
      final minutesByCourse = <String, int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final courseId = data['course_id'] as String?;
        if (courseId == null) continue;
        minutesByCourse[courseId] = (minutesByCourse[courseId] ?? 0) +
            ((data['duration_minutes'] as num?)?.toInt() ??
                (((data['end_minute'] as num?)?.toInt() ?? 0) -
                    ((data['start_minute'] as num?)?.toInt() ?? 0)));
      }

      final totalTime =
          minutesByCourse.values.fold<int>(0, (sum, m) => sum + m);

      // Every user course gets an entry, sorted by completed time descending, top 5.
      final entries = userCourses
          .map((c) {
            final minutes = minutesByCourse[c['id']] ?? 0;
            final code = c['code'] ?? '';
            final name = c['name'] ?? '';
            final label = code.isEmpty ? name : (name.isEmpty || name == code) ? code : '$code · $name';
            return MapEntry(
                label, totalTime > 0 ? minutes / totalTime : 0.0);
          })
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (!mounted) return;
      setState(() {
        _DashboardRepository.subjectDistribution =
            Map.fromEntries(entries.take(5));
      });
    } catch (e) {
      debugPrint('Failed to load subject distribution: $e');
    }
  }

  /// Builds [AppDashboardRepository.weeklyHours] (Mon-Sun) from completed
  /// sessions stored in the `study_sessions` collection. Only sessions with
  /// `completed == true` count towards the weekly analysis.
  Future<void> _loadWeeklyHoursFromDb() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final snapshot = await FirebaseFirestore.instance
          .collection('study_sessions')
          .where('user_id', isEqualTo: user.uid)
          .where('completed', isEqualTo: true)
          .get();

      // Mon-Sun buckets, minutes of completed study per day
      final minutes = List.filled(7, 0);
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['session_date'] as Timestamp?)?.toDate();
        if (date == null) continue;
        final day = DateTime(date.year, date.month, date.day);
        if (day.isBefore(weekStart) || !day.isBefore(weekEnd)) continue;
        final weekdayIndex = day.weekday - 1; // Monday = 0
        minutes[weekdayIndex] += (data['duration_minutes'] as num?)?.toInt() ??
            ((data['end_minute'] as num?)?.toInt() ?? 0) -
                ((data['start_minute'] as num?)?.toInt() ?? 0);
      }

      _DashboardRepository.weeklyHours = [
        for (final m in minutes) double.parse((m / 60).toStringAsFixed(2)),
      ];
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load weekly hours from DB: $e');
    }
  }

  /// Loads the signed-in user's Firestore profile into [AppSettings] so
  /// the dashboard shows database data instead of the mock profile.
  Future<void> _loadProfileFromDb() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final appUser = await UserRepository().getById(user.uid);
      if (appUser == null || !mounted) return;
      AppSettings.instance.applyAppUser(appUser);
    } catch (e) {
      debugPrint('Failed to load profile from DB: $e');
    }
  }

  void _openHabitTracker() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HabitTrackerPage()));
  }

  void _openNotifications() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }

  /// Permanently deletes the signed-in Firebase Auth account so its email
  /// becomes available for a fresh registration. Always requires the user to
  /// re-enter their password first; only deletes when the password matches.
  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.confirmDeleteAccount),
        content: Text(
          AppStrings.deleteAccountWarning,
          style: TextStyle(
            color: AppPalette.textSecondary(ctx),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Re-authenticate with the password before deleting so the user must
    // actually confirm ownership of the account.
    if (user.email == null) {
      await _deleteWithConfirmation(user);
      return;
    }
    final password = await _promptDeletePassword();
    if (password == null || password.trim().isEmpty || !mounted) return;

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) _showDeleteError(e.code);
      return;
    }

    await _deleteWithConfirmation(user);
  }

  /// Deletes the (now re-authenticated) Firebase user and returns to the
  /// welcome screen. Handles the Google-account case where password
  /// re-authentication is not possible.
  Future<void> _deleteWithConfirmation(User user) async {
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showDeleteError(e.code);
      return;
    }

    if (!mounted) return;
    FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (_) => false,
    );
  }

  Future<String?> _promptDeletePassword() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.deleteReauthTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.deleteReauthBody),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppStrings.passwordHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }

  void _showDeleteError(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.authErrorMessage(code)),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _closeDrawer() {
    final state = _scaffoldKey.currentState;
    if (state != null && state.isDrawerOpen) Navigator.of(context).pop();
  }

  void _openManageCourses() {
    _closeDrawer();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CourseSetupPage(isEditing: true)),
    ).then((_) {
      _loadUserCoursesForSubjectDistribution();
      if (mounted) setState(() {});
    });
  }

  void _openLeaderboard() {
    _closeDrawer();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LeaderboardPage()));
  }

  void _openAppBlocker() {
    _closeDrawer();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AppBlockerPage()));
  }

  void _showSettings() {
    _closeDrawer();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(
        onOpenNotifications: () {
          Navigator.of(context).pop();
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const NotificationsPage()));
        },
        onChangePassword: _changePassword,
        onDeleteAccount: _deleteAccount,
      ),
    );
  }

  Future<void> _signOut() async {
    _closeDrawer();
    final isBn = AppSettings.instance.locale.languageCode == 'bn';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isBn ? 'সাইন আউট করুন?' : 'Sign out?',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: Text(
          isBn
              ? 'আপনি কি নিশ্চিতভাবে সাইন আউট করতে চান?'
              : 'Are you sure you want to sign out of CampusTwin?',
          style: TextStyle(
            color: AppPalette.textSecondary(ctx),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (_) => false,
    );
  }

  void _showProfile() {
    _closeDrawer();
    final p = AppSettings.instance.profile;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(
        profile: p,
        onEditProfile: () {
          Navigator.of(context).pop();
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileEditPage()));
        },
      ),
    );
  }

  Future<void> _changePassword() async {
    final isBn = AppSettings.instance.locale.languageCode == 'bn';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.providerData.any((info) => info.providerId == 'google.com')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isBn
              ? 'Google দিয়ে সাইন-ইন করা অ্যাকাউন্টে পাসওয়ার্ড পরিবর্তন করা যায় না।'
              : 'Password change isn\'t available for Google sign-in accounts.',
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final result = await showDialog<_PasswordResult>(
      context: context,
      builder: (_) => const _ChangePasswordSheet(),
    );
    if (result == null || !mounted) return;

    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: result.currentPassword,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            e.code == 'wrong-password'
                ? AppStrings.outdatedPassword
                : AppStrings.authErrorMessage(e.code),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    try {
      await user.updatePassword(result.newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.passwordChanged),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.authErrorMessage(e.code)),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Tab items ────────────────────────────────────────────────────────
  List<_TabItem> get _tabs => [
    _TabItem(
      label: AppStrings.tabHome,
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    _TabItem(
      label: AppStrings.tabPlanner,
      icon: Icons.edit_calendar_outlined,
      activeIcon: Icons.edit_calendar_rounded,
    ),
    _TabItem(
      label: AppStrings.tabHabits,
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department_rounded,
    ),
    _TabItem(
      label: AppStrings.tabBudget,
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
    ),
    _TabItem(
      label: AppStrings.tabAssistant,
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy_rounded,
    ),
  ];

  // ── Helpers ──────────────────────────────────────────────────────────
  String _wd(int w) => [
    AppStrings.wdMon,
    AppStrings.wdTue,
    AppStrings.wdWed,
    AppStrings.wdThu,
    AppStrings.wdFri,
    AppStrings.wdSat,
    AppStrings.wdSun,
  ][w - 1];
  String _mn(int m) => [
    AppStrings.mnJan,
    AppStrings.mnFeb,
    AppStrings.mnMar,
    AppStrings.mnApr,
    AppStrings.mnMay,
    AppStrings.mnJun,
    AppStrings.mnJul,
    AppStrings.mnAug,
    AppStrings.mnSep,
    AppStrings.mnOct,
    AppStrings.mnNov,
    AppStrings.mnDec,
  ][m - 1];

  Color _stressColor(StressLevel l) => switch (l) {
    StressLevel.low => const Color(0xFF16A34A),
    StressLevel.medium => const Color(0xFFD97706),
    StressLevel.high => const Color(0xFFDC2626),
  };

  String _stressLabel(StressLevel l) => switch (l) {
    StressLevel.low => AppStrings.stressLow,
    StressLevel.medium => AppStrings.stressMedium,
    StressLevel.high => AppStrings.stressHigh,
  };

  Widget _sectionTitle(String title, {String? trailing}) {
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
          style: TextStyle(
            color: AppPalette.textPrimary(context),
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          Text(
            trailing,
            style: TextStyle(
              color: AppPalette.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyCard(IconData icon, String msg) {
    return _GlowCard(
      radius: 14,
      strokeWidth: 1.2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppPalette.textSecondary(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              msg,
              style: TextStyle(
                color: AppPalette.textSecondary(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: false,
      drawer: _AppDrawer(
        onProfile: _showProfile,
        onManageCourses: _openManageCourses,
        onLeaderboard: _openLeaderboard,
        onAppBlocker: _openAppBlocker,
        onNotifications: _openNotifications,
        onSettings: _showSettings,
        onSignOut: _signOut,
      ),
      drawerEdgeDragWidth: 0,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppPalette.background(context),
              AppPalette.isDark(context)
                  ? const Color(0xFF111B2E)
                  : const Color(0xFFF6F9FF),
              AppPalette.background(context),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              )
            : _buildCurrentTab(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppPalette.card(context),
          border: Border(
            top: BorderSide(color: AppPalette.border(context), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final sel = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 11,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? AppColors.purple : AppPalette.textSecondary(context),
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
              onDestinationSelected: (i) {
                if (i == 2) {
                  _openHabitTracker();
                  return;
                }
                setState(() => _selectedTabIndex = i);
              },
              destinations: _tabs
                  .map(
                    (t) => NavigationDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon, color: AppColors.purple),
                      label: t.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const PlannerPage();
      case 2:
        return _buildHabitsTab();
      case 3:
        return const budget.BudgetPage();
      case 4:
        return const AssistantTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // HOME TAB
  // =========================================================================

  Widget _buildHomeTab() {
    return SafeArea(
      bottom: false,
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
            _sectionTitle(AppStrings.todaySchedule),
            const SizedBox(height: 10),
            _buildScheduleList(),
            const SizedBox(height: 22),
            _sectionTitle(AppStrings.upcomingDeadlines),
            const SizedBox(height: 10),
            _buildUpcomingSchedule(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour >= 21 || hour < 5
        ? AppStrings.goodNight
        : hour < 12
        ? AppStrings.goodMorning
        : hour < 17
        ? AppStrings.goodAfternoon
        : AppStrings.goodEvening;
    final p = _DashboardRepository.profile;
    final sc = _stressColor(_DashboardRepository.stressLevel);
    final sl = _stressLabel(_DashboardRepository.stressLevel);

    return _GlowCard(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 14, 14),
        child: Row(
          children: [
            // Hamburger menu — opens the sidebar drawer
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: AppColors.purple,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$greeting,',
                        style: TextStyle(
                          color: AppPalette.textSecondary(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.name,
                        style: TextStyle(
                          color: AppPalette.textPrimary(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppPalette.textSecondary(context).withValues(
                          alpha: 0.7,
                        ),
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_wd(now.weekday)}, ${_mn(now.month)} ${now.day}',
                        style: TextStyle(
                          color: AppPalette.textSecondary(context).withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () {
                          _DashboardRepository.cycleStress();
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: sc.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: sc.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: sc, size: 11),
                              const SizedBox(width: 2),
                              Text(
                                sl,
                                style: TextStyle(
                                  color: sc,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Avatar — top right (static display, profile via sidebar menu)
            Container(
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppAvatar(size: 48, borderRadius: 16),
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
        Expanded(
          child: _StatTile(
            icon: Icons.leaderboard_rounded,
            label: AppStrings.pointsTag,
            value: _DashboardRepository.myRank > 0
                ? '${_DashboardRepository.myOverallScore} ${AppStrings.points}'
                : '#${_DashboardRepository.rankCount}',
            accent: const Color(0xFF6366F1),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaderboardPage()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_outlined,
            label: AppStrings.streak,
            value: '${_DashboardRepository.habitStreak} ${AppStrings.days}',
            accent: const Color(0xFF06B6D4),
            onTap: _openHabitTracker,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.account_balance_wallet_outlined,
            label: AppStrings.budgetLeft,
            value: '৳${_DashboardRepository.budgetRemaining.toStringAsFixed(0)}',
            accent: const Color(0xFF10B981),
            onTap: () => setState(() => _selectedTabIndex = 3),
          ),
        ),
      ],
    );
  }


  // ── Visualization section: bar chart + donut chart ───────────────────

  Widget _buildVisualizationSection() {
    final hours = _DashboardRepository.weeklyHours;
    final maxH = hours.reduce((a, b) => a > b ? a : b);
    final totalH = hours.fold<double>(0, (s, h) => s + h);
    final labels = [
      AppStrings.wdMon,
      AppStrings.wdTue,
      AppStrings.wdWed,
      AppStrings.wdThu,
      AppStrings.wdFri,
      AppStrings.wdSat,
      AppStrings.wdSun,
    ];
    final dist = _DashboardRepository.subjectDistribution;
    final distColors = [
      const Color(0xFF4F46E5),
      const Color(0xFF06B6D4),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
    ];

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
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.purple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Weekly Study Hours',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$totalH hrs',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
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
                              Text(
                                h == 0 ? '' : '${h.toInt()}h',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isToday
                                      ? AppColors.purple
                                      : AppPalette.textSecondary(context).withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: pct * 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isToday
                                          ? AppColors.purple
                                          : AppColors.purple.withValues(
                                              alpha: 0.4,
                                            ),
                                      isToday
                                          ? const Color(0xFF7C3AED)
                                          : AppColors.purpleLight.withValues(
                                              alpha: 0.3,
                                            ),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: isToday
                                      ? [
                                          BoxShadow(
                                            color: AppColors.purple.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                labels[i],
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? AppColors.purple
                                      : AppPalette.textSecondary(context).withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
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
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: Color(0xFF06B6D4),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Subject Distribution',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textPrimary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Donut
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CustomPaint(
                        painter: _DonutChartPainter(
                          values: dist.values.toList(),
                          colors: distColors,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${totalH.toInt()}h',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.textPrimary(context),
                                ),
                              ),
                              Text(
                                'total',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppPalette.textSecondary(context).withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Legend
                    Expanded(
                      child: Column(
                        children: dist.entries.toList().asMap().entries.map((
                          e,
                        ) {
                          final i = e.key;
                          final entry = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: distColors[i % distColors.length],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppPalette.textPrimary(context),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(entry.value * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppPalette.textSecondary(context),
                                  ),
                                ),
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
    return StreamBuilder<List<StudyBlock>>(
      stream: FirestorePlannerRepository().streamDay(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyCard(Icons.error_outline, 'Failed to load schedule.');
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final items = snapshot.data!;
        
        if (items.isEmpty) {
          return _emptyCard(Icons.task_alt_rounded, 'All done for today!');
        }

        return Column(
          children: items.map((item) {
            final isClass = item.type.apiValue == 'Class' || item.type.apiValue == 'Lab';
            final accent = isClass ? AppColors.purple : const Color(0xFF06B6D4);
            
            final startTime = TimeOfDay(hour: item.startMinute ~/ 60, minute: item.startMinute % 60);
            final endTime = TimeOfDay(hour: item.endMinute ~/ 60, minute: item.endMinute % 60);
            
            final card = Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GlowCard(
                radius: 14,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 45,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              startTime.format(context),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.textPrimary(context),
                              ),
                            ),
                            Text(
                              endTime.format(context),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppPalette.textSecondary(context).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 3,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent,
                              accent.withValues(alpha: 0.4),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: item.completed
                                    ? AppPalette.textPrimary(context).withValues(alpha: 0.6)
                                    : AppPalette.textPrimary(context),
                                decoration: item.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  item.type.label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: accent.withValues(alpha: 0.8),
                                  ),
                                ),
                                if (item.subjectName != null && item.subjectName!.isNotEmpty) ...[
                                  Text(
                                    ' · ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppPalette.textSecondary(context).withValues(alpha: 0.5),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.subjectName!,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppPalette.textSecondary(context).withValues(alpha: 0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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

            if (item.completed) {
              return ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
                child: Opacity(
                  opacity: 0.55,
                  child: card,
                ),
              );
            }
            return card;
          }).toList(),
        );
      },
    );
  }

  bool get _isBn => AppSettings.instance.locale.languageCode == 'bn';

  // ── Upcoming schedule (next 14 days, fetched from study_sessions) ──────

  DateTime get _today => _dateOnly(DateTime.now());

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Days between today and the task's date (0 = today).
  int _daysUntil(DateTime date) => _dateOnly(date).difference(_today).inDays;

  Future<List<StudyBlock>> _loadUpcomingTasks() async {
    final repo = FirestorePlannerRepository();
    final weekStart = _today.subtract(Duration(days: _today.weekday - 1));
    final weeks = await Future.wait([
      repo.fetchWeek(weekStart),
      repo.fetchWeek(weekStart.add(const Duration(days: 7))),
    ]);
    final horizon = _today.add(const Duration(days: 14));
    final all = [...weeks[0], ...weeks[1]];
    final upcoming = all
        .where((b) =>
            !b.completed &&
            !_dateOnly(b.date).isBefore(_today) &&
            _dateOnly(b.date).isBefore(horizon))
        .toList()
      ..sort((a, b) {
        final byDate = _dateOnly(a.date).compareTo(_dateOnly(b.date));
        if (byDate != 0) return byDate;
        return a.startMinute.compareTo(b.startMinute);
      });
    return upcoming;
  }

  String _gapLabel(int days) {
    if (_isBn) {
      switch (days) {
        case 0:
          return 'আজ';
        case 1:
          return 'আগামীকাল';
        default:
          return '$days দিন পরে';
      }
    }
    switch (days) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      default:
        return 'In $days days';
    }
  }

  /// Urgency tier: 0 = soon (normal), 1 = critical (2 days away),
  /// 2 = normal/faded (3+ days away).
  int _urgencyTier(int days) {
    if (days <= 1) return 0;
    if (days == 2) return 1;
    return 2;
  }

  Widget _buildUpcomingSchedule() {
    return FutureBuilder<List<StudyBlock>>(
      future: _loadUpcomingTasks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyCard(Icons.error_outline, 'Failed to load schedule.');
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return _emptyCard(Icons.event_note_rounded, AppStrings.noUpcomingTasks);
        }

        // Overview: group tasks by how many days ahead they are.
        final byGap = <int, List<StudyBlock>>{};
        for (final task in items) {
          byGap.putIfAbsent(_daysUntil(task.date), () => []).add(task);
        }
        final gaps = byGap.keys.toList()..sort();
        final futureGaps = gaps.where((g) => g >= 1).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Day-by-day overview chips (tomorrow onwards) ──
            if (futureGaps.isNotEmpty) ...[
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: futureGaps.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final gap = futureGaps[i];
                    final tier = _urgencyTier(gap);
                    final color = tier == 1
                        ? const Color(0xFFDC2626)
                        : tier == 0
                            ? const Color(0xFF06B6D4)
                            : AppPalette.textSecondary(context);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tier == 1
                            ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                            : color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: color.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tier == 1 ? Icons.priority_high_rounded : Icons.event_rounded,
                            size: 13,
                            color: color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_gapLabel(gap)} · ${byGap[gap]!.length}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
            // ── Task cards in ascending order of day & time ──
            ...items.map((item) {
              final gap = _daysUntil(item.date);
              final tier = _urgencyTier(gap);

              // Critical tint for tasks exactly 2 days away; faded for 3+
              final isCritical = tier == 1;
              final accent = isCritical
                  ? const Color(0xFFDC2626)
                  : gap <= 1
                      ? const Color(0xFF06B6D4)
                      : AppColors.purple;

              final startTime = TimeOfDay(
                hour: item.startMinute ~/ 60,
                minute: item.startMinute % 60,
              );
              final endTime = TimeOfDay(
                hour: item.endMinute ~/ 60,
                minute: item.endMinute % 60,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _GlowCard(
                  radius: 14,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isCritical
                          ? const Color(0xFFDC2626).withValues(alpha: 0.05)
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 45,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                startTime.format(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppPalette.textPrimary(context),
                                ),
                              ),
                              Text(
                                endTime.format(context),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppPalette.textSecondary(context)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 3,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent,
                                accent.withValues(alpha: 0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppPalette.textPrimary(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _gapLabel(gap),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isCritical || gap <= 1
                                            ? accent
                                            : AppPalette.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    item.type.label,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: accent.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  if (item.subjectName != null &&
                                      item.subjectName!.isNotEmpty) ...[
                                    Text(
                                      ' · ',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppPalette.textSecondary(context)
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        item.subjectName!,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color:
                                              AppPalette.textSecondary(context)
                                                  .withValues(alpha: 0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
            }),
          ],
        );
      },
    );
  }

  Future<void> _handleToggleSchedule(ScheduleItem item) async {
    if (!item.isCompleted) {
      // ── Marking done — simple yes/no confirm (prevents accidental taps) ──
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(_isBn ? 'কাজটি সম্পন্ন করবেন?' : 'Mark as done?'),
          content: Text(
            _isBn
                ? '"${item.title}" সম্পন্ন হিসেবে চিহ্নিত হবে।'
                : 'This will mark "${item.title}" as completed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_isBn ? 'বাতিল' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: Text(_isBn ? 'সম্পন্ন করুন' : 'Mark Done'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return; // guarded async gap — dialog may have disposed us
      _DashboardRepository.toggleScheduleComplete(item.id);
      setState(() {});
      return;
    }

    // ── Undoing — ask why, so accidental undo is caught ────────────────
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UndoReasonSheet(itemTitle: item.title),
    );
    if (reason == null) return; // cancelled
    if (!mounted) return; // guarded async gap — sheet may have disposed us
    _DashboardRepository.toggleScheduleComplete(item.id);
    setState(() {});
  }

  void _showDeadlineDetail(DeadlineItem d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DeadlineDetailSheet(
        deadline: d,
        onOpenPlanner: () {
          Navigator.of(context).pop();
          setState(() => _selectedTabIndex = 1);
        },
      ),
    );
  }


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

  Widget _buildPlaceholderTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> highlights,
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
                    width: 50,
                    height: 50,
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
                    child: Icon(icon, color: AppColors.purple, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppPalette.textSecondary(context),
                            fontSize: 13,
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
          _sectionTitle('What you can do here'),
          const SizedBox(height: 10),
          ...highlights.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GlowCard(
                radius: 14,
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
                      Text(
                        point,
                        style: TextStyle(
                          color: AppPalette.textPrimary(context),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _emptyCard(
            Icons.construction_rounded,
            'Feature coming soon. Connect this tab with your backend next.',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PROFILE BOTTOM SHEET
// =============================================================================

class _ProfileSheet extends StatelessWidget {
  bool get _isBn => AppSettings.instance.locale.languageCode == 'bn';
  final UserProfile profile;
  final VoidCallback onEditProfile;

  const _ProfileSheet({
    required this.profile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: AppPalette.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppPalette.border(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Avatar + name + edit
            Center(
              child: Column(
                children: [
                  AppAvatar(
                    size: 74,
                    borderRadius: 22,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    style: TextStyle(
                      color: AppPalette.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                  // Academic standing computed from Level & Term
                  // (2 semesters per academic year → L4 T1 == 7th Semester)
                  Builder(builder: (context) {
                    final lvl = settings.academicLevel;
                    final trm = settings.academicTerm;
                    if (lvl == null || trm == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Level $lvl · Term $trm  —  '
                          '${semesterLabel(lvl, trm, _isBn)}',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onEditProfile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.purple, Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            AppStrings.editProfile,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          // Info cards
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPalette.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppPalette.border(context).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                _infoRow(
                  context,
                  Icons.school_rounded,
                  AppStrings.department,
                  profile.department,
                ),
                Divider(height: 20, color: AppPalette.border(context)),
                _infoRow(
                  context,
                  Icons.auto_stories_rounded,
                  AppStrings.semester,
                  (settings.academicLevel != null &&
                          settings.academicTerm != null)
                      ? semesterLabel(
                          settings.academicLevel,
                          settings.academicTerm,
                          _isBn)
                      : profile.semester,
                ),
                Divider(height: 20, color: AppPalette.border(context)),
                _infoRow(
                  context,
                  Icons.badge_outlined,
                  AppStrings.studentId,
                  profile.studentId.isEmpty ? AppStrings.notSet : profile.studentId,
                  onTap: onEditProfile,
                ),
                Divider(height: 20, color: AppPalette.border(context)),
                _infoRow(
                  context,
                  Icons.phone_rounded,
                  AppStrings.phone,
                  profile.phone.isEmpty ? AppStrings.notSet : profile.phone,
                  onTap: onEditProfile,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final row = Row(
      children: [
        Container(
          width: 36,
          height: 36,
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
              Text(
                label,
                style: TextStyle(
                  color: AppPalette.textSecondary(context),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: value == AppStrings.notSet
                      ? AppPalette.textSecondary(context)
                      : AppPalette.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF9CA3AF),
            size: 18,
          ),
      ],
    );
    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: row,
    );
  }
}

// =============================================================================
// SETTINGS BOTTOM SHEET — theme, notifications, language, change password.
// =============================================================================

class _SettingsSheet extends StatelessWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;

  const _SettingsSheet({
    required this.onOpenNotifications,
    required this.onChangePassword,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final isBn = settings.locale.languageCode == 'bn';
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: AppPalette.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppPalette.border(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.settings,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary(context),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPalette.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppPalette.border(context).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  _settingRow(
                    context,
                    Icons.palette_outlined,
                    AppStrings.appTheme,
                    _themeLabel(settings.themeMode),
                    () => _showThemeSheet(context),
                  ),
                  Divider(
                    height: 20,
                    indent: 40,
                    color: AppPalette.border(context),
                  ),
                  _settingRow(
                    context,
                    Icons.notifications_outlined,
                    AppStrings.notifications,
                    settings.notificationsEnabled ? AppStrings.on : AppStrings.off,
                    onOpenNotifications,
                  ),
                  Divider(
                    height: 20,
                    indent: 40,
                    color: AppPalette.border(context),
                  ),
                  _settingRow(
                    context,
                    Icons.language_outlined,
                    AppStrings.language,
                    settings.locale.languageCode == 'bn'
                        ? AppStrings.bengali
                        : AppStrings.english,
                    () => _showLanguageSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Change Password
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPalette.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppPalette.border(context).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  _settingRow(
                    context,
                    Icons.password_rounded,
                    AppStrings.changePassword,
                    '',
                    onChangePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Account (destructive)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppPalette.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  _settingRow(
                    context,
                    Icons.delete_forever_rounded,
                    AppStrings.deleteAccount,
                    '',
                    onDeleteAccount,
                    destructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return AppStrings.dark;
      case ThemeMode.system:
        return AppStrings.system;
      case ThemeMode.light:
        return AppStrings.light;
    }
  }

  void _showThemeSheet(BuildContext context) {
    final settings = AppSettings.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _optionSheet(
        context,
        AppStrings.appTheme,
        [
          (
            label: AppStrings.light,
            icon: Icons.light_mode_rounded,
            selected: settings.themeMode == ThemeMode.light,
          ),
          (
            label: AppStrings.dark,
            icon: Icons.dark_mode_rounded,
            selected: settings.themeMode == ThemeMode.dark,
          ),
        ],
        (index) {
          settings.themeMode = index == 0 ? ThemeMode.light : ThemeMode.dark;
        },
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final settings = AppSettings.instance;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _optionSheet(
        context,
        AppStrings.language,
        [
          (
            label: AppStrings.english,
            icon: Icons.translate_rounded,
            selected: settings.locale.languageCode == 'en',
          ),
          (
            label: AppStrings.bengali,
            icon: Icons.translate_rounded,
            selected: settings.locale.languageCode == 'bn',
          ),
        ],
        (index) {
          settings.locale = Locale(index == 0 ? 'en' : 'bn');
        },
      ),
    );
  }

  Widget _optionSheet(
    BuildContext context,
    String title,
    List<({String label, IconData icon, bool selected})> options,
    void Function(int index) onSelect,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: AppPalette.background(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppPalette.border(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(options.length, (i) {
                final o = options[i];
                return GestureDetector(
                  onTap: () {
                    onSelect(i);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: o.selected
                          ? AppColors.purple.withValues(alpha: 0.1)
                          : AppPalette.card(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: o.selected
                            ? AppColors.purple.withValues(alpha: 0.4)
                            : AppPalette.border(context),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          o.icon,
                          color: o.selected
                              ? AppColors.purple
                              : AppPalette.textSecondary(context),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            o.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.textPrimary(context),
                            ),
                          ),
                        ),
                        if (o.selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.purple,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    final color =
        destructive ? const Color(0xFFDC2626) : AppPalette.textSecondary(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: destructive
                      ? const Color(0xFFDC2626)
                      : AppPalette.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CHANGE PASSWORD DIALOG — current / new / confirm.
// =============================================================================

class _PasswordResult {
  final String currentPassword;
  final String newPassword;
  const _PasswordResult({required this.currentPassword, required this.newPassword});
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        AppStrings.changePassword,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.enterCurrentPassword,
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.textSecondary(context),
              ),
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _currentController,
              label: AppStrings.currentPassword,
              obscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _newController,
              label: AppStrings.newPassword,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _confirmController,
              label: AppStrings.confirmPassword,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AppPalette.textSecondary(context),
          ),
          child: Text(AppStrings.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: Text(AppStrings.updatePassword),
        ),
      ],
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppPalette.textSecondary(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppPalette.textSecondary(context),
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  void _submit() {
    final current = _currentController.text;
    final newPass = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showError(AppSettings.instance.locale.languageCode == 'bn'
          ? 'সবগুলো ক্ষেত্র পূরণ করুন'
          : 'Please fill in all fields');
      return;
    }
    if (newPass.length < 6) {
      _showError(AppStrings.passwordTooShortText);
      return;
    }
    if (newPass != confirm) {
      _showError(AppStrings.passwordsDoNotMatch);
      return;
    }
    Navigator.pop(context, _PasswordResult(
      currentPassword: current,
      newPassword: newPass,
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// =============================================================================
// DASHBOARD SIDEBAR (DRAWER)
// =============================================================================

class _AppDrawer extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onManageCourses;
  final VoidCallback onLeaderboard;
  final VoidCallback onAppBlocker;
  final VoidCallback onNotifications;
  final VoidCallback onSettings;
  final VoidCallback onSignOut;

  const _AppDrawer({
    required this.onProfile,
    required this.onManageCourses,
    required this.onLeaderboard,
    required this.onAppBlocker,
    required this.onNotifications,
    required this.onSettings,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final profile = AppSettings.instance.profile;
    return Drawer(
      backgroundColor: AppPalette.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      width: 300,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  AppAvatar(size: 72, borderRadius: 20),
                  const SizedBox(height: 10),
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPalette.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: AppPalette.border(context)),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.person_rounded,
              label: AppStrings.profile,
              onTap: onProfile,
            ),
            _DrawerItem(
              icon: Icons.menu_book_rounded,
              label: AppStrings.manageCourses,
              onTap: onManageCourses,
            ),
            _DrawerItem(
              icon: Icons.leaderboard_rounded,
              label: AppStrings.leaderboard,
              onTap: onLeaderboard,
            ),
            _DrawerItem(
              icon: Icons.block_rounded,
              label: AppStrings.appBlocker,
              onTap: onAppBlocker,
            ),
            _DrawerItem(
              icon: Icons.notifications_none_rounded,
              label: AppStrings.notificationCenter,
              onTap: onNotifications,
            ),
            _DrawerItem(
              icon: Icons.settings_rounded,
              label: AppStrings.settings,
              onTap: onSettings,
            ),
            const SizedBox(height: 8),
            Divider(color: AppPalette.border(context)),
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: AppStrings.signOut,
              destructive: true,
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? const Color(0xFFDC2626) : AppPalette.textPrimary(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              color: AppPalette.textSecondary(context),
              size: 18,
            ),
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
  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

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
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.16),
                      accent.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textPrimary(context),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppPalette.textSecondary(context).withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows full context for a deadline — what it's about, how urgent it is,
/// and a shortcut to the planner to schedule study time for it.
class _DeadlineDetailSheet extends StatelessWidget {
  final DeadlineItem deadline;
  final VoidCallback onOpenPlanner;
  const _DeadlineDetailSheet({required this.deadline, required this.onOpenPlanner});

  static const _wdShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _mnShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final isBn = AppSettings.instance.locale.languageCode == 'bn';
    final overdue = deadline.isOverdue;
    final urgent = deadline.isUrgent;
    final urgColor = overdue ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final statusColor = overdue
        ? const Color(0xFFDC2626)
        : urgent
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);

    final due = deadline.dueDate;
    final dateLabel =
        '${_wdShort[due.weekday - 1]}, ${_mnShort[due.month - 1]} ${due.day}';

    final statusLabel = overdue
        ? (isBn ? 'মেয়াদ শেষ' : 'Overdue')
        : deadline.daysLeft == 0
            ? (isBn ? 'আজই শেষ দিন' : 'Due today')
            : (isBn ? '${deadline.daysLeft} দিন বাকি' : '${deadline.daysLeft} days left');

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: AppPalette.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
          shrinkWrap: true,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppPalette.border(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // ── Status pill ──────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        overdue
                            ? Icons.error_outline_rounded
                            : urgent
                                ? Icons.warning_amber_rounded
                                : Icons.event_available_rounded,
                        size: 13,
                        color: statusColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // ── Title ────────────────────────────────────────────────
            Text(
              deadline.title,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.menu_book_rounded, size: 14, color: AppPalette.textSecondary(context)),
                const SizedBox(width: 5),
                Text(
                  deadline.courseCode != null
                      ? '${deadline.course} · ${deadline.courseCode}'
                      : deadline.course,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppPalette.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 13, color: AppPalette.textSecondary(context)),
                const SizedBox(width: 5),
                Text(
                  isBn ? 'জমা দেওয়ার তারিখ: $dateLabel' : 'Due $dateLabel',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppPalette.textSecondary(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ── Description / what to do ────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppPalette.card(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPalette.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 16, color: AppColors.purple),
                      const SizedBox(width: 6),
                      Text(
                        isBn ? 'কী করতে হবে' : 'What to do',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (deadline.description?.trim().isNotEmpty ?? false)
                        ? deadline.description!
                        : (isBn
                            ? 'এই কাজের জন্য কোনো বিস্তারিত নোট যোগ করা হয়নি।'
                            : 'No additional notes have been added for this yet.'),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: AppPalette.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            if (urgent && !overdue) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: urgColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: urgColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 16, color: urgColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isBn
                            ? 'সময় খুবই কম — আজই সময় বের করে কাজ শুরু করুন।'
                            : 'Time is tight — consider blocking study time today.',
                        style: TextStyle(fontSize: 12.5, color: urgColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: onOpenPlanner,
                icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                label: Text(
                  isBn ? 'প্ল্যানারে সময় নির্ধারণ করুন' : 'Schedule time in Planner',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet asking why a completed schedule item is being undone —
/// stops accidental undos and (later) feeds undo analytics.
class _UndoReasonSheet extends StatelessWidget {
  final String itemTitle;
  const _UndoReasonSheet({required this.itemTitle});

  @override
  Widget build(BuildContext context) {
    final isBn = AppSettings.instance.locale.languageCode == 'bn';
    final reasons = [
      (
        icon: Icons.touch_app_outlined,
        label: isBn ? 'ভুল করে ক্লিক হয়ে গেছে' : 'Accidentally marked',
      ),
      (
        icon: Icons.hourglass_empty_rounded,
        label: isBn ? 'এখনো শেষ হয়নি' : 'Not finished yet',
      ),
      (
        icon: Icons.event_repeat_rounded,
        label: isBn ? 'ক্লাসের সময় পরিবর্তন হয়েছে' : 'Class time changed',
      ),
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: AppPalette.background(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppPalette.border(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isBn ? 'কেন আনডু করছেন?' : 'Why are you undoing this?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppPalette.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              itemTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: AppPalette.textSecondary(context),
              ),
            ),
            const SizedBox(height: 16),
            ...reasons.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context, r.label),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppPalette.card(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppPalette.border(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(r.icon, size: 19, color: AppPalette.textSecondary(context)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.textPrimary(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(isBn ? 'বাতিল' : 'Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowCard extends StatelessWidget {
  const _GlowCard({
    required this.child,
    this.radius = 16,
    this.strokeWidth = 1.6,
  });

  final Widget child;
  final double radius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: _StaticBorderBox(
        borderRadius: radius,
        strokeWidth: strokeWidth,
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
  });

  final Widget child;
  final double borderRadius;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BorderPainter(radius: borderRadius, strokeWidth: strokeWidth),
      child: Padding(
        padding: EdgeInsets.all(strokeWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            (borderRadius - strokeWidth).clamp(0, borderRadius),
          ),
          child: ColoredBox(color: AppPalette.card(context), child: child),
        ),
      ),
    );
  }
}

class _BorderPainter extends CustomPainter {
  _BorderPainter({required this.radius, required this.strokeWidth});

  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF1E40AF),
          Color(0xFF3B82F6),
          Color(0xFF7DB4FF),
          Color(0xFF1E40AF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _BorderPainter old) =>
      old.radius != radius || old.strokeWidth != strokeWidth;
}

class _AnimatedBorderBox extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final Color fillColor;
  final List<Color> colors;

    const _AnimatedBorderBox({
    required this.animation,
    required this.child,
    this.borderRadius = 16,
    this.strokeWidth = 1.6,
    this.fillColor = AppColors.card,
    this.colors = const [
      Color(0xFFF1E40AF),
      Color(0xFFF3B82F6),
      Color(0xFFF1E40AF),
    ],
  });


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => CustomPaint(
        painter: _RotatingBorderPainter(
          t: animation.value,
          radius: borderRadius,
          strokeWidth: strokeWidth,
          colors: colors,
        ),
        child: Padding(
          padding: EdgeInsets.all(strokeWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              (borderRadius - strokeWidth).clamp(0, borderRadius),
            ),
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

  _RotatingBorderPainter({
    required this.t,
    required this.radius,
    required this.strokeWidth,
    required this.colors,
  });

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
  bool shouldRepaint(covariant _RotatingBorderPainter old) =>
      old.t != t || old.colors != colors;
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
