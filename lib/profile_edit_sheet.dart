import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/app_widget.dart';
import 'package:campus_twin/repositories/app_repositories.dart';

/// Full-screen profile editor. Reads/writes the `users/{uid}` Firestore
/// doc; profile photos go to Firebase Storage and the download URL is
/// stored in `profile_photo`.
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _nickname;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _department;
  late final TextEditingController _semester;
  late final TextEditingController _studentId;
  bool _saving = false;
  bool _photoChanged = false;

  @override
  void initState() {
    super.initState();
    final p = AppSettings.instance.profile;
    _name = TextEditingController(text: p.name);
    _nickname = TextEditingController(text: p.nickname);
    _email = TextEditingController(text: p.email);
    _phone = TextEditingController(text: p.phone);
    _department = TextEditingController(text: p.department);
    _semester = TextEditingController(text: p.semester);
    _studentId = TextEditingController(text: p.studentId);
    _loadFromDb();
  }

  /// Prefills the form from Firestore so the editor always shows the
  /// database values (not the in-memory mock).
  Future<void> _loadFromDb() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final appUser = await UserRepository().getById(user.uid);
      if (appUser == null || !mounted) return;
      _name.text = appUser.fullName.isEmpty ? _name.text : appUser.fullName;
      _email.text = appUser.email.isEmpty ? _email.text : appUser.email;
      _department.text =
          appUser.department.isEmpty ? _department.text : appUser.department;
      if (appUser.semester > 0) {
        _semester.text = '${appUser.semester}';
      }
      if (appUser.phone.isNotEmpty) _phone.text = appUser.phone;
      if (appUser.studentId.isNotEmpty) _studentId.text = appUser.studentId;
      setState(() {});
    } catch (e) {
      debugPrint('Failed to load profile from DB: $e');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _email.dispose();
    _phone.dispose();
    _department.dispose();
    _semester.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final result = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(),
    );
    if (result == null || !mounted) return;
    if (result == _PhotoChoice.gallery || result == _PhotoChoice.camera) {
      final file = await ImagePicker().pickImage(
        source: result == _PhotoChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      AppSettings.instance.setAvatarBytes(bytes);
      _photoChanged = true;
    } else if (result == _PhotoChoice.preset) {
      if (!mounted) return;
      _pickPreset();
    }
  }

  Future<void> _pickPreset() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PresetSheet(),
    );
    if (index != null && mounted) {
      AppSettings.instance.setAvatarPreset(index);
      _photoChanged = true;
    }
  }

  /// Encodes the picked photo as a base64 data-URI so it can live inside
  /// the Firestore `profile_photo` field (no Firebase Storage / billing).
  String? _encodePhoto() {
    final bytes = AppSettings.instance.avatarBytes;
    if (bytes == null) return null;
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final p = AppSettings.instance.profile;
      final name = _name.text.trim().isEmpty ? p.name : _name.text.trim();
      final email = _email.text.trim().isEmpty ? p.email : _email.text.trim();
      final department = _department.text.trim().isEmpty
          ? p.department
          : _department.text.trim();
      final semesterText = _semester.text.trim().isEmpty
          ? p.semester
          : _semester.text.trim();
      final phone = _phone.text.trim().isEmpty ? p.phone : _phone.text.trim();
      final studentId =
          _studentId.text.trim().isEmpty ? p.studentId : _studentId.text.trim();

      // Persist to Firestore (users/{uid}) — silently skips when no
      // authenticated user, keeping the old local-only behaviour.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final semNum = int.tryParse(
                semesterText.replaceAll(RegExp(r'[^\d]'), '')) ??
            1;
        // Derive Level/Term (2 semesters per academic year):
        // Semester N → Level = (N-1)~/2 + 1, Term = (N-1)%2 + 1.
        final derivedLevel = (semNum - 1) ~/ 2 + 1;
        final derivedTerm = (semNum - 1) % 2 + 1;
        final patch = <String, dynamic>{
          'full_name': name,
          'email': email,
          'department': department,
          'semester': semNum,
          'academic_level': derivedLevel,
          'academic_term': derivedTerm,
          if (phone.isNotEmpty) 'phone': phone,
          if (studentId.isNotEmpty) 'student_id': studentId,
        };
        if (_photoChanged) {
          final dataUri = _encodePhoto();
          if (dataUri != null) patch['profile_photo'] = dataUri;
        }
        await UserRepository().update(user.uid, patch);
        if (patch['profile_photo'] != null) {
          AppSettings.instance
              .setPhotoUrl(patch['profile_photo']! as String);
        }
        AppSettings.instance.setAcademicInfo(derivedLevel, derivedTerm);
      }

      // Update the in-memory profile so the whole UI reflects the save.
      AppSettings.instance.profile = p.copyWith(
        name: name,
        nickname: _nickname.text.trim().isEmpty
            ? p.nickname
            : _nickname.text.trim(),
        email: email,
        phone: phone,
        studentId: studentId,
        department: department,
        semester: semesterText,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.saved),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${AppStrings.authFailed} (${e.toString()})'),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background(context),
      appBar: AppBar(
        backgroundColor: AppPalette.background(context),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppPalette.textPrimary(context),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.editProfile,
          style: TextStyle(
            color: AppPalette.textPrimary(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: ListenableBuilder(
              listenable: AppSettings.instance,
              builder: (context, _) => AppAvatar(
                size: 104,
                borderRadius: 28,
                showEditBadge: true,
                onTap: _changePhoto,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _changePhoto,
              icon: const Icon(Icons.photo_camera_rounded, size: 18),
              label: Text(
                AppStrings.changePhoto,
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(AppStrings.name, _name, Icons.badge_outlined),
          const SizedBox(height: 14),
          _field(AppStrings.nickname, _nickname, Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _field(AppStrings.email, _email, Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _field(AppStrings.phone, _phone, Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _field(AppStrings.department, _department, Icons.school_outlined),
          const SizedBox(height: 14),
          _field(AppStrings.semester, _semester, Icons.auto_stories_outlined),
          const SizedBox(height: 14),
          _field(AppStrings.studentId, _studentId, Icons.badge_outlined),
          const SizedBox(height: 28),
          AppPrimaryButton(
            label: AppStrings.save,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: AppFieldLabel(label),
        ),
        AppTextField(
          controller: controller,
          hint: label,
          icon: icon,
          keyboardType: keyboardType,
        ),
      ],
    );
  }
}

enum _PhotoChoice { camera, gallery, preset }

class _PhotoSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 20),
          _option(
            context,
            icon: Icons.photo_camera_outlined,
            title: AppStrings.takePhoto,
            onTap: () => Navigator.of(context).pop(_PhotoChoice.camera),
          ),
          const SizedBox(height: 12),
          _option(
            context,
            icon: Icons.photo_library_outlined,
            title: AppStrings.chooseFromGallery,
            onTap: () => Navigator.of(context).pop(_PhotoChoice.gallery),
          ),
          const SizedBox(height: 12),
          _option(
            context,
            icon: Icons.emoji_emotions_outlined,
            title: AppStrings.choosePreset,
            onTap: () => Navigator.of(context).pop(_PhotoChoice.preset),
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4F46E5), size: 22),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 20),
          const Text(
            'Choose an avatar',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: AvatarPresets.gradients.length,
            itemBuilder: (context, i) {
              final colors = AvatarPresets.gradients[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).pop(i),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      AppSettings.instance.profile.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
