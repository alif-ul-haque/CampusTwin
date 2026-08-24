// =============================================================================
// FIRESTORE DATA MODELS — generated from the ER diagram.
//
// Every model: `id` is the Firestore document id (not stored as a field).
// `fromMap(id, map)` builds from a Firestore document snapshot's data().
// `toMap()` returns the field map to write (no `id` inside).
//
// NOTE on User.password_hash: Firebase Auth already manages credentials
// (hashing, salting, rotation) — do NOT store a password hash in Firestore
// yourself. It's omitted here on purpose. Use the Firebase Auth `uid` as
// this collection's document id so `users/{uid}` stays 1:1 with the auth
// account.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _ts(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}

Timestamp _tsOrNow(DateTime? d) =>
    d == null ? Timestamp.now() : Timestamp.fromDate(d);

double _asDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

int _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

bool _asBool(dynamic v) => v == true;

// ── User ─────────────────────────────────────────────────────────────────
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.department,
    required this.semester,
    this.profilePhoto,
    this.createdAt,
    this.academicLevel,
    this.academicTerm,
    this.electiveCourses = const [],
  });

  final String id; // == FirebaseAuth uid
  final String fullName;
  final String email;
  final String department;
  final int semester;
  final String? profilePhoto;
  final DateTime? createdAt;
  final int? academicLevel; // 1–4
  final int? academicTerm;  // 1 or 2
  final List<String> electiveCourses; // chosen elective catalog ids

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        fullName: map['full_name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        department: map['department'] as String? ?? '',
        semester: _asInt(map['semester']),
        profilePhoto: map['profile_photo'] as String?,
        createdAt: _ts(map['created_at']),
        academicLevel: map['academic_level'] as int?,
        academicTerm: map['academic_term'] as int?,
        electiveCourses: (map['elective_courses'] as List?)
                ?.whereType<String>()
                .toList() ??
            const [],
      );

  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        'email': email,
        'department': department,
        'semester': semester,
        'profile_photo': profilePhoto,
        'created_at': createdAt == null ? FieldValue.serverTimestamp() : _tsOrNow(createdAt),
        if (academicLevel != null) 'academic_level': academicLevel,
        if (academicTerm != null) 'academic_term': academicTerm,
        if (electiveCourses.isNotEmpty) 'elective_courses': electiveCourses,
      };
}

// ── ExpenseCategory ─────────────────────────────────────────────────────
class ExpenseCategory {
  const ExpenseCategory({required this.id, required this.categoryName, required this.monthlyLimit});

  final String id;
  final String categoryName;
  final double monthlyLimit;

  factory ExpenseCategory.fromMap(String id, Map<String, dynamic> map) => ExpenseCategory(
        id: id,
        categoryName: map['category_name'] as String? ?? '',
        monthlyLimit: _asDouble(map['monthly_limit']),
      );

  Map<String, dynamic> toMap() => {
        'category_name': categoryName,
        'monthly_limit': monthlyLimit,
      };
}

// ── Expense ──────────────────────────────────────────────────────────────
class Expense {
  const Expense({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    this.note,
    required this.expenseDate,
  });

  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String? note;
  final DateTime expenseDate;

  factory Expense.fromMap(String id, Map<String, dynamic> map) => Expense(
        id: id,
        userId: map['user_id'] as String? ?? '',
        categoryId: map['category_id'] as String? ?? '',
        amount: _asDouble(map['amount']),
        note: map['note'] as String?,
        expenseDate: _ts(map['expense_date']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'note': note,
        'expense_date': Timestamp.fromDate(expenseDate),
      };
}

// ── Budget ───────────────────────────────────────────────────────────────
class Budget {
  const Budget({
    required this.id,
    required this.userId,
    required this.month, // e.g. "2026-08"
    required this.totalBudget,
    required this.remainingBudget,
  });

  final String id;
  final String userId;
  final String month;
  final double totalBudget;
  final double remainingBudget;

  factory Budget.fromMap(String id, Map<String, dynamic> map) => Budget(
        id: id,
        userId: map['user_id'] as String? ?? '',
        month: map['month'] as String? ?? '',
        totalBudget: _asDouble(map['total_budget']),
        remainingBudget: _asDouble(map['remaining_budget']),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'month': month,
        'total_budget': totalBudget,
        'remaining_budget': remainingBudget,
      };
}

// ── Course ───────────────────────────────────────────────────────────────
class Course {
  const Course({
    required this.id,
    required this.userId,
    required this.courseTitle,
    required this.courseCode,
    required this.credit,
    required this.instructor,
    required this.attendancePercent,
  });

  final String id;
  final String userId;
  final String courseTitle;
  final String courseCode;
  final int credit;
  final String instructor;
  final double attendancePercent;

