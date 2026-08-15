import 'package:campus_twin/models/app_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = Timestamp.fromDate(DateTime(2026, 8, 10, 12, 30));

  Map<String, dynamic> withTs(Map<String, dynamic> map, String key) =>
      map..[key] = ts;

  test('AppUser round-trip', () {
    final m = AppUser(
      id: 'u1', fullName: 'Alif Haque', email: 'a@b.com',
      department: 'CSE', semester: 3, profilePhoto: 'gs://x',
      createdAt: ts.toDate(),
    );
    final back = AppUser.fromMap('u1', withTs(m.toMap(), 'created_at'));
    expect(back.id, 'u1');
    expect(back.fullName, 'Alif Haque');
    expect(back.semester, 3);
    expect(back.profilePhoto, 'gs://x');
  });

  test('ExpenseCategory round-trip', () {
    final m = ExpenseCategory(id: 'food', categoryName: 'Food', monthlyLimit: 3000);
    final back = ExpenseCategory.fromMap('food', m.toMap());
    expect(back.categoryName, 'Food');
    expect(back.monthlyLimit, 3000);
  });

  test('Expense round-trip', () {
    final m = Expense(
      id: '', userId: 'u1', categoryId: 'food', amount: 250,
      note: 'Lunch', expenseDate: ts.toDate(),
    );
    final back = Expense.fromMap('e1', withTs(m.toMap(), 'expense_date'));
    expect(back.id, 'e1');
    expect(back.amount, 250);
    expect(back.note, 'Lunch');
  });

  test('Budget round-trip', () {
    final m = Budget(
      id: 'b1', userId: 'u1', month: '2026-08',
      totalBudget: 5000, remainingBudget: 3000,
    );
    final back = Budget.fromMap('b1', m.toMap());
    expect(back.month, '2026-08');
    expect(back.remainingBudget, 3000);
  });

  test('Course round-trip', () {
    final m = Course(
      id: 'c1', userId: 'u1', courseTitle: 'Database Systems',
      courseCode: 'CSE301', credit: 3, instructor: 'Dr. X', attendancePercent: 87,
    );
    final back = Course.fromMap('c1', m.toMap());
    expect(back.courseCode, 'CSE301');
    expect(back.credit, 3);
    expect(back.attendancePercent, 87);
  });

  test('Assignment round-trip', () {
    final m = Assignment(
      id: 'a1', courseId: 'c1', title: 'Lab report',
      dueDate: ts.toDate(), difficulty: AssignmentDifficulty.hard,
      status: AssignmentStatus.inProgress,
    );
    final back = Assignment.fromMap('a1', withTs(m.toMap(), 'due_date'));
    expect(back.difficulty, AssignmentDifficulty.hard);
    expect(back.status, AssignmentStatus.inProgress);
  });

  test('DbStudyPlan + DbStudySession round-trip', () {
    final p = DbStudyPlan(
      id: 'p1', userId: 'u1', generatedDate: ts.toDate(),
      totalHours: 12.5, status: StudyPlanStatus.active,
    );
    final pb = DbStudyPlan.fromMap('p1', withTs(p.toMap(), 'generated_date'));
    expect(pb.totalHours, 12.5);
    expect(pb.status, StudyPlanStatus.active);

    final s = DbStudySession(
      id: 's1', planId: 'p1', courseId: 'c1', sessionDate: ts.toDate(),
      durationMinutes: 90, priority: SessionPriority.high, completed: true,
    );
    final sb = DbStudySession.fromMap('s1', withTs(s.toMap(), 'session_date'));
    expect(sb.durationMinutes, 90);
    expect(sb.priority, SessionPriority.high);
    expect(sb.completed, true);
  });

  test('HabitLog round-trip', () {
    final m = HabitLog(
      id: 'h1', userId: 'u1', logDate: ts.toDate(),
      sleepHours: 7.2, exerciseMinutes: 30, waterIntakeLiter: 2.5,
      screenTimeHours: 4.2,
    );
    final back = HabitLog.fromMap('h1', withTs(m.toMap(), 'log_date'));
    expect(back.sleepHours, 7.2);
    expect(back.exerciseMinutes, 30);
  });

  test('StressPrediction round-trip', () {
    final m = StressPrediction(
      id: 'sp1', userId: 'u1', score: 82, level: StressLevel.moderate,
      explanation: 'Heavy exam week', predictedAt: ts.toDate(),
    );
    final back = StressPrediction.fromMap('sp1', withTs(m.toMap(), 'predicted_at'));
    expect(back.level, StressLevel.moderate);
    expect(back.explanation, 'Heavy exam week');
  });

  test('AIChat round-trip', () {
    final m = AIChat(
      id: 'ch1', userId: 'u1', question: 'Plan my day',
      response: 'Sure!', createdAt: ts.toDate(),
    );
    final back = AIChat.fromMap('ch1', withTs(m.toMap(), 'created_at'));
    expect(back.question, 'Plan my day');
    expect(back.response, 'Sure!');
  });

  test('AppNotification round-trip', () {
    final m = AppNotification(
      id: 'n1', userId: 'u1', title: 'Deadline', message: 'Tomorrow',
      type: NotificationType.reminder, isRead: false, createdAt: ts.toDate(),
    );
    final back = AppNotification.fromMap('n1', withTs(m.toMap(), 'created_at'));
    expect(back.type, NotificationType.reminder);
    expect(back.isRead, false);
  });

  test('DailyCheckIn round-trip', () {
    final m = DailyCheckIn(
      id: 'd1', userId: 'u1', checkinDate: ts.toDate(),
      dayNumber: 5, rewardPoints: 20, completed: true,
    );
    final back = DailyCheckIn.fromMap('d1', withTs(m.toMap(), 'checkin_date'));
    expect(back.dayNumber, 5);
    expect(back.rewardPoints, 20);
    expect(back.completed, true);
  });

  test('Achievement + UserAchievement round-trip', () {
    final a = Achievement(
      id: 'ac1', badgeName: '7 Day Streak', description: 'Check in 7 days',
      rewardPoints: 50,
    );
    final ab = Achievement.fromMap('ac1', a.toMap());
    expect(ab.badgeName, '7 Day Streak');
    expect(ab.rewardPoints, 50);

    final ua = UserAchievement(
      id: '', userId: 'u1', achievementId: 'ac1', earnedDate: ts.toDate(),
    );
    final uab = UserAchievement.fromMap('ua1', withTs(ua.toMap(), 'earned_date'));
    expect(uab.id, 'ua1');
    expect(uab.achievementId, 'ac1');
  });
}
