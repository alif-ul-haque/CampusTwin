// =============================================================================
// CONCRETE REPOSITORIES — one per collection in the ER diagram.
// Each is a thin FirestoreRepository<T> plus any entity-specific queries.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_twin/models/app_models.dart';
import 'package:campus_twin/repositories/base_repository.dart';

// ── users ────────────────────────────────────────────────────────────────
// Doc id == FirebaseAuth uid. No password field here — Auth owns credentials.
class UserRepository extends FirestoreRepository<AppUser> {
  UserRepository() : super('users');

  @override
  AppUser fromMap(String id, Map<String, dynamic> map) => AppUser.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AppUser item) => item.toMap();

  /// Creates the profile doc the first time a user signs up.
  Future<void> createProfile(AppUser user) => set(user.id, user);
}

// ── expense_categories ──────────────────────────────────────────────────
class ExpenseCategoryRepository extends FirestoreRepository<ExpenseCategory> {
  ExpenseCategoryRepository() : super('expense_categories');

  @override
  ExpenseCategory fromMap(String id, Map<String, dynamic> map) => ExpenseCategory.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(ExpenseCategory item) => item.toMap();
}

// ── expenses ─────────────────────────────────────────────────────────────
class ExpenseRepository extends FirestoreRepository<Expense> {
  ExpenseRepository() : super('expenses');

  @override
  Expense fromMap(String id, Map<String, dynamic> map) => Expense.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Expense item) => item.toMap();

  /// Expenses for a user within a given month (e.g. month="2026-08").
  Future<List<Expense>> fetchForMonth(String userId, String month) async {
    final start = DateTime.parse('$month-01');
    final end = DateTime(start.year, start.month + 1, 1);
    final snap = await collection
        .where('user_id', isEqualTo: userId)
        .where('expense_date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('expense_date', isLessThan: Timestamp.fromDate(end))
        .orderBy('expense_date', descending: true)
        .get();
    return snap.docs.map((d) => fromMap(d.id, d.data())).toList();
  }

  /// All transaction docs (used by the leaderboard to rank budget health).
  Future<List<Expense>> fetchAll({int limit = 1000}) async {
    final snap = await collection.limit(limit).get();
    return snap.docs.map((d) => fromMap(d.id, d.data())).toList();
  }
}

// ── budgets ──────────────────────────────────────────────────────────────
class BudgetRepository extends FirestoreRepository<Budget> {
  BudgetRepository() : super('budgets');

  @override
  Budget fromMap(String id, Map<String, dynamic> map) => Budget.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Budget item) => item.toMap();

  Future<Budget?> fetchForMonth(String userId, String month) async {
    final snap = await collection
        .where('user_id', isEqualTo: userId)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return fromMap(snap.docs.first.id, snap.docs.first.data());
  }
}

// ── courses ──────────────────────────────────────────────────────────────
class CourseRepository extends FirestoreRepository<Course> {
  CourseRepository() : super('courses');

  @override
  Course fromMap(String id, Map<String, dynamic> map) => Course.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Course item) => item.toMap();
}

// ── assignments (keyed off course_id, not user_id directly) ─────────────
class AssignmentRepository extends FirestoreRepository<Assignment> {
  AssignmentRepository() : super('assignments');

  @override
  Assignment fromMap(String id, Map<String, dynamic> map) => Assignment.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Assignment item) => item.toMap();

  Future<List<Assignment>> fetchForCourse(String courseId) async {
    final snap = await collection
        .where('course_id', isEqualTo: courseId)
        .orderBy('due_date')
        .get();
    return snap.docs.map((d) => fromMap(d.id, d.data())).toList();
  }

  /// Fan-out fetch across every course id a user owns — Firestore has no
  /// server-side join, so this issues one query per course id (chunked to
  /// respect the 30-value `whereIn` limit).
  Future<List<Assignment>> fetchForCourses(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];
    final results = <Assignment>[];
    for (var i = 0; i < courseIds.length; i += 30) {
      final chunk = courseIds.sublist(i, i + 30 > courseIds.length ? courseIds.length : i + 30);
      final snap = await collection.where('course_id', whereIn: chunk).get();
      results.addAll(snap.docs.map((d) => fromMap(d.id, d.data())));
    }
    return results;
  }
}

// ── study_plans ──────────────────────────────────────────────────────────
class StudyPlanRepository extends FirestoreRepository<DbStudyPlan> {
  StudyPlanRepository() : super('study_plans');

  @override
  DbStudyPlan fromMap(String id, Map<String, dynamic> map) => DbStudyPlan.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(DbStudyPlan item) => item.toMap();
}

// ── study_sessions (keyed off plan_id) ───────────────────────────────────
class StudySessionRepository extends FirestoreRepository<DbStudySession> {
  StudySessionRepository() : super('study_sessions');