  factory Course.fromMap(String id, Map<String, dynamic> map) => Course(
        id: id,
        userId: map['user_id'] as String? ?? '',
        courseTitle: map['course_title'] as String? ?? '',
        courseCode: map['course_code'] as String? ?? '',
        credit: _asInt(map['credit']),
        instructor: map['instructor'] as String? ?? '',
        attendancePercent: _asDouble(map['attendance_percent']),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'course_title': courseTitle,
        'course_code': courseCode,
        'credit': credit,
        'instructor': instructor,
        'attendance_percent': attendancePercent,
      };
}

// ── Assignment ───────────────────────────────────────────────────────────
enum AssignmentDifficulty { easy, medium, hard }
enum AssignmentStatus { pending, inProgress, done }

AssignmentDifficulty _difficultyFrom(String? v) => AssignmentDifficulty.values
    .firstWhere((e) => e.name == v, orElse: () => AssignmentDifficulty.medium);
AssignmentStatus _statusFrom(String? v) =>
    AssignmentStatus.values.firstWhere((e) => e.name == v, orElse: () => AssignmentStatus.pending);

class Assignment {
  const Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.dueDate,
    required this.difficulty,
    required this.status,
  });

  final String id;
  final String courseId;
  final String title;
  final DateTime dueDate;
  final AssignmentDifficulty difficulty;
  final AssignmentStatus status;

  factory Assignment.fromMap(String id, Map<String, dynamic> map) => Assignment(
        id: id,
        courseId: map['course_id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        dueDate: _ts(map['due_date']) ?? DateTime.now(),
        difficulty: _difficultyFrom(map['difficulty'] as String?),
        status: _statusFrom(map['status'] as String?),
      );

  Map<String, dynamic> toMap() => {
        'course_id': courseId,
        'title': title,
        'due_date': Timestamp.fromDate(dueDate),
        'difficulty': difficulty.name,
        'status': status.name,
      };
}

// ── StudyPlan ────────────────────────────────────────────────────────────
enum StudyPlanStatus { active, completed, archived }

StudyPlanStatus _planStatusFrom(String? v) =>
    StudyPlanStatus.values.firstWhere((e) => e.name == v, orElse: () => StudyPlanStatus.active);

class DbStudyPlan {
  const DbStudyPlan({
    required this.id,
    required this.userId,
    required this.generatedDate,
    required this.totalHours,
    required this.status,
  });

  final String id;
  final String userId;
  final DateTime generatedDate;
  final double totalHours;
  final StudyPlanStatus status;

  factory DbStudyPlan.fromMap(String id, Map<String, dynamic> map) => DbStudyPlan(
        id: id,
        userId: map['user_id'] as String? ?? '',
        generatedDate: _ts(map['generated_date']) ?? DateTime.now(),
        totalHours: _asDouble(map['total_hours']),
        status: _planStatusFrom(map['status'] as String?),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'generated_date': Timestamp.fromDate(generatedDate),
        'total_hours': totalHours,
        'status': status.name,
      };
}

// ── StudySession ─────────────────────────────────────────────────────────
enum SessionPriority { low, medium, high }

SessionPriority _priorityFrom(String? v) =>
    SessionPriority.values.firstWhere((e) => e.name == v, orElse: () => SessionPriority.medium);

class DbStudySession {
  const DbStudySession({
    required this.id,
    required this.planId,
    required this.courseId,
    required this.sessionDate,
    required this.durationMinutes,
    required this.priority,
    required this.completed,
  });

  final String id;
  final String planId;
  final String courseId;
  final DateTime sessionDate;
  final int durationMinutes;
  final SessionPriority priority;
  final bool completed;

  factory DbStudySession.fromMap(String id, Map<String, dynamic> map) => DbStudySession(
        id: id,
        planId: map['plan_id'] as String? ?? '',
        courseId: map['course_id'] as String? ?? '',
        sessionDate: _ts(map['session_date']) ?? DateTime.now(),
        durationMinutes: _asInt(map['duration_minutes']),
        priority: _priorityFrom(map['priority'] as String?),
        completed: _asBool(map['completed']),
      );

  Map<String, dynamic> toMap() => {
        'plan_id': planId,
        'course_id': courseId,
        'session_date': Timestamp.fromDate(sessionDate),
        'duration_minutes': durationMinutes,
        'priority': priority.name,
        'completed': completed,
      };
}

// ── HabitLog ─────────────────────────────────────────────────────────────
class HabitLog {
  const HabitLog({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.sleepHours,
    required this.exerciseMinutes,
    required this.waterIntakeLiter,
    required this.screenTimeHours,
  });

  final String id;
  final String userId;
  final DateTime logDate;
  final double sleepHours;
  final int exerciseMinutes;
  final double waterIntakeLiter;
  final double screenTimeHours;

