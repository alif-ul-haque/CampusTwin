import 'package:campus_twin/planner_page.dart';
import 'package:campus_twin/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StudyBlock parses and serializes the backend payload', () {
    final block = StudyBlock.fromJson({
      'id': 'task-1',
      'title': 'Review normalization',
      'date': '2026-07-20',
      'start_time': '09:15',
      'end_time': '10:45',
      'type': 'revision',
      'completed': false,
      'subject_id': 's1',
      'subject_name': 'Database Systems',
      'subject_code': 'CSE301',
    });

    expect(block.durationMinutes, 90);
    expect(block.type, PlannerTaskType.revision);
    expect(block.toJson()['start_time'], '09:15');
    expect(block.toJson()['date'], '2026-07-20');
  });

  test('StudyBlock rejects an invalid backend time range', () {
    expect(
      () => StudyBlock.fromJson({
        'id': 'task-1',
        'title': 'Invalid task',
        'date': '2026-07-20',
        'start_time': '11:00',
        'end_time': '10:00',
        'type': 'study',
      }),
      throwsFormatException,
    );
  });

  test('repository rejects creating tasks on a past date', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    await expectLater(
      MockPlannerRepository.instance.createTask(
        StudyBlockDraft(
          title: 'Too late to add',
          date: yesterday,
          startMinute: 9 * 60,
          endMinute: 10 * 60,
          type: PlannerTaskType.study,
        ),
      ),
      throwsA(isA<PlannerReadOnlyException>()),
    );
  });

  testWidgets('planner loads its primary actions and weekly overview', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: PlannerPage(repository: _TestPlannerRepository())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Study planner'), findsOneWidget);
    expect(find.text('New task'), findsOneWidget);
    expect(find.text('Weekly progress'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Today task'), findsNothing);
  });

  testWidgets('a previous week is visibly read-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: PlannerPage(repository: _TestPlannerRepository())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous week'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Read-only'), findsOneWidget);
    expect(find.text('New task'), findsNothing);
  });

  testWidgets('task editor course field fits a narrow phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: PlannerPage(repository: _TestPlannerRepository())),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();

    expect(find.text('Add study task'), findsOneWidget);
    expect(find.textContaining('CSE301'), findsWidgets);
  });
}

class _TestPlannerRepository implements PlannerRepository {
  final subject = const PlannerSubject(
    id: 'subject-1',
    name: 'Database Systems and Information Management',
    code: 'CSE301',
    colorValue: 0xFF4F46E5,
  );

  late final StudyBlock task = StudyBlock(
    id: 'today-task',
    title: 'Today task',
    date: DateTime.now(),
    startMinute: 23 * 60,
    endMinute: 23 * 60 + 30,
    type: PlannerTaskType.study,
    completed: false,
    subjectId: subject.id,
    subjectName: subject.name,
    subjectCode: subject.code,
  );

  @override
  Future<StudyBlock> createTask(StudyBlockDraft draft) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTask(String id) async {}

  @override
  Future<List<PlannerSubject>> fetchSubjects() async => [subject];

  @override
  Future<List<StudyBlock>> fetchWeek(DateTime weekStart) async {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return !task.date.isBefore(weekStart) && task.date.isBefore(weekEnd)
        ? [task]
        : [];
  }

  @override
  Future<List<StudyBlock>> generateWeek(DateTime weekStart) async => [task];

  @override
  Future<StudyBlock> setCompleted(String id, bool completed) async =>
      task.copyWith(completed: completed);
}
