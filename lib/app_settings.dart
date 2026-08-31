import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:campus_twin/models/app_models.dart';

// =============================================================================
// USER PROFILE  (DB-backed display data)
// =============================================================================

String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

class UserProfile {
  final String id;
  final String name;
  final String nickname;
  final String email;
  final String department;
  final String semester;
  final String session;
  final String phone;
  final String photoUrl;
  final String studentId;
  final List<String> enrolledCourses;

  const UserProfile({
    required this.id,
    required this.name,
    required this.nickname,
    required this.email,
    required this.department,
    required this.semester,
    this.session = '2022-2026',
    this.phone = '',
    this.photoUrl = '',
    this.studentId = '',
    this.enrolledCourses = const [],
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? nickname,
    String? email,
    String? department,
    String? semester,
    String? session,
    String? phone,
    String? photoUrl,
    String? studentId,
    List<String>? enrolledCourses,
  }) =>
      UserProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        nickname: nickname ?? this.nickname,
        email: email ?? this.email,
        department: department ?? this.department,
        semester: semester ?? this.semester,
        session: session ?? this.session,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        studentId: studentId ?? this.studentId,
        enrolledCourses: enrolledCourses ?? this.enrolledCourses,
      );

  String get initials {
    final parts = name.split(' ').where((w) => w.isNotEmpty && w.length > 1);
    return parts.map((e) => e[0]).take(2).join().toUpperCase();
  }
}

// =============================================================================
// MOCK NOTIFICATION
// =============================================================================

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    title: title,
    body: body,
    time: time,
    icon: icon,
    color: color,
    read: read ?? this.read,
  );
}

// =============================================================================
// AVATAR PRESETS — mock "photo gallery" for the profile picture
// =============================================================================