  factory HabitLog.fromMap(String id, Map<String, dynamic> map) => HabitLog(
        id: id,
        userId: map['user_id'] as String? ?? '',
        logDate: _ts(map['log_date']) ?? DateTime.now(),
        sleepHours: _asDouble(map['sleep_hours']),
        exerciseMinutes: _asInt(map['exercise_minutes']),
        waterIntakeLiter: _asDouble(map['water_intake_liter']),
        screenTimeHours: _asDouble(map['screen_time_hours']),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'log_date': Timestamp.fromDate(logDate),
        'sleep_hours': sleepHours,
        'exercise_minutes': exerciseMinutes,
        'water_intake_liter': waterIntakeLiter,
        'screen_time_hours': screenTimeHours,
      };
}

// ── StressPrediction ─────────────────────────────────────────────────────
enum StressLevel { low, moderate, high }

StressLevel _stressFrom(String? v) =>
    StressLevel.values.firstWhere((e) => e.name == v, orElse: () => StressLevel.low);

class StressPrediction {
  const StressPrediction({
    required this.id,
    required this.userId,
    required this.score,
    required this.level,
    required this.explanation,
    required this.predictedAt,
  });

  final String id;
  final String userId;
  final int score;
  final StressLevel level;
  final String explanation;
  final DateTime predictedAt;

  factory StressPrediction.fromMap(String id, Map<String, dynamic> map) => StressPrediction(
        id: id,
        userId: map['user_id'] as String? ?? '',
        score: _asInt(map['score']),
        level: _stressFrom(map['level'] as String?),
        explanation: map['explanation'] as String? ?? '',
        predictedAt: _ts(map['predicted_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'score': score,
        'level': level.name,
        'explanation': explanation,
        'predicted_at': FieldValue.serverTimestamp(),
      };
}

// ── AIChat ───────────────────────────────────────────────────────────────
class AIChat {
  const AIChat({
    required this.id,
    required this.userId,
    required this.question,
    required this.response,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String question;
  final String response;
  final DateTime createdAt;

  factory AIChat.fromMap(String id, Map<String, dynamic> map) => AIChat(
        id: id,
        userId: map['user_id'] as String? ?? '',
        question: map['question'] as String? ?? '',
        response: map['response'] as String? ?? '',
        createdAt: _ts(map['created_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'question': question,
        'response': response,
        'created_at': FieldValue.serverTimestamp(),
      };
}

// ── Notification ─────────────────────────────────────────────────────────
enum NotificationType { reminder, alert, achievement, system }

NotificationType _notifTypeFrom(String? v) =>
    NotificationType.values.firstWhere((e) => e.name == v, orElse: () => NotificationType.system);

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) => AppNotification(
        id: id,
        userId: map['user_id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        message: map['message'] as String? ?? '',
        type: _notifTypeFrom(map['type'] as String?),
        isRead: _asBool(map['is_read']),
        createdAt: _ts(map['created_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'is_read': isRead,
        'created_at': FieldValue.serverTimestamp(),
      };
}

// ── DailyCheckIn ─────────────────────────────────────────────────────────
class DailyCheckIn {
  const DailyCheckIn({
    required this.id,
    required this.userId,
    required this.checkinDate,
    required this.dayNumber,
    required this.rewardPoints,
    required this.completed,
  });

  final String id;
  final String userId;
  final DateTime checkinDate;
  final int dayNumber;
  final int rewardPoints;
  final bool completed;

  factory DailyCheckIn.fromMap(String id, Map<String, dynamic> map) => DailyCheckIn(
        id: id,
        userId: map['user_id'] as String? ?? '',
        checkinDate: _ts(map['checkin_date']) ?? DateTime.now(),
        dayNumber: _asInt(map['day_number']),
        rewardPoints: _asInt(map['reward_points']),
        completed: _asBool(map['completed']),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'checkin_date': Timestamp.fromDate(checkinDate),
        'day_number': dayNumber,
        'reward_points': rewardPoints,
        'completed': completed,
      };
}

// ── Achievement (catalog — not user-owned) ──────────────────────────────
class Achievement {
  const Achievement({
    required this.id,
    required this.badgeName,
    required this.description,
    required this.rewardPoints,
  });

  final String id;
  final String badgeName;
  final String description;
  final int rewardPoints;

  factory Achievement.fromMap(String id, Map<String, dynamic> map) => Achievement(
        id: id,
        badgeName: map['badge_name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        rewardPoints: _asInt(map['reward_points']),
      );

  Map<String, dynamic> toMap() => {
        'badge_name': badgeName,
        'description': description,
        'reward_points': rewardPoints,
      };
}

// ── UserAchievement (join table) ─────────────────────────────────────────
class UserAchievement {
  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.earnedDate,
  });

  final String id;
  final String userId;
  final String achievementId;
  final DateTime earnedDate;

  factory UserAchievement.fromMap(String id, Map<String, dynamic> map) => UserAchievement(
        id: id,
        userId: map['user_id'] as String? ?? '',
        achievementId: map['achievement_id'] as String? ?? '',
        earnedDate: _ts(map['earned_date']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'achievement_id': achievementId,
        'earned_date': FieldValue.serverTimestamp(),
      };
}
