import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/twinDashboard.dart';

// =============================================================================
// COURSE SETUP — Onboarding page where new users add their courses.
// This replaces the old auto-filled course_catalog system.
// =============================================================================

class _CourseEntry {
  final TextEditingController nameController;
  final TextEditingController codeController;
  _CourseEntry({required this.nameController, required this.codeController});
  _CourseEntry.empty()
      : nameController = TextEditingController(),
        codeController = TextEditingController();
  void dispose() {
    nameController.dispose();
    codeController.dispose();
  }
}

class CourseSetupPage extends StatefulWidget {
  final bool isEditing;
  const CourseSetupPage({super.key, this.isEditing = false});

  @override
  State<CourseSetupPage> createState() => _CourseSetupPageState();
}

class _CourseSetupPageState extends State<CourseSetupPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final List<_CourseEntry> _courses = [];
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _loadedExisting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();

    if (widget.isEditing) _loadExistingCourses();
    if (!widget.isEditing && _courses.isEmpty) _courses.add(_CourseEntry.empty());
  }

  @override
  void dispose() {
    _animController.dispose();
    for (final c in _courses) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingCourses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('courses')
          .where('user_id', isEqualTo: uid)
          .get();
      if (!mounted || _loadedExisting) return;
      _loadedExisting = true;
      setState(() {
        for (final doc in snap.docs) {
          final data = doc.data();
          _courses.add(_CourseEntry(
            nameController: TextEditingController(text: data['course_title'] ?? ''),
            codeController: TextEditingController(text: data['course_code'] ?? ''),
          ));
        }
        if (_courses.isEmpty) _courses.add(_CourseEntry.empty());
      });
    } catch (_) {}
  }

  void _addCourse() {
    setState(() => _courses.add(_CourseEntry.empty()));
  }

  void _removeCourse(int index) {
    if (_courses.length <= 1) return;
    setState(() {
      _courses[index].dispose();
      _courses.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Validate at least one course has a name
    final validCourses = _courses
        .where((e) => e.nameController.text.trim().isNotEmpty)
        .toList();
    if (validCourses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            AppSettings.instance.locale.languageCode == 'bn'
                ? 'অন্তত একটি কোর্স যোগ করুন'
                : 'Add at least one course',
          ),
          backgroundColor: const Color(0xFFF59E0B),
        ));
      }
      return;
    }

    setState(() => _saving = true);
    try {
      // Delete existing user courses
      final existing = await FirebaseFirestore.instance
          .collection('courses')
          .where('user_id', isEqualTo: uid)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Write new courses
      final writeBatch = FirebaseFirestore.instance.batch();
      for (final entry in validCourses) {
        final name = entry.nameController.text.trim();
        final code = entry.codeController.text.trim();
        final ref = FirebaseFirestore.instance.collection('courses').doc();
        writeBatch.set(ref, {
          'user_id': uid,
          'course_title': name,
          'course_code': code,
          'credit': 0,
          'instructor': '',
          'attendance_percent': 0,
        });
      }
      await writeBatch.commit();

      // Mark setup completed
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'course_setup_completed': true},
        SetOptions(merge: true),
      );
      AppSettings.instance.setCourseSetupCompleted(true);

      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.pop(context, true);
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const _CourseSetupDonePage(),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save courses: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _skipSetup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'course_setup_completed': true},
        SetOptions(merge: true),
      );
      AppSettings.instance.setCourseSetupCompleted(true);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBn = AppSettings.instance.locale.languageCode == 'bn';

    return Scaffold(
      backgroundColor: AppPalette.background(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                children: [
                  if (!widget.isEditing) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _saving ? null : _skipSetup,
                        style: TextButton.styleFrom(
                          foregroundColor: AppPalette.textSecondary(context),
                        ),
                        child: Text(
                          isBn ? 'এড়িয়ে যান' : 'Skip',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.purple.withValues(alpha: 0.15),
                              AppColors.purpleLight.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 36,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        isBn ? 'আপনার কোর্স যোগ করুন' : 'Add Your Courses',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.textPrimary(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        isBn
                            ? 'আপনি কোন কোর্সগুলো পড়ছেন সেগুলো লিখুন।\nপরে সেটিংস থেকে এডিট করতে পারবেন।'
                            : 'Enter the courses you\'re currently taking.\nYou can edit these later from your profile.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppPalette.textSecondary(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  if (widget.isEditing) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back_rounded,
                              color: AppPalette.textPrimary(context)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isBn ? 'কোর্স পরিচালনা' : 'Manage Courses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppPalette.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  ...List.generate(_courses.length, (i) {
                    return _buildCourseCard(i, isBn);
                  }),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _addCourse,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.purple.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded,
                              color: AppColors.purple, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            isBn ? 'আরেকটি কোর্স যোগ করুন' : 'Add Another Course',
                            style: const TextStyle(
                              color: AppColors.purple,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.purple.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isBn ? 'সংরক্ষণ করুন' : 'Save Courses',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          isBn ? 'বাতিল' : 'Cancel',
                          style: TextStyle(
                            color: AppPalette.textSecondary(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(int index, bool isBn) {
    final entry = _courses[index];
    final canRemove = _courses.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${isBn ? 'কোর্স' : 'Course'} ${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textPrimary(context),
                    ),
                  ),
                ),
                if (canRemove)
                  GestureDetector(
                    onTap: () => _removeCourse(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isBn ? 'কোর্স কোড' : 'Course Code',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPalette.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: entry.codeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [ FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')) ],
              decoration: _inputDecoration(context, 'e.g. CSE301'),
              style: TextStyle(
                color: AppPalette.textPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isBn ? 'কোর্সের নাম' : 'Course Name',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPalette.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: entry.nameController,
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return isBn ? 'কোর্সের নাম দিন' : 'Enter course name';
                }
                return null;
              },
              decoration: _inputDecoration(context, isBn ? 'e.g. Data Structures' : 'e.g. Data Structures'),
              style: TextStyle(
                color: AppPalette.textPrimary(context),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppPalette.textSecondary(context).withValues(alpha: 0.5),
        fontSize: 13.5,
      ),
      filled: true,
      fillColor: AppPalette.inputFill(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppPalette.border(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppPalette.border(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }
}

// =============================================================================
// Done confirmation page
// =============================================================================

class _CourseSetupDonePage extends StatelessWidget {
  const _CourseSetupDonePage();

  @override
  Widget build(BuildContext context) {
    final isBn = AppSettings.instance.locale.languageCode == 'bn';
    return Scaffold(
      backgroundColor: AppPalette.background(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                isBn ? 'সব তৈরি!' : 'You\'re All Set!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppPalette.textPrimary(context),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isBn
                    ? 'আপনার কোর্সগুলো সংরক্ষিত হয়েছে।\nএখন অ্যাপের সব ফিচার ব্যবহার করতে পারবেন।'
                    : 'Your courses have been saved.\nYou now have full access to the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppPalette.textSecondary(context),
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardPage()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isBn ? 'অ্যাপে প্রবেশ করুন' : 'Enter App',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
