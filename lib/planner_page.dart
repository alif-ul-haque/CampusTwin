import 'package:campus_twin/theme.dart';
import 'package:flutter/material.dart';

// The UI talks only to this contract. Replace MockPlannerRepository with an
// API implementation later without changing PlannerPage or its widgets.
abstract class PlannerRepository {
  Future<List<PlannerSubject>> fetchSubjects();

  Future<List<StudyBlock>> fetchWeek(DateTime weekStart);

  Future<StudyBlock> createTask(StudyBlockDraft draft);

  Future<StudyBlock> setCompleted(String id, bool completed);

  Future<void> deleteTask(String id);

  Future<List<StudyBlock>> generateWeek(DateTime weekStart);
}

enum PlannerTaskType {
  study('study', 'Study', Icons.menu_book_rounded),
  assignment('assignment', 'Assignment', Icons.assignment_rounded),
  revision('revision', 'Revision', Icons.replay_rounded),
  classSession('class', 'Class', Icons.school_rounded),
  examPrep('exam_prep', 'Exam prep', Icons.fact_check_rounded);

  const PlannerTaskType(this.apiValue, this.label, this.icon);

  final String apiValue;
  final String label;
  final IconData icon;

  static PlannerTaskType fromApi(String? value) {
    return values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => PlannerTaskType.study,
    );
  }
}

