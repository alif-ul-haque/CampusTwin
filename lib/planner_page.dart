import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';

// =============================================================================
// DATA MODELS — mirror the API response structure so the UI never changes when
// you swap MockPlannerService for a real ApiPlannerService.
// =============================================================================

class StudyBlock {
  final String id;
  final String title;
  final String subjectName;
  final String subjectCode;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String type;
  final String? note;
  final bool isCompleted;
  final Color accent;
  final String dayLabel; // 'Mon', 'Tue', …

  const StudyBlock({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.subjectCode,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.note,
    this.isCompleted = false,
    required this.accent,
    required this.dayLabel,
  });

  Duration get duration => Duration(
        hours: endTime.hour - startTime.hour,
        minutes: endTime.minute - startTime.minute,
      );

  String get timeRangeLabel {
    final s = startTime;
    final e = endTime;
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(s.hour)}:${pad(s.minute)} - ${pad(e.hour)}:${pad(e.minute)}';
  }

  StudyBlock copyWith({bool? isCompleted, String? dayLabel}) {
    return StudyBlock(
      id: id,
      title: title,
      subjectName: subjectName,
      subjectCode: subjectCode,
      startTime: startTime,
      endTime: endTime,
      type: type,
      note: note,
      isCompleted: isCompleted ?? this.isCompleted,
      accent: accent,
      dayLabel: dayLabel ?? this.dayLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject_name': subjectName,
        'subject_code': subjectCode,
        'start_time': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'end_time': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        'type': type,
        'note': note,
        'is_completed': isCompleted,
        'day_label': dayLabel,
      };

  factory StudyBlock.fromJson(Map<String, dynamic> json, {Color? accent}) {
    TimeOfDay parseTime(String key) {
      final parts = (json[key] as String).split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return StudyBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String,
      startTime: parseTime('start_time'),
      endTime: parseTime('end_time'),
      type: json['type'] as String,
      note: json['note'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      accent: accent ?? AppColors.purple,
      dayLabel: json['day_label'] as String,
    );
  }
}

class SubjectInfo {
  final String id;
  final String name;
  final String code;
  final Color color;
  final double weeklyProgress;
  final int completedHours;
  final int totalHours;

  const SubjectInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.color,
    required this.weeklyProgress,
    required this.completedHours,
    required this.totalHours,
  });
}

class WeekStats {
  final int totalPlannedHours;
  final int completedHours;
  final int totalTasks;
  final int completedTasks;

  const WeekStats({
    required this.totalPlannedHours,
    required this.completedHours,
    required this.totalTasks,
    required this.completedTasks,
  });
}



class _PlannerRepository {

  static final List<SubjectInfo> _subjects = [
    SubjectInfo(id: 's1', name: 'Database Systems', code: 'CSE301', color: const Color(0xFF4F46E5), weeklyProgress: 0.72, completedHours: 6, totalHours: 8),
    SubjectInfo(id: 's2', name: 'Data Mining', code: 'CSE402', color: const Color(0xFF06B6D4), weeklyProgress: 0.55, completedHours: 4, totalHours: 7),
    SubjectInfo(id: 's3', name: 'Machine Learning', code: 'CSE501', color: const Color(0xFFF59E0B), weeklyProgress: 0.45, completedHours: 3, totalHours: 7),
    SubjectInfo(id: 's4', name: 'Software Eng.', code: 'CSE303', color: const Color(0xFF10B981), weeklyProgress: 0.88, completedHours: 5, totalHours: 6),
    SubjectInfo(id: 's5', name: 'Internship', code: 'INT401', color: const Color(0xFFEC4899), weeklyProgress: 0.33, completedHours: 1, totalHours: 3),
    SubjectInfo(id: 's6', name: 'Comp. Networks', code: 'CSE302', color: const Color(0xFF3B82F6), weeklyProgress: 0.60, completedHours: 3, totalHours: 5),
  ];

  static Color _colorForSubject(String code) {
    for (final s in _subjects) {
      if (s.code == code) return s.color;
    }
    return AppColors.purple;
  }