class AvatarPresets {
  AvatarPresets._();
  static const List<List<Color>> gradients = [
    [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    [Color(0xFF06B6D4), Color(0xFF2563EB)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
    [Color(0xFF10B981), Color(0xFF059669)],
    [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    [Color(0xFFF97316), Color(0xFFDC2626)],
    [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
    [Color(0xFF6366F1), Color(0xFF0F766E)],
  ];
}

// =============================================================================
// GLOBAL APP SETTINGS
// Drives theme mode, language, notifications and the user profile.
// Mock-only: nothing is persisted to a backend yet.
// =============================================================================

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  // ── Theme ──────────────────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    notifyListeners();
  }

  // ── Language ───────────────────────────────────────────────────────────
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  set locale(Locale value) {
    if (_locale == value) return;
    _locale = value;
    notifyListeners();
  }

  // ── Notifications ──────────────────────────────────────────────────────
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  set notificationsEnabled(bool value) {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
  }

  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;

  int get unreadCount =>
      _notificationsEnabled ? _notifications.where((n) => !n.read).length : 0;

  /// Adds a real app event to the notification centre (planner reminders,
  /// new tasks, habit milestones...). Newest first.
  void pushNotification(
    String title,
    String body, {
    IconData icon = Icons.notifications_active_rounded,
    Color color = const Color(0xFF4F46E5),
    bool critical = false,
  }) {
    final now = DateTime.now();
    _notifications.insert(
      0,
      AppNotification(
        id: '${now.millisecondsSinceEpoch}-$_notificationSeq',
        title: critical ? '🚨 $title' : title,
        body: body,
        time: _isBnLocale ? 'এইমাত্র' : 'Just now',
        icon: icon,
        color: color,
      ),
    );
    _notificationSeq++;
    notifyListeners();
  }

  static int _notificationSeq = 0;
  static bool get _isBnLocale =>
      instance.locale.languageCode == 'bn';

  void markAllRead() {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
  }

  // ── Academic Level/Term ────────────────────────────────────────────────
  int? _academicLevel;
  int? _academicTerm;
  List<String> _electiveCourseIds = [];
  int? get academicLevel => _academicLevel;
  int? get academicTerm => _academicTerm;

  /// Catalog doc ids of the electives the user picked during setup
  /// (L4T1: 1 theory elective; L4T2: 1 theory + 1 sessional elective).
  List<String> get electiveCourseIds => _electiveCourseIds;

  void setAcademicInfo(int level, int term, {List<String>? electiveIds}) {
    _academicLevel = level;
    _academicTerm = term;
    if (electiveIds != null) _electiveCourseIds = electiveIds;
    notifyListeners();
  }

  /// Whether a course_catalog entry should be shown for this user:
  /// non-electives always; electives only when the user picked them.
  bool isCourseAllowed(Map<String, dynamic>? data, String docId) {
    if (data == null || data['isElective'] != true) return true;
    return _electiveCourseIds.contains(docId);
  }

  // ── Profile ────────────────────────────────────────────────────────────
  UserProfile _profile = const UserProfile(
    id: 'u1',
    name: 'Abu Salah Md. Jamil',
    nickname: 'Jamil',
    email: 'jamil@student.campustwin.edu',
    department: 'Computer Science & Engineering',
    semester: '6th Semester',
    session: '2022-2026',
    phone: '+880 1700-000001',
    enrolledCourses: ['CSE301', 'CSE302', 'CSE303', 'CSE402', 'CSE501', 'INT401'],
  );
  UserProfile get profile => _profile;
  set profile(UserProfile value) {
    _profile = value;
    notifyListeners();
  }

  // ── Course Setup ────────────────────────────────────────────────────────
  bool _courseSetupCompleted = false;
  bool get courseSetupCompleted => _courseSetupCompleted;

  void setCourseSetupCompleted(bool value) {
    _courseSetupCompleted = value;
    notifyListeners();
  }

  /// Syncs the in-memory profile with the Firestore `users/{uid}` doc.
  /// Only maps fields that exist in the database — mock-only fields
  /// (nickname, phone, session, enrolledCourses) keep their values.
  void applyAppUser(AppUser user) {
    _profile = _profile.copyWith(
      id: user.id,
      name: user.fullName.isEmpty ? _profile.name : user.fullName,
      email: user.email.isEmpty ? _profile.email : user.email,
      department: user.department.isEmpty ? _profile.department : user.department,
      semester: user.semester > 0 ? '${_ordinal(user.semester)} Semester' : _profile.semester,
      photoUrl: user.profilePhoto ?? '',
      // Synced from the DB schema so edits made on the profile screen
      // persist across reloads.
      phone: user.phone,
      studentId: user.studentId,
      nickname: '',
    );
    // Sync level/term from DB if set
    if (user.academicLevel != null) _academicLevel = user.academicLevel;
    if (user.academicTerm != null) _academicTerm = user.academicTerm;
    if (user.electiveCourses.isNotEmpty) {
      _electiveCourseIds = user.electiveCourses;
    }
    _courseSetupCompleted = user.courseSetupCompleted;
    notifyListeners();
  }

  /// Syncs the in-memory avatar with a downloaded photo URL (e.g. Google
  /// photo or a Firebase Storage link). Clears any local bytes so the
  /// network image wins.
  void setPhotoUrl(String url) {
    _avatarBytes = null;
    _avatarPresetIndex = 0;
    _profile = _profile.copyWith(photoUrl: url);
    notifyListeners();
  }

  // ── Avatar ─────────────────────────────────────────────────────────────
  Uint8List? _avatarBytes;
  int _avatarPresetIndex = 0;
  Uint8List? get avatarBytes => _avatarBytes;
  int get avatarPresetIndex => _avatarPresetIndex;
  bool get hasCustomAvatar => _avatarBytes != null;

  void setAvatarBytes(Uint8List? bytes) {
    _avatarBytes = bytes;
    notifyListeners();
  }

  void setAvatarPreset(int index) {
    _avatarPresetIndex = index;
    _avatarBytes = null;
    notifyListeners();
  }
}

// =============================================================================
// REUSABLE AVATAR WIDGET — renders the current profile picture everywhere
// =============================================================================

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.size,
    this.borderRadius = 16,
    this.showEditBadge = false,
    this.onTap,
  });

  final double size;
  final double borderRadius;
  final bool showEditBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    Widget child;
    if (s.profile.photoUrl.isNotEmpty) {
      final Widget photo;
      if (s.profile.photoUrl.startsWith('data:')) {
        // Base64 photo stored directly in Firestore.
        photo = Image.memory(
          base64Decode(s.profile.photoUrl.split(',').last),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(s, context),
        );
      } else {
        // Remote URL (e.g. Google profile photo).
        photo = Image.network(
          s.profile.photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(s, context),
        );
      }
      child = ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: photo);
    } else if (s.hasCustomAvatar) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          s.avatarBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _gradientBox(s, context),
        ),
      );
    } else {
      child = _gradientBox(s, context);
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          child,
          if (showEditBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(AppSettings s, BuildContext context) =>
      _gradientBox(s, context);

  Widget _gradientBox(AppSettings s, BuildContext context) {
    final colors = AvatarPresets.gradients[s.avatarPresetIndex %
        AvatarPresets.gradients.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          s.profile.initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