@immutable
class PlannerSubject {
  const PlannerSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.colorValue,
    this.weeklyTargetMinutes = 0,
  });

  final String id;
  final String name;
  final String code;
  final int colorValue;
  final int weeklyTargetMinutes;

  Color get color => Color(colorValue);

  factory PlannerSubject.fromJson(Map<String, dynamic> json) {
    return PlannerSubject(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      code: _requiredString(json, 'code'),
      colorValue: _asInt(json['color_value']) ?? 0xFF4F46E5,
      weeklyTargetMinutes: _asInt(json['weekly_target_minutes']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'color_value': colorValue,
    'weekly_target_minutes': weeklyTargetMinutes,
  };
}

@immutable
class StudyBlock {
  const StudyBlock({
    required this.id,
    required this.title,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    required this.type,
    required this.completed,
    this.subjectId,
    this.subjectName,
    this.subjectCode,
    this.note,
  });

  final String id;
  final String title;
  final DateTime date;
  final int startMinute;
  final int endMinute;
  final PlannerTaskType type;
  final bool completed;
  final String? subjectId;
  final String? subjectName;
  final String? subjectCode;
  final String? note;

  int get durationMinutes => endMinute - startMinute;

  StudyBlock copyWith({bool? completed}) => StudyBlock(
    id: id,
    title: title,
    date: date,
    startMinute: startMinute,
    endMinute: endMinute,
    type: type,
    completed: completed ?? this.completed,
    subjectId: subjectId,
    subjectName: subjectName,
    subjectCode: subjectCode,
    note: note,
  );

  factory StudyBlock.fromJson(Map<String, dynamic> json) {
    final start = _parseClock(_requiredString(json, 'start_time'));
    final end = _parseClock(_requiredString(json, 'end_time'));
    if (end <= start) {
      throw const FormatException('end_time must be after start_time');
    }
    return StudyBlock(
      id: _requiredString(json, 'id'),
      title: _requiredString(json, 'title'),
      date: _dateOnly(DateTime.parse(_requiredString(json, 'date'))),
      startMinute: start,
      endMinute: end,
      type: PlannerTaskType.fromApi(json['type'] as String?),
      completed: json['completed'] == true,
      subjectId: _optionalString(json['subject_id']),
      subjectName: _optionalString(json['subject_name']),
      subjectCode: _optionalString(json['subject_code']),
      note: _optionalString(json['note']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': _apiDate(date),
    'start_time': _apiTime(startMinute),
    'end_time': _apiTime(endMinute),
    'type': type.apiValue,
    'completed': completed,
    'subject_id': subjectId,
    'subject_name': subjectName,
    'subject_code': subjectCode,
    'note': note,
  };
}

@immutable
class StudyBlockDraft {
  const StudyBlockDraft({
    required this.title,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    required this.type,
    this.subjectId,
    this.note,
  });

  final String title;
  final DateTime date;
  final int startMinute;
  final int endMinute;
  final PlannerTaskType type;
  final String? subjectId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': _apiDate(date),
    'start_time': _apiTime(startMinute),
    'end_time': _apiTime(endMinute),
    'type': type.apiValue,
    'subject_id': subjectId,
    'note': note,
  };
}

class PlannerConflictException implements Exception {
  const PlannerConflictException(this.message);
  final String message;
}

class PlannerReadOnlyException implements Exception {
  const PlannerReadOnlyException([
    this.message = 'Tasks from a past date are read-only.',
  ]);

  final String message;
}

class MockPlannerRepository implements PlannerRepository {
  MockPlannerRepository._();

  static final MockPlannerRepository instance = MockPlannerRepository._();

  final List<PlannerSubject> _subjects = const [
    PlannerSubject(
      id: 's1',
      name: 'Database Systems',
      code: 'CSE301',
      colorValue: 0xFF4F46E5,
      weeklyTargetMinutes: 360,
    ),
    PlannerSubject(
      id: 's2',
      name: 'Data Mining',
      code: 'CSE402',
      colorValue: 0xFF0891B2,
      weeklyTargetMinutes: 300,
    ),
    PlannerSubject(
      id: 's3',
      name: 'Machine Learning',
      code: 'CSE501',
      colorValue: 0xFFD97706,
      weeklyTargetMinutes: 360,
    ),
    PlannerSubject(
      id: 's4',
      name: 'Software Engineering',
      code: 'CSE303',
      colorValue: 0xFF059669,
      weeklyTargetMinutes: 240,
    ),
    PlannerSubject(
      id: 's5',
      name: 'Computer Networks',
      code: 'CSE302',
      colorValue: 0xFF2563EB,
      weeklyTargetMinutes: 240,
    ),
  ];

  final List<StudyBlock> _tasks = [];
  bool _seeded = false;
  int _nextId = 100;

  void _seed() {
    if (_seeded) return;
    _seeded = true;
    final monday = _startOfWeek(DateTime.now());
    _tasks.addAll([
      _task(
        '1',
        'Review database normalization',
        monday,
        9 * 60,
        10 * 60,
        PlannerTaskType.revision,
        's1',
        note: 'Focus on 3NF and BCNF examples.',
      ),
      _task(
        '2',
        'Data mining practice',
        monday,
        11 * 60 + 30,
        13 * 60,
        PlannerTaskType.study,
        's2',
        note: 'Complete two clustering problems.',
      ),
      _task(
        '3',
        'ML assignment sprint',
        monday.add(const Duration(days: 1)),
        15 * 60,
        16 * 60 + 30,
        PlannerTaskType.assignment,
        's3',
      ),
      _task(
        '4',
        'Networks quiz preparation',
        monday.add(const Duration(days: 2)),
        19 * 60,
        20 * 60,
        PlannerTaskType.examPrep,
        's5',
      ),
      _task(
        '5',
        'Software project meeting',
        monday.add(const Duration(days: 3)),
        14 * 60,
        15 * 60,
        PlannerTaskType.classSession,
        's4',
      ),
      _task(
        '6',
        'Weekly course review',
        monday.add(const Duration(days: 4)),
        16 * 60,
        17 * 60,
        PlannerTaskType.revision,
        null,
      ),
    ]);
  }

  StudyBlock _task(
    String id,
    String title,
    DateTime date,
    int start,
    int end,
    PlannerTaskType type,
    String? subjectId, {
    String? note,
  }) {
    final subject = _subject(subjectId);
    return StudyBlock(
      id: id,
      title: title,
      date: _dateOnly(date),
      startMinute: start,
      endMinute: end,
      type: type,
      completed: false,
      subjectId: subject?.id,
      subjectName: subject?.name,
      subjectCode: subject?.code,
      note: note,
    );
  }

  PlannerSubject? _subject(String? id) {
    if (id == null) return null;
    for (final subject in _subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 220));

  @override
  Future<List<PlannerSubject>> fetchSubjects() async {
    _seed();
    await _latency();
    return List.unmodifiable(_subjects);
  }

  @override
  Future<List<StudyBlock>> fetchWeek(DateTime weekStart) async {
    _seed();
    await _latency();
    final end = weekStart.add(const Duration(days: 7));
    final result =
        _tasks
            .where(
              (task) =>
                  !task.date.isBefore(weekStart) && task.date.isBefore(end),
            )
            .toList()
          ..sort(_sortTasks);
    return List.unmodifiable(result);
  }

  @override
  Future<StudyBlock> createTask(StudyBlockDraft draft) async {
    _seed();
    await _latency();
    _validateDraft(draft);
    final subject = _subject(draft.subjectId);
    final task = StudyBlock(
      id: 'local_${_nextId++}',
      title: draft.title.trim(),
      date: _dateOnly(draft.date),
      startMinute: draft.startMinute,
      endMinute: draft.endMinute,
      type: draft.type,
      completed: false,
      subjectId: subject?.id,
      subjectName: subject?.name,
      subjectCode: subject?.code,
      note: _optionalString(draft.note),
    );
    _tasks.add(task);
    return task;
  }

  void _validateDraft(StudyBlockDraft draft) {
    if (draft.title.trim().isEmpty || draft.title.trim().length > 80) {
      throw const FormatException(
        'Task title must contain 1 to 80 characters.',
      );
    }
    if (draft.startMinute < 0 ||
        draft.endMinute > 24 * 60 ||
        draft.endMinute - draft.startMinute < 5) {
      throw const FormatException(
        'Choose a valid time range of at least 5 minutes.',
      );
    }
    if (_dateOnly(draft.date).isBefore(_dateOnly(DateTime.now()))) {
      throw const PlannerReadOnlyException(
        'You cannot add a task to a date that has already passed.',
      );
    }
    final overlaps = _tasks.any(
      (task) =>
          _sameDate(task.date, draft.date) &&
          draft.startMinute < task.endMinute &&
          draft.endMinute > task.startMinute,
    );
    if (overlaps) {
      throw const PlannerConflictException(
        'This time overlaps another task. Choose a free time.',
      );
    }
  }

  @override
  Future<StudyBlock> setCompleted(String id, bool completed) async {
    await _latency();
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) throw StateError('Task no longer exists.');
    if (_tasks[index].date.isBefore(_dateOnly(DateTime.now()))) {
      throw const PlannerReadOnlyException();
    }
    _tasks[index] = _tasks[index].copyWith(completed: completed);
    return _tasks[index];
  }

  @override
  Future<void> deleteTask(String id) async {
    await _latency();
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index < 0) throw StateError('Task no longer exists.');
    if (_tasks[index].date.isBefore(_dateOnly(DateTime.now()))) {
      throw const PlannerReadOnlyException();
    }
    _tasks.removeAt(index);
  }

  @override
  Future<List<StudyBlock>> generateWeek(DateTime weekStart) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final suggestions = [
      StudyBlockDraft(
        title: 'Focused course review',
        date: weekStart.add(const Duration(days: 1)),
        startMinute: 9 * 60,
        endMinute: 10 * 60,
        type: PlannerTaskType.study,
        subjectId: _subjects.first.id,
      ),
      StudyBlockDraft(
        title: 'Practice and recall',
        date: weekStart.add(const Duration(days: 5)),
        startMinute: 10 * 60,
        endMinute: 11 * 60,
        type: PlannerTaskType.revision,
        subjectId: _subjects[2].id,
      ),
    ];
    for (final draft in suggestions) {
      try {
        _validateDraft(draft);
        final subject = _subject(draft.subjectId);
        _tasks.add(
          StudyBlock(
            id: 'generated_${_nextId++}',
            title: draft.title,
            date: draft.date,
            startMinute: draft.startMinute,
            endMinute: draft.endMinute,
            type: draft.type,
            completed: false,
            subjectId: subject?.id,
            subjectName: subject?.name,
            subjectCode: subject?.code,
            note: 'Suggested from your course load and available time.',
          ),
        );
      } on PlannerConflictException {
        // A generated suggestion never overwrites or overlaps a user's task.
      } on PlannerReadOnlyException {
        // Suggestions are never inserted into dates that have already passed.
      }
    }
    return fetchWeek(weekStart);
  }
}

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, this.repository});

  final PlannerRepository? repository;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  late final PlannerRepository _repository;
  late DateTime _weekStart;
  late DateTime _selectedDate;
  List<PlannerSubject> _subjects = const [];
  List<StudyBlock> _tasks = const [];
  bool _loading = true;
  bool _generating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MockPlannerRepository.instance;
    _weekStart = _startOfWeek(DateTime.now());
    _selectedDate = _dateOnly(DateTime.now());
    _load();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        _repository.fetchSubjects(),
        _repository.fetchWeek(_weekStart),
      ]);
      if (!mounted) return;
      setState(() {
        _subjects = results[0] as List<PlannerSubject>;
        _tasks = results[1] as List<StudyBlock>;
        _error = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'We could not load your planner. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: offset * 7));
      final today = _dateOnly(DateTime.now());
      _selectedDate = _isInWeek(today, _weekStart) ? today : _weekStart;
      _loading = true;
    });
    _load(showLoader: false);
  }

  void _goToToday() {
    final today = _dateOnly(DateTime.now());
    setState(() {
      _weekStart = _startOfWeek(today);
      _selectedDate = today;
      _loading = true;
    });
    _load(showLoader: false);
  }

  List<StudyBlock> get _selectedTasks =>
      _tasks.where((task) => _sameDate(task.date, _selectedDate)).toList()
        ..sort(_sortTasks);

  bool get _selectedDateIsPast =>
      _selectedDate.isBefore(_dateOnly(DateTime.now()));

  bool get _weekIsPast => _weekStart
      .add(const Duration(days: 6))
      .isBefore(_dateOnly(DateTime.now()));

  PlannerSubject? _subjectFor(StudyBlock task) {
    for (final subject in _subjects) {
      if (subject.id == task.subjectId) return subject;
    }
    return null;
  }

  Future<void> _toggleTask(StudyBlock task) async {
    if (task.date.isBefore(_dateOnly(DateTime.now()))) {
      _showMessage('Past tasks are read-only.');
      return;
    }
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    final previous = _tasks[index];
    setState(() {
      final copy = [..._tasks];
      copy[index] = task.copyWith(completed: !task.completed);
      _tasks = copy;
    });
    try {
      await _repository.setCompleted(task.id, !task.completed);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final copy = [..._tasks];
        final current = copy.indexWhere((item) => item.id == task.id);
        if (current >= 0) copy[current] = previous;
        _tasks = copy;
      });
      _showMessage('Could not update this task. Please try again.');
    }
  }

  Future<void> _openAddTask() async {
    if (_selectedDateIsPast) {
      _showMessage('Choose today or a future date to add a task.');
      return;
    }
    final created = await showModalBottomSheet<StudyBlock>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskEditorSheet(
        repository: _repository,
        subjects: _subjects,
        initialDate: _selectedDate,
      ),
    );
    if (created == null || !mounted) return;
    if (!_isInWeek(created.date, _weekStart)) {
      setState(() {
        _weekStart = _startOfWeek(created.date);
        _selectedDate = created.date;
      });
      await _load();
    } else {
      setState(() {
        _tasks = [..._tasks, created]..sort(_sortTasks);
        _selectedDate = created.date;
      });
    }
    _showMessage('Task added to your planner.');
  }

  Future<void> _openDetails(StudyBlock task) async {
    final action = await showModalBottomSheet<_TaskAction>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TaskDetailSheet(
        task: task,
        color: _subjectFor(task)?.color ?? AppColors.purple,
        readOnly: task.date.isBefore(_dateOnly(DateTime.now())),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _TaskAction.toggle) {
      await _toggleTask(task);
      return;
    }
    await _deleteTask(task);
  }

  Future<void> _deleteTask(StudyBlock task) async {
    if (task.date.isBefore(_dateOnly(DateTime.now()))) {
      _showMessage('Past tasks are read-only and cannot be deleted.');
      return;
    }
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text('“${task.title}” will be permanently removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _repository.deleteTask(task.id);
      if (!mounted) return;
      setState(
        () => _tasks = _tasks.where((item) => item.id != task.id).toList(),
      );
      _showMessage('Task deleted.');
    } catch (_) {
      if (mounted) {
        _showMessage('Could not delete this task. Please try again.');
      }
    }
  }

  Future<void> _generatePlan() async {
    if (_generating) return;
    if (_weekIsPast) {
      _showMessage('Past weeks are read-only.');
      return;
    }
    if (_tasks.isNotEmpty) {
      final proceed =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add smart suggestions?'),
              content: const Text(
                'CampusTwin will fill available time only. Your existing tasks will stay unchanged.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Add suggestions'),
                ),
              ],
            ),
          ) ??
          false;
      if (!proceed) return;
    }
    setState(() => _generating = true);
    try {
      final tasks = await _repository.generateWeek(_weekStart);
      if (!mounted) return;
      setState(() => _tasks = tasks);
      _showMessage('Your week has been updated with available study blocks.');
    } catch (_) {
      if (mounted) _showMessage('Could not generate suggestions right now.');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: () => _load(showLoader: false),
        child: _loading
            ? const _PlannerLoadingView()
            : _error != null
            ? _PlannerErrorView(message: _error!, onRetry: _load)
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                children: [
                  _buildTitle(),
                  const SizedBox(height: 20),
                  _buildWeekPicker(),
                  const SizedBox(height: 14),
                  _buildDayPicker(),
                  const SizedBox(height: 20),
                  _buildOverview(),
                  const SizedBox(height: 24),
                  _buildScheduleHeader(),
                  const SizedBox(height: 10),
                  _buildSchedule(),
                  const SizedBox(height: 24),
                  _buildSubjectProgress(),
                  const SizedBox(height: 20),
                  _buildSmartPlanCard(),
                ],
              ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study planner',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Plan clearly. Study consistently.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildWeekPicker() {
    final end = _weekStart.add(const Duration(days: 6));
    final isCurrent = _sameDate(_weekStart, _startOfWeek(DateTime.now()));
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous week',
            onPressed: () => _changeWeek(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _weekRange(_weekStart, end),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrent
                      ? 'Current week'
                      : 'Week ${_isoWeekNumber(_weekStart)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(onPressed: _goToToday, child: const Text('Today'))
          else
            IconButton(
              tooltip: 'Next week',
              onPressed: () => _changeWeek(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          if (!isCurrent)
            IconButton(
              tooltip: 'Next week',
              onPressed: () => _changeWeek(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    );
  }

  Widget _buildDayPicker() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _weekStart.add(Duration(days: index));
          final selected = _sameDate(date, _selectedDate);
          final today = _sameDate(date, DateTime.now());
          final isPast = date.isBefore(_dateOnly(DateTime.now()));
          final hasTasks = _tasks.any((task) => _sameDate(task.date, date));
          return Semantics(
            button: true,
            selected: selected,
            label: '${_weekdayLong(date.weekday)} ${date.day}',
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _selectedDate = date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 54,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? (isPast ? const Color(0xFFE2E8F0) : AppColors.purple)
                      : (isPast ? const Color(0xFFF1F5F9) : AppColors.card),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isPast
                        ? const Color(0xFFCBD5E1)
                        : (selected ? AppColors.purple : AppColors.border),
                  ),
                  boxShadow: selected && !isPast
                      ? [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      _weekdayShort(date.weekday),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected && !isPast
                            ? Colors.white70
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: selected && !isPast
                            ? Colors.white
                            : (isPast
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isPast)
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 9,
                        color: AppColors.textSecondary,
                      )
                    else
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasTasks
                              ? (selected ? Colors.white : AppColors.purple)
                              : (today
                                    ? const Color(0xFFF59E0B)
                                    : Colors.transparent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverview() {
    final totalMinutes = _tasks.fold<int>(
      0,
      (sum, task) => sum + task.durationMinutes,
    );
    final completedMinutes = _tasks
        .where((task) => task.completed)
        .fold<int>(0, (sum, task) => sum + task.durationMinutes);
    final completedTasks = _tasks.where((task) => task.completed).length;
    final progress = totalMinutes == 0 ? 0.0 : completedMinutes / totalMinutes;
    return _SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 7,
                      backgroundColor: AppColors.inputFill,
                      color: const Color(0xFF10B981),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly progress',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalMinutes == 0
                          ? 'Add a task to start your week.'
                          : '$completedTasks of ${_tasks.length} tasks completed',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.schedule_rounded,
                  label: 'Planned',
                  value: _durationLabel(totalMinutes),
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: Icons.task_alt_rounded,
                  label: 'Completed',
                  value: _durationLabel(completedMinutes),
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: Icons.pending_actions_rounded,
                  label: 'Remaining',
                  value: '${_tasks.length - completedTasks}',
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleHeader() {
    final today = _sameDate(_selectedDate, DateTime.now());
    return Row(
      children: [
        Expanded(
          child: _SectionTitle(
            title: today
                ? 'Today’s plan'
                : '${_weekdayLong(_selectedDate.weekday)}’s plan',
          ),
        ),
        if (_selectedDateIsPast)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14),
              SizedBox(width: 4),
              Text(
                'Read-only',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          )
        else
          FilledButton.icon(
            onPressed: _openAddTask,
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('New task'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSchedule() {
    final tasks = _selectedTasks;
    if (tasks.isEmpty) {
      return _SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedDateIsPast
                  ? 'No tasks were planned'
                  : 'No tasks planned',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _selectedDateIsPast
                  ? 'This date has passed and is now read-only.'
                  : 'Keep this time free or add a focused study block.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (!_selectedDateIsPast) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _openAddTask,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add a task'),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TaskCard(
              task: task,
              color: _subjectFor(task)?.color ?? AppColors.purple,
              onToggle: () => _toggleTask(task),
              onTap: () => _openDetails(task),
              onDelete: () => _deleteTask(task),
              readOnly: _selectedDateIsPast,
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectProgress() {
    if (_subjects.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Course focus'),
        const SizedBox(height: 10),
        SizedBox(
          height: 114,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _subjects.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final subject = _subjects[index];
              final planned = _tasks
                  .where((task) => task.subjectId == subject.id)
                  .fold<int>(0, (sum, task) => sum + task.durationMinutes);
              final target = subject.weeklyTargetMinutes;
              final progress = target == 0
                  ? 0.0
                  : (planned / target).clamp(0.0, 1.0);
              return Container(
                width: 164,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: subject.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            subject.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.inputFill,
                        color: subject.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_durationLabel(planned)} planned',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmartPlanCard() {
    final readOnly = _weekIsPast;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  readOnly ? 'Past week archived' : 'Build a balanced week',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  readOnly
                      ? 'Tasks in this week can be viewed but not changed.'
                      : 'Fill free time without changing existing tasks.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: _generating || readOnly ? null : _generatePlan,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.purple,
              disabledBackgroundColor: Colors.white70,
              minimumSize: const Size(72, 42),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.purple,
                    ),
                  )
                : Icon(
                    readOnly
                        ? Icons.lock_outline_rounded
                        : Icons.arrow_forward_rounded,
                    size: 19,
                  ),
          ),
        ],
      ),
    );
  }
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({
    required this.repository,
    required this.subjects,
    required this.initialDate,
  });

  final PlannerRepository repository;
  final List<PlannerSubject> subjects;
  final DateTime initialDate;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  late DateTime _date;
  int _startMinute = 9 * 60;
  int _endMinute = 10 * 60;
  String? _subjectId;
  PlannerTaskType _type = PlannerTaskType.study;
  bool _saving = false;
  String? _timeError;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _subjectId = widget.subjects.isEmpty ? null : widget.subjects.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null && mounted) setState(() => _date = _dateOnly(picked));
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _startMinute : _endMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: _toTimeOfDay(current),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final value = picked.hour * 60 + picked.minute;
      if (start) {
        _startMinute = value;
        if (_endMinute <= value) {
          _endMinute = (value + 60).clamp(0, 24 * 60 - 1).toInt();
        }
      } else {
        _endMinute = value;
      }
      _timeError = _endMinute - _startMinute < 5
          ? 'End time must be at least 5 minutes after start.'
          : null;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(
      () => _timeError = _endMinute - _startMinute < 5
          ? 'End time must be at least 5 minutes after start.'
          : null,
    );
    if (!_formKey.currentState!.validate() || _timeError != null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final task = await widget.repository.createTask(
        StudyBlockDraft(
          title: _titleController.text.trim(),
          date: _date,
          startMinute: _startMinute,
          endMinute: _endMinute,
          type: _type,
          subjectId: _subjectId,
          note: _optionalString(_noteController.text),
        ),
      );
      if (mounted) Navigator.pop(context, task);
    } on PlannerConflictException catch (error) {
      if (mounted) setState(() => _timeError = error.message);
    } on PlannerReadOnlyException catch (error) {
      if (mounted) setState(() => _timeError = error.message);
    } on FormatException catch (error) {
      if (mounted) setState(() => _timeError = error.message);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save the task. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(22, 14, 22, 24 + bottom),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Add study task',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              autofocus: true,
              maxLength: 80,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'What do you want to accomplish?',
                prefixIcon: Icon(Icons.task_alt_rounded),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) return 'Enter a task title.';
                if (text.length < 3) return 'Use at least 3 characters.';
                return null;
              },
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(
                  '${_weekdayLong(_date.weekday)}, ${_monthLong(_date.month)} ${_date.day}, ${_date.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Starts',
                    minute: _startMinute,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeField(
                    label: 'Ends',
                    minute: _endMinute,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            if (_timeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 7, left: 12),
                child: Text(
                  _timeError!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            DropdownButtonFormField<PlannerTaskType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Task type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: PlannerTaskType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              initialValue: _subjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Course',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('General / no course'),
                ),
                ...widget.subjects.map(
                  (subject) => DropdownMenuItem<String?>(
                    value: subject.id,
                    child: Text(
                      '${subject.code} — ${subject.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              selectedItemBuilder: (context) => [
                const Text(
                  'General / no course',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                ...widget.subjects.map(
                  (subject) => Text(
                    '${subject.code} — ${subject.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _subjectId = value),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Resources, goals, or reminders',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 44),
                  child: Icon(Icons.notes_rounded),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_task_rounded),
              label: Text(_saving ? 'Adding task…' : 'Add to planner'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TaskAction { toggle, delete }

class _TaskDetailSheet extends StatelessWidget {
  const _TaskDetailSheet({
    required this.task,
    required this.color,
    required this.readOnly,
  });
  final StudyBlock task;
  final Color color;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(text: task.type.label, color: color),
              if (task.subjectCode != null)
                _Pill(text: task.subjectCode!, color: const Color(0xFF475569)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: task.completed
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              decoration: task.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 12),
          _DetailLine(
            icon: Icons.calendar_today_rounded,
            text:
                '${_weekdayLong(task.date.weekday)}, ${_monthLong(task.date.month)} ${task.date.day}',
          ),
          const SizedBox(height: 9),
          _DetailLine(
            icon: Icons.schedule_rounded,
            text:
                '${_formatMinute(context, task.startMinute)} – ${_formatMinute(context, task.endMinute)} · ${_durationLabel(task.durationMinutes)}',
          ),
          if (task.subjectName != null) ...[
            const SizedBox(height: 9),
            _DetailLine(icon: Icons.school_outlined, text: task.subjectName!),
          ],
          if (task.note != null) ...[
            const SizedBox(height: 16),
            Text(
              task.note!,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (readOnly) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 18),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'This date has passed. The task is kept as history and cannot be changed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!readOnly)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, _TaskAction.delete),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, _TaskAction.toggle),
                    icon: Icon(
                      task.completed ? Icons.undo_rounded : Icons.check_rounded,
                    ),
                    label: Text(task.completed ? 'Mark pending' : 'Mark done'),
                    style: FilledButton.styleFrom(
                      backgroundColor: task.completed
                          ? AppColors.textSecondary
                          : const Color(0xFF059669),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.color,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.readOnly,
  });
  final StudyBlock task;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 13, 14, 13),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 58,
                decoration: BoxDecoration(
                  color: task.completed ? AppColors.border : color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 11),
              Semantics(
                button: true,
                label: task.completed
                    ? 'Mark ${task.title} pending'
                    : 'Mark ${task.title} complete',
                child: Checkbox(
                  value: task.completed,
                  onChanged: readOnly ? null : (_) => onToggle(),
                  activeColor: const Color(0xFF059669),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: task.completed
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_formatMinute(context, task.startMinute)} – ${_formatMinute(context, task.endMinute)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (task.subjectCode != null) const SizedBox(width: 6),
                        if (task.subjectCode != null)
                          _Pill(text: task.subjectCode!, color: color),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: readOnly ? 'Past tasks are read-only' : 'Delete task',
                onPressed: readOnly ? null : onDelete,
                icon: Icon(
                  readOnly
                      ? Icons.lock_outline_rounded
                      : Icons.delete_outline_rounded,
                  color: readOnly
                      ? AppColors.textSecondary
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minute,
    required this.onTap,
  });
  final String label;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule_rounded),
        ),
        child: Text(
          _formatMinute(context, minute),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 17,
        decoration: BoxDecoration(
          color: AppColors.purple,
          borderRadius: BorderRadius.circular(9),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, required this.padding});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class _PlannerLoadingView extends StatelessWidget {
  const _PlannerLoadingView();

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
    children: [
      Row(
        children: [
          Expanded(child: _placeholder(170, 28)),
          const SizedBox(width: 50),
          _placeholder(104, 46),
        ],
      ),
      const SizedBox(height: 22),
      _placeholder(double.infinity, 66),
      const SizedBox(height: 14),
      _placeholder(double.infinity, 76),
      const SizedBox(height: 20),
      _placeholder(double.infinity, 190),
      const SizedBox(height: 24),
      _placeholder(130, 22),
      const SizedBox(height: 12),
      _placeholder(double.infinity, 90),
      const SizedBox(height: 10),
      _placeholder(double.infinity, 90),
    ],
  );

  static Widget _placeholder(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.border.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

class _PlannerErrorView extends StatelessWidget {
  const _PlannerErrorView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function({bool showLoader}) onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(32),
    children: [
      const SizedBox(height: 120),
      const Icon(
        Icons.cloud_off_rounded,
        size: 54,
        color: AppColors.textSecondary,
      ),
      const SizedBox(height: 16),
      const Text(
        'Planner unavailable',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
      ),
      const SizedBox(height: 20),
      Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ),
    ],
  );
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _startOfWeek(DateTime date) =>
    _dateOnly(date).subtract(Duration(days: date.weekday - 1));

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isInWeek(DateTime date, DateTime start) =>
    !date.isBefore(start) && date.isBefore(start.add(const Duration(days: 7)));

int _sortTasks(StudyBlock a, StudyBlock b) {
  final date = a.date.compareTo(b.date);
  return date != 0 ? date : a.startMinute.compareTo(b.startMinute);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = _optionalString(json[key]);
  if (value == null) throw FormatException('Missing or invalid $key');
  return value;
}

String? _optionalString(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

int? _asInt(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

int _parseClock(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})(?::\d{2})?$').firstMatch(value);
  if (match == null) throw const FormatException('Invalid time format');
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) {
    throw const FormatException('Invalid clock time');
  }
  return hour * 60 + minute;
}

String _apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _apiTime(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';

TimeOfDay _toTimeOfDay(int minute) =>
    TimeOfDay(hour: minute ~/ 60, minute: minute % 60);

String _formatMinute(BuildContext context, int minute) =>
    _toTimeOfDay(minute).format(context);

String _durationLabel(int minutes) {
  if (minutes <= 0) return '0m';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '${remaining}m';
  if (remaining == 0) return '${hours}h';
  return '${hours}h ${remaining}m';
}

String _weekdayShort(int weekday) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

String _weekdayLong(int weekday) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][weekday - 1];

String _monthShort(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

String _monthLong(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

String _weekRange(DateTime start, DateTime end) {
  if (start.year != end.year) {
    return '${_monthShort(start.month)} ${start.day}, ${start.year} – ${_monthShort(end.month)} ${end.day}, ${end.year}';
  }
  if (start.month != end.month) {
    return '${_monthShort(start.month)} ${start.day} – ${_monthShort(end.month)} ${end.day}, ${end.year}';
  }
  return '${_monthShort(start.month)} ${start.day} – ${end.day}, ${end.year}';
}

int _isoWeekNumber(DateTime date) {
  final thursday = _dateOnly(date).add(Duration(days: 4 - date.weekday));
  final firstThursday = DateTime(thursday.year, 1, 4);
  return 1 +
      (thursday
              .difference(
                firstThursday.subtract(
                  Duration(days: firstThursday.weekday - 4),
                ),
              )
              .inDays ~/
          7);
}