  static List<StudyBlock> _blocks = [];

  static void _initBlocks() {
    if (_blocks.isNotEmpty) return;
    final raw = [
      ('DB lecture review', 'CSE301', TimeOfDay(hour: 8, minute: 30), TimeOfDay(hour: 9, minute: 0), 'Warm-up', 'Scan lecture slides.', 'Mon'),
      ('Data Mining study', 'CSE402', TimeOfDay(hour: 11, minute: 30), TimeOfDay(hour: 13, minute: 0), 'Focus block', 'Chapter summary + 2 practice problems.', 'Mon'),
      ('DB assignment work', 'CSE301', TimeOfDay(hour: 15, minute: 0), TimeOfDay(hour: 16, minute: 15), 'Assignment', 'ER diagram for project.', 'Mon'),
      ('SE lab prep', 'CSE303', TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 30), 'Lecture', 'Review SRS template.', 'Tue'),
      ('ML assignment sprint', 'CSE501', TimeOfDay(hour: 15, minute: 0), TimeOfDay(hour: 16, minute: 30), 'Assignment', 'Draft solution outline.', 'Tue'),
      ('Networks quiz prep', 'CSE302', TimeOfDay(hour: 20, minute: 0), TimeOfDay(hour: 21, minute: 0), 'Revision', 'TCP/IP and OSI model.', 'Tue'),
      ('Comp. Networks lecture', 'CSE302', TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 10, minute: 30), 'Lecture', 'Attend class + take notes.', 'Wed'),
      ('DB group project', 'CSE301', TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 15, minute: 30), 'Assignment', 'Meet team for schema design.', 'Wed'),
      ('Revision: ML basics', 'CSE501', TimeOfDay(hour: 17, minute: 0), TimeOfDay(hour: 18, minute: 0), 'Revision', 'Linear regression & gradient descent.', 'Wed'),
      ('Data Mining quiz prep', 'CSE402', TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 0), 'Revision', 'Clustering algorithms review.', 'Thu'),
      ('ML study block', 'CSE501', TimeOfDay(hour: 13, minute: 0), TimeOfDay(hour: 14, minute: 30), 'Focus block', 'Work on neural nets assignment.', 'Thu'),
      ('SE group meeting', 'CSE303', TimeOfDay(hour: 16, minute: 0), TimeOfDay(hour: 17, minute: 0), 'Assignment', 'Sprint review & task分配.', 'Thu'),
      ('Internship report', 'INT401', TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 11, minute: 0), 'Focus block', 'Write ISO 27001 audit draft.', 'Fri'),
      ('Weekly review', '-', TimeOfDay(hour: 15, minute: 0), TimeOfDay(hour: 16, minute: 0), 'Revision', 'Review all subjects progress.', 'Fri'),
      ('Light revision', '-', TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 0), 'Revision', 'Go over weak topics.', 'Sat'),
      ('Monday prep', 'CSE402', TimeOfDay(hour: 17, minute: 0), TimeOfDay(hour: 18, minute: 0), 'Warm-up', 'Preview Data Mining slides.', 'Sun'),
    ];
    int idCounter = 1;
    _blocks = raw.map((r) {
      final accent = r.$2 == '-' ? const Color(0xFF64748B) : _colorForSubject(r.$2);
      return StudyBlock(
        id: 'b${idCounter++}',
        title: r.$1,
        subjectCode: r.$2,
        subjectName: _subjects.where((s) => s.code == r.$2).map((s) => s.name).firstOrNull ?? 'General',
        startTime: r.$3,
        endTime: r.$4,
        type: r.$5,
        note: r.$6,
        accent: accent,
        dayLabel: r.$7,
      );
    }).toList();
  }

  // -- Public mock methods (drop-in for real API) --

  static List<_DayInfo> getWeekDays() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final full = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
      _initBlocks();
      final hasActivity = _blocks.any((b) => b.dayLabel == labels[i] && !b.isCompleted);
      return _DayInfo(
        date: date,
        label: labels[i],
        fullLabel: full[i],
        dayNumber: date.day,
        isToday: isToday,
        hasActivity: hasActivity,
      );
    });
  }

  static WeekStats getWeekStats() {
    _initBlocks();
    final totalMinutes = _blocks.fold<int>(0, (sum, b) => sum + b.duration.inMinutes);
    final doneMinutes = _blocks.where((b) => b.isCompleted).fold<int>(0, (sum, b) => sum + b.duration.inMinutes);
    return WeekStats(
      totalPlannedHours: (totalMinutes / 60).round(),
      completedHours: (doneMinutes / 60).round(),
      totalTasks: _blocks.length,
      completedTasks: _blocks.where((b) => b.isCompleted).length,
    );
  }

  static List<StudyBlock> getBlocksForDay(String dayLabel) {
    _initBlocks();
    final blocks = _blocks.where((b) => b.dayLabel == dayLabel).toList();
    blocks.sort((a, b) {
      final cmp = a.startTime.hour.compareTo(b.startTime.hour);
      if (cmp != 0) return cmp;
      return a.startTime.minute.compareTo(b.startTime.minute);
    });
    return blocks;
  }

  static List<SubjectInfo> getSubjects() => List.unmodifiable(_subjects);

  static void toggleBlockComplete(String blockId) {
    _initBlocks();
    final idx = _blocks.indexWhere((b) => b.id == blockId);
    if (idx == -1) return;
    _blocks[idx] = _blocks[idx].copyWith(isCompleted: !_blocks[idx].isCompleted);
  }

  static void addBlock(StudyBlock block) {
    _initBlocks();
    _blocks.add(block);
  }

  static void deleteBlock(String blockId) {
    _initBlocks();
    _blocks.removeWhere((b) => b.id == blockId);
  }

  static Future<void> generatePlan() async {
    _initBlocks();
    // Simulate a delay then "regenerate" by toggling some completion states.
    await Future.delayed(const Duration(milliseconds: 800));
    final now = DateTime.now();
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayLabel = labels[now.weekday - 1];
    for (var i = 0; i < _blocks.length; i++) {
      if (_blocks[i].dayLabel == todayLabel) {
        _blocks[i] = _blocks[i].copyWith(isCompleted: false);
      }
    }
  }

  static void resetPlan() {
    _blocks = [];
    _initBlocks();
  }
}

