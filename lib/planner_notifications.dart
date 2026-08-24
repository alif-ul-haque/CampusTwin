import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// ============================================================
// PlannerNotificationService
// Handles all scheduled notifications for planner tasks.
// ============================================================
class PlannerNotificationService {
  PlannerNotificationService._();
  static final PlannerNotificationService instance =
      PlannerNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    // Set up correct local timezone for scheduling
    tz_data.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ---- Cancel all notifications for a task ----
  Future<void> cancelTaskNotifications(String taskId) async {
    // Each task uses a range of notification IDs derived from its hash
    final base = taskId.hashCode.abs() % 90000000;
    for (int i = 0; i < 30; i++) {
      await _plugin.cancel(base + i);
    }
  }

  // ---- Schedule all notifications for a task ----
  Future<void> scheduleTaskNotifications({
    required String taskId,
    required String taskTitle,
    required String taskType, // 'assignment' | 'study' | 'revision' | etc.
    required DateTime taskDate,
    required int startMinute, // minutes from midnight
    required int endMinute,
  }) async {
    await init();
    await cancelTaskNotifications(taskId);

    final base = taskId.hashCode.abs() % 90000000;
    int notifIndex = 0;

    final taskStart = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
      startMinute ~/ 60,
      startMinute % 60,
    );
    final taskEnd = DateTime(
      taskDate.year,
      taskDate.month,
      taskDate.day,
      endMinute ~/ 60,
      endMinute % 60,
    );
    final now = DateTime.now();

    Future<void> scheduleAt(
      DateTime when,
      String title,
      String body, {
      bool critical = false,
    }) async {
      final now = DateTime.now();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          critical ? 'planner_critical' : 'planner_reminders',
          critical ? 'Critical Deadline Alerts' : 'Planner Reminders',
          channelDescription: critical
              ? 'Last-hour deadline critical alerts'
              : 'Study planner task reminders',
          importance: critical ? Importance.max : Importance.high,
          priority: critical ? Priority.max : Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: critical,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: critical
              ? InterruptionLevel.critical
              : InterruptionLevel.active,
        ),
      );

      if (when.isBefore(now)) {
        // If the reminder time passed less than 5 minutes ago (e.g. user just scheduled 
        // a task that starts in 4 minutes), show the reminder immediately instead of dropping it.
        if (now.difference(when).inMinutes < 5) {
          await _plugin.show(base + notifIndex++, title, body, details);
        }
        return;
      }

      final tzWhen = tz.TZDateTime.from(when, tz.local);
      await _plugin.zonedSchedule(
        base + notifIndex++,
        title,
        body,
        tzWhen,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (taskType == 'assignment') {
      // ── Assignment / Deadline notifications ──────────────────
      final deadline = taskEnd; // treat end time as the deadline

      // 6 hours before
      await scheduleAt(
        deadline.subtract(const Duration(hours: 6)),
        '📋 Assignment Reminder',
        '"$taskTitle" due in 6 hours!',
      );
      // 3 hours before
      await scheduleAt(
        deadline.subtract(const Duration(hours: 3)),
        '⏰ Assignment Due Soon',
        '"$taskTitle" due in 3 hours!',
      );
      // Every 1 hour until the last hour
      for (int h = 2; h > 1; h--) {
        await scheduleAt(
          deadline.subtract(Duration(hours: h)),
          '⚠️ Assignment Reminder',
          '"$taskTitle" due in $h hour${h > 1 ? 's' : ''}!',
        );
      }
      // Last hour: every 30 minutes — critical alerts
      await scheduleAt(
        deadline.subtract(const Duration(minutes: 60)),
        '🚨 DEADLINE IN 1 HOUR',
        '"$taskTitle" is almost due! Submit now!',
        critical: true,
      );
      await scheduleAt(
        deadline.subtract(const Duration(minutes: 30)),
        '🚨 DEADLINE IN 30 MINUTES',
        '"$taskTitle" deadline is in 30 minutes!',
        critical: true,
      );
      await scheduleAt(
        deadline.subtract(const Duration(minutes: 10)),
        '🚨 DEADLINE IN 10 MINUTES',
        '"$taskTitle" — 10 minutes left!',
        critical: true,
      );
      await scheduleAt(
        deadline,
        '❌ DEADLINE REACHED',
        '"$taskTitle" deadline has passed!',
        critical: true,
      );
    } else {
      // ── Study / Class / Revision / Exam Prep ─────────────────
      final label = _labelFor(taskType);
      // 1 hour before start
      await scheduleAt(
        taskStart.subtract(const Duration(hours: 1)),
        '📚 $label Starting Soon',
        '"$taskTitle" starts in 1 hour.',
      );
      // 5 minutes before start
      await scheduleAt(
        taskStart.subtract(const Duration(minutes: 5)),
        '⏱️ $label Starting in 5 Minutes',
        '"$taskTitle" is about to start!',
      );
    }
  }

  String _labelFor(String type) {
    switch (type) {
      case 'study':
        return 'Study Session';
      case 'revision':
        return 'Revision';
      case 'exam_prep':
        return 'Exam Prep';
      case 'class':
        return 'Class';
      default:
        return 'Task';
    }
  }
}
