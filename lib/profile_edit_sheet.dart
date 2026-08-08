import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/app_widget.dart';

/// Full-screen profile editor. Saves straight into [AppSettings] (mock).
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
  bool _saving = false;

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
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    _email.dispose();
    _phone.dispose();
    _department.dispose();
    _semester.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    final result = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoSourceSheet(),
    );
    if (result == null || !mounted) return;
    if (result == _PhotoChoice.gallery) {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final Uint8List bytes = await file.readAsBytes();
      if (!mounted) return;
      AppSettings.instance.setAvatarBytes(bytes);
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
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final p = AppSettings.instance.profile;
    AppSettings.instance.profile = p.copyWith(
      name: _name.text.trim().isEmpty ? p.name : _name.text.trim(),
      nickname: _nickname.text.trim().isEmpty ? p.nickname : _nickname.text.trim(),
      email: _email.text.trim().isEmpty ? p.email : _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? p.phone : _phone.text.trim(),
      department: _department.text.trim().isEmpty
          ? p.department
          : _department.text.trim(),
      semester: _semester.text.trim().isEmpty ? p.semester : _semester.text.trim(),
    );
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppStrings.saved),
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pop();
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

enum _PhotoChoice { gallery, preset }

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