// =============================================================================
// DAY INFO HELPER
// =============================================================================

class _DayInfo {
  final DateTime date;
  final String label;
  final String fullLabel;
  final int dayNumber;
  final bool isToday;
  final bool hasActivity;

  _DayInfo({
    required this.date,
    required this.label,
    required this.fullLabel,
    required this.dayNumber,
    this.isToday = false,
    this.hasActivity = false,
  });
}

// =============================================================================
// PLANNER PAGE — StatefulWidget so interactions work with mock data.
// =============================================================================

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  late List<_DayInfo> _days;
  late _DayInfo _selectedDay;
  late WeekStats _stats;
  late List<StudyBlock> _dayBlocks;
  late List<SubjectInfo> _subjects;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _days = _PlannerRepository.getWeekDays();
    _selectedDay = _days.firstWhere((d) => d.isToday, orElse: () => _days.first);
    _stats = _PlannerRepository.getWeekStats();
    _dayBlocks = _PlannerRepository.getBlocksForDay(_selectedDay.label);
    _subjects = _PlannerRepository.getSubjects();
  }

  void _selectDay(_DayInfo day) {
    if (day.label == _selectedDay.label) return;
    setState(() {
      _selectedDay = day;
      _dayBlocks = _PlannerRepository.getBlocksForDay(day.label);
    });
  }

  void _refresh() {
    // TODO: Also refetch subjects here — progress may have changed.
    //   _subjects = await ApiService.getSubjects(userId);
    setState(() {
      _stats = _PlannerRepository.getWeekStats();
      _dayBlocks = _PlannerRepository.getBlocksForDay(_selectedDay.label);
      _days = _PlannerRepository.getWeekDays();
    });
  }

  Future<void> _handleGenerate() async {
    setState(() => _isGenerating = true);
    await _PlannerRepository.generatePlan();
    _refresh();
    setState(() => _isGenerating = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Study plan optimised for the week!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleComplete(String blockId) {
    _PlannerRepository.toggleBlockComplete(blockId);
    _refresh();
  }

  void _deleteBlock(String blockId) {
    _PlannerRepository.deleteBlock(blockId);
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Task removed.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showAddTaskSheet() {
    _PlannerRepository.resetPlan();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(
        selectedDayLabel: _selectedDay.label,
        subjects: _subjects,
        onAdd: (block) {
          _PlannerRepository.addBlock(block);
          _refresh();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showBlockDetail(StudyBlock block) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BlockDetailSheet(
        block: block,
        onToggle: () {
          _toggleComplete(block.id);
          Navigator.of(context).pop();
        },
        onDelete: () {
          _deleteBlock(block.id);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF6F9FF), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            children: [
              _buildWeekHeader(),
              const SizedBox(height: 14),
              _buildDayStrip(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildSectionTitle('Today\'s plan'),
              const SizedBox(height: 10),
              _buildDaySchedule(),
              const SizedBox(height: 20),
              _buildSectionTitle('Subjects'),
              const SizedBox(height: 10),
              _buildSubjectsRow(),
              const SizedBox(height: 20),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  // -- Week header (month label + left/right arrows) --

  Widget _buildWeekHeader() {
    final monday = _days.first.date;
    final sunday = _days.last.date;
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final label = '${monthNames[monday.month - 1]} ${monday.day} - ${sunday.day}, ${monday.year}';
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Week ${_weekNumber(monday)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(startOfYear).inDays;
    return ((diff + startOfYear.weekday - 1) / 7).ceil();
  }

  // -- Horizontal day strip --

  Widget _buildDayStrip() {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) => _DayBubble(
          day: _days[i],
          isSelected: _days[i].label == _selectedDay.label,
          onTap: () => _selectDay(_days[i]),
        ),
      ),
    );
  }

  // -- Stats row --

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _StatCard(
          icon: Icons.schedule_rounded,
          label: 'Planned',
          value: '${_stats.totalPlannedHours}h',
          accent: AppColors.purple,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.check_circle_outline_rounded,
          label: 'Completed',
          value: '${_stats.completedHours}h',
          accent: const Color(0xFF10B981),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          icon: Icons.task_alt_rounded,
          label: 'Tasks',
          value: '${_stats.completedTasks}/${_stats.totalTasks}',
          accent: const Color(0xFF06B6D4),
        )),
      ],
    );
  }

  // -- Today's plan schedule --

  Widget _buildDaySchedule() {
    if (_dayBlocks.isEmpty) {
      return _emptyState(
        _selectedDay.isToday
            ? 'No study blocks planned for today. Tap + to add one!'
            : 'Nothing scheduled for ${_selectedDay.fullLabel}.',
        Icons.event_busy_rounded,
      );
    }
    return Column(
      children: _dayBlocks.map((block) => _ScheduleCard(
        block: block,
        onToggle: () => _toggleComplete(block.id),
        onTap: () => _showBlockDetail(block),
        onDelete: () => _deleteBlock(block.id),
      )).toList(),
    );
  }

  // -- Subjects horizontal scroll --

  Widget _buildSubjectsRow() {
    if (_subjects.isEmpty) {
      return _emptyState('No subjects added yet.', Icons.menu_book_rounded);
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _subjects.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) => _SubjectChip(subject: _subjects[i]),
      ),
    );
  }

  // -- Quick actions --

  Widget _buildQuickActions() {
    return _GlowCard(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _showAddTaskSheet,
                      icon: const Icon(Icons.add_task_rounded, size: 18),
                      label: const Text('Add task', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isGenerating ? null : _handleGenerate,
                      icon: _isGenerating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(
                        _isGenerating ? 'Optimising…' : 'Generate',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Color(0xFF4F46E5).withValues(alpha: 0.06),
                        foregroundColor: AppColors.purple,
                        side: BorderSide(color: AppColors.purple.withValues(alpha: 0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -- Shared widgets --

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
        const Spacer(),
        if (title == 'Today\'s plan' && _dayBlocks.isNotEmpty)
          Text(
            '${_dayBlocks.where((b) => b.isCompleted).length}/${_dayBlocks.length}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return _GlowCard(
      radius: 16,
      strokeWidth: 1.2,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DAY BUBBLE
// =============================================================================

class _DayBubble extends StatelessWidget {
  final _DayInfo day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayBubble({required this.day, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.purple
                : day.hasActivity
                    ? AppColors.purple.withValues(alpha: 0.25)
                    : AppColors.border.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.purple.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day.dayNumber.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (day.hasActivity && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
              ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// STAT CARD
// =============================================================================

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatCard({required this.icon, required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return _GlowCard(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0.06)],
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
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SCHEDULE CARD
// =============================================================================

class _ScheduleCard extends StatelessWidget {
  final StudyBlock block;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScheduleCard({required this.block, required this.onToggle, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(block.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 24),
        ),
        confirmDismiss: (_) async {
          onDelete();
          return false;
        },
        child: GestureDetector(
          onTap: onTap,
          child: _GlowCard(
            radius: 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: block.isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.04) : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  SizedBox(
                    width: 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${block.startTime.hour.toString().padLeft(2, '0')}:${block.startTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: block.isCompleted ? AppColors.textSecondary.withValues(alpha: 0.6) : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${block.endTime.hour.toString().padLeft(2, '0')}:${block.endTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: block.isCompleted ? 0.4 : 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Accent bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    width: 4,
                    height: block.isCompleted ? 32 : 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          block.isCompleted ? const Color(0xFF10B981) : block.accent,
                          block.isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.4) : block.accent.withValues(alpha: 0.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                block.title,
                                style: TextStyle(
                                  color: block.isCompleted ? AppColors.textSecondary.withValues(alpha: 0.7) : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  decoration: block.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            // Completion toggle
                            GestureDetector(
                              onTap: onToggle,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: block.isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                                  border: Border.all(
                                    color: block.isCompleted ? const Color(0xFF10B981) : AppColors.border,
                                    width: block.isCompleted ? 0 : 2,
                                  ),
                                ),
                                child: block.isCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        if (block.note != null && block.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            block.note!,
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: block.isCompleted ? 0.5 : 0.8),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Tag(label: block.type, color: block.accent),
                            const SizedBox(width: 8),
                            _Tag(label: block.subjectName, color: const Color(0xFF64748B)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUBJECT CHIP
// =============================================================================

class _SubjectChip extends StatelessWidget {
  final SubjectInfo subject;

  const _SubjectChip({required this.subject});

  @override
  Widget build(BuildContext context) {
    final progress = subject.weeklyProgress.clamp(0.0, 1.0);
    return _GlowCard(
      radius: 16,
      child: SizedBox(
        width: 130,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: subject.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subject.code,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: subject.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subject.name,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.border.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(subject.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAG
// =============================================================================

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// =============================================================================
// GLOW CARD (shared visual wrapper, same design language as the dashboard)
// =============================================================================

class _GlowCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final double strokeWidth;
  const _GlowCard({
    required this.child,
    this.radius = 16,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  const _StaticBorderBox({
    required this.child,
    this.borderRadius = 16,
    this.strokeWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RotatingBorderPainter(
        t: 0,
        radius: borderRadius,
        strokeWidth: strokeWidth,
        colors: const [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF1E40AF)],
      ),
      child: Padding(
        padding: EdgeInsets.all(strokeWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((borderRadius - strokeWidth).clamp(0, borderRadius)),
          child: ColoredBox(
            color: AppColors.card,
            child: child,
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
  bool shouldRepaint(covariant _RotatingBorderPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.colors != colors;
  }
}

// =============================================================================
// ADD TASK BOTTOM SHEET
// =============================================================================

class _AddTaskSheet extends StatefulWidget {
  final String selectedDayLabel;
  final List<SubjectInfo> subjects;
  final ValueChanged<StudyBlock> onAdd;

  const _AddTaskSheet({
    required this.selectedDayLabel,
    required this.subjects,
    required this.onAdd,
  });

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _selectedSubjectCode;
  late String _selectedType;
  late String _selectedDay;

  final _types = ['Warm-up', 'Focus block', 'Lecture', 'Assignment', 'Revision'];

  @override
  void initState() {
    super.initState();
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 10, minute: 0);
    _selectedSubjectCode = widget.subjects.isNotEmpty ? widget.subjects.first.code : '';
    _selectedType = _types.first;
    _selectedDay = widget.selectedDayLabel;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_endTime.hour < _startTime.hour || (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(hour: picked.hour + 1, minute: picked.minute);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final subject = widget.subjects.firstWhere(
      (s) => s.code == _selectedSubjectCode,
      orElse: () => widget.subjects.first,
    );
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final block = StudyBlock(
      id: 'b_$id',
      title: _titleCtrl.text.trim(),
      subjectName: subject.name,
      subjectCode: subject.code,
      startTime: _startTime,
      endTime: _endTime,
      type: _selectedType,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      accent: subject.color,
      dayLabel: _selectedDay,
    );
    widget.onAdd(block);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
          shrinkWrap: true,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add study task',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Task title',
                hintText: 'e.g. Database revision',
                prefixIcon: Icon(Icons.assignment_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 14),
            // Row: Day + Type
            Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: 'Day',
                    value: _selectedDay,
                    items: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                    onChanged: (v) => setState(() => _selectedDay = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropdownField(
                    label: 'Type',
                    value: _selectedType,
                    items: _types,
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Subject
            _DropdownField(
              label: 'Subject',
              value: _selectedSubjectCode,
              items: widget.subjects.map((s) => s.code).toList(),
              displayMap: {for (final s in widget.subjects) s.code: '${s.code} - ${s.name}'},
              onChanged: (v) => setState(() => _selectedSubjectCode = v!),
            ),
            const SizedBox(height: 14),
            // Time row
            Row(
              children: [
                Expanded(
                  child: _TimePickerField(
                    label: 'Start',
                    time: _startTime,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 18),
                ),
                Expanded(
                  child: _TimePickerField(
                    label: 'End',
                    time: _endTime,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add details or resources',
                prefixIcon: Icon(Icons.notes_rounded, size: 20),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Add to planner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DROPDOWN FIELD (reusable for bottom sheet)
// =============================================================================

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final Map<String, String>? displayMap;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    this.displayMap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          underline: const SizedBox.shrink(),
          items: items.map((item) {
            final display = displayMap?[item] ?? item;
            return DropdownMenuItem(value: item, child: Text(display, style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// =============================================================================
// TIME PICKER FIELD
// =============================================================================

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerField({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(
              '${pad(time.hour)}:${pad(time.minute)}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BLOCK DETAIL BOTTOM SHEET
// =============================================================================

class _BlockDetailSheet extends StatelessWidget {
  final StudyBlock block;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _BlockDetailSheet({required this.block, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999))),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: block.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                _Tag(label: block.type, color: block.accent),
                const SizedBox(width: 8),
                _Tag(label: block.subjectName, color: const Color(0xFF64748B)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              block.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            if (block.note != null && block.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(block.note!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${block.startTime.format(context)} - ${block.endTime.format(context)}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: block.isCompleted ? const Color(0xFF10B981).withValues(alpha: 0.1) : AppColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    block.isCompleted ? 'Done' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: block.isCompleted ? const Color(0xFF10B981) : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: BorderSide(color: Color(0xFFDC2626).withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: onToggle,
                      icon: Icon(block.isCompleted ? Icons.undo_rounded : Icons.check_rounded, size: 18),
                      label: Text(block.isCompleted ? 'Mark pending' : 'Mark done'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: block.isCompleted ? AppColors.border : const Color(0xFF10B981),
                        foregroundColor: block.isCompleted ? AppColors.textPrimary : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