  @override
  DbStudySession fromMap(String id, Map<String, dynamic> map) => DbStudySession.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(DbStudySession item) => item.toMap();

  Future<List<DbStudySession>> fetchForPlan(String planId) async {
    final snap = await collection
        .where('plan_id', isEqualTo: planId)
        .orderBy('session_date')
        .get();
    return snap.docs.map((d) => fromMap(d.id, d.data())).toList();
  }
}

// ── habit_logs ───────────────────────────────────────────────────────────
class HabitLogRepository extends FirestoreRepository<HabitLog> {
  HabitLogRepository() : super('habit_logs');

  @override
  HabitLog fromMap(String id, Map<String, dynamic> map) => HabitLog.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(HabitLog item) => item.toMap();

  /// Last [days] logs for a user, most recent first — powers the weekly chart.
  Future<List<HabitLog>> fetchRecent(String userId, {int days = 7}) async {
    final snap = await collection
        .where('user_id', isEqualTo: userId)
        .orderBy('log_date', descending: true)
        .limit(days)
        .get();
    return snap.docs.map((d) => fromMap(d.id, d.data())).toList();
  }
}

// ── stress_predictions ───────────────────────────────────────────────────
class StressPredictionRepository extends FirestoreRepository<StressPrediction> {
  StressPredictionRepository() : super('stress_predictions');

  @override
  StressPrediction fromMap(String id, Map<String, dynamic> map) => StressPrediction.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(StressPrediction item) => item.toMap();

  Future<StressPrediction?> fetchLatest(String userId) async {
    final snap = await collection
        .where('user_id', isEqualTo: userId)
        .orderBy('predicted_at', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return fromMap(snap.docs.first.id, snap.docs.first.data());
  }
}

// ── ai_chats ─────────────────────────────────────────────────────────────
class AIChatRepository extends FirestoreRepository<AIChat> {
  AIChatRepository() : super('ai_chats');

  @override
  AIChat fromMap(String id, Map<String, dynamic> map) => AIChat.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AIChat item) => item.toMap();

  Stream<List<AIChat>> watchHistory(String userId, {int limit = 50}) => watchByUser(
        userId,
        orderBy: 'created_at',
        limit: limit,
      );
}

// ── notifications ────────────────────────────────────────────────────────
class NotificationRepository extends FirestoreRepository<AppNotification> {
  NotificationRepository() : super('notifications');

  @override
  AppNotification fromMap(String id, Map<String, dynamic> map) => AppNotification.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(AppNotification item) => item.toMap();

  Stream<List<AppNotification>> watchUnread(String userId) => collection
      .where('user_id', isEqualTo: userId)
      .where('is_read', isEqualTo: false)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => fromMap(d.id, d.data())).toList());

  Future<void> markRead(String id) => update(id, {'is_read': true});
}

// ── daily_checkins ───────────────────────────────────────────────────────
class DailyCheckInRepository extends FirestoreRepository<DailyCheckIn> {
  DailyCheckInRepository() : super('daily_checkins');

  @override
  DailyCheckIn fromMap(String id, Map<String, dynamic> map) => DailyCheckIn.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(DailyCheckIn item) => item.toMap();

  Future<bool> hasCheckedInToday(String userId) async {
    final start = DateTime.now();
    final dayStart = DateTime(start.year, start.month, start.day);
    final snap = await collection
        .where('user_id', isEqualTo: userId)
        .where('checkin_date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}

// ── achievements (read-only catalog, seeded by admins) ───────────────────
class AchievementRepository extends FirestoreRepository<Achievement> {
  AchievementRepository() : super('achievements');

  @override
  Achievement fromMap(String id, Map<String, dynamic> map) => Achievement.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(Achievement item) => item.toMap();

  Future<List<Achievement>> fetchAll() async {
    final snap = await collection.get();
    return snap.docs.map((d) => fromMap(d.id, d.data())).toList();
  }
}

// ── user_achievements (join table) ───────────────────────────────────────
class UserAchievementRepository extends FirestoreRepository<UserAchievement> {
  UserAchievementRepository() : super('user_achievements');

  @override
  UserAchievement fromMap(String id, Map<String, dynamic> map) => UserAchievement.fromMap(id, map);
  @override
  Map<String, dynamic> toMap(UserAchievement item) => item.toMap();

  /// Awards a badge once — no-op if the user already has it.
  Future<void> awardIfNew(String userId, String achievementId) async {
    final existing = await collection
        .where('user_id', isEqualTo: userId)
        .where('achievement_id', isEqualTo: achievementId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    await create(UserAchievement(
      id: '',
      userId: userId,
      achievementId: achievementId,
      earnedDate: DateTime.now(),
    ));
  }
}
