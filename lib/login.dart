import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/register.dart';
import 'package:campus_twin/app_widget.dart';
import 'package:campus_twin/twinDashboard.dart';
import 'package:campus_twin/welcome_page.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/app_settings.dart';
import 'package:campus_twin/models/app_models.dart';
import 'package:campus_twin/repositories/app_repositories.dart';
import 'package:campus_twin/services/verification_email_service.dart';
import 'package:campus_twin/services/password_reset_email_service.dart';
import 'package:campus_twin/course_setup_page.dart';

class LoginPage extends StatefulWidget {
  /// Pre-fills the email field (e.g. when jumping here from "account already
  /// exists" on the registration page).
  final String? initialEmail;

  const LoginPage({super.key, this.initialEmail});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail ?? '');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const double _heroHeight = 372;
  static const double _cardOverlap = 30;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.fillAllFields)),
      );
      return;
    }
    if (!AppStrings.isValidEmail(email)) {
      _showError(AppStrings.authInvalidEmail);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Block login until the email is verified. Every attempt re-sends
      // the verification link, so users never get stuck.
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (user != null && !user.emailVerified) {
        try {
          await VerificationEmailService.send();
        } catch (_) {}
        await FirebaseAuth.instance.signOut();
        _showError(AppStrings.emailNotVerified);
        return;
      }

      await _ensureUserProfile();

      if (!mounted) return;

      // Check if course setup is completed
      final repo = UserRepository();
      final appUser = await repo.getById(FirebaseAuth.instance.currentUser!.uid);
      if (appUser != null && !appUser.courseSetupCompleted) {
        // New user — go to course setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CourseSetupPage()),
        );
        return;
      }

      // Navigate to the Twin Dashboard on success.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(AppStrings.authErrorMessage(e.code));
    } catch (e) {
      _showError('${AppStrings.authFailed} (${e.toString()})');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Ensures users/{uid} exists. Creates it with Google profile data if
  /// missing (e.g. sign-in through Google when no local doc was made yet).
  /// Never throws — profile failure must not block an otherwise successful
  /// sign-in (the doc is re-created on the next sign-in / Edit Profile).
  Future<void> _ensureUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final repo = UserRepository();
      final existing = await repo.getById(user.uid);
      if (existing != null) return;
      await repo.createProfile(AppUser(
        id: user.uid,
        fullName: user.displayName ?? '',
        email: user.email ?? '',
        department: '',
        semester: 1,
        profilePhoto: user.photoURL,
      ));
    } catch (e) {
      debugPrint('Failed to ensure user profile: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final current = _emailController.text.trim();
    final controller = TextEditingController(
      text: AppStrings.isValidEmail(current) ? current : '',
    );

    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.forgotPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.enterEmailToReset),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(AppStrings.sendResetLink),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;
    if (!AppStrings.isValidEmail(email)) {
      _showError(AppStrings.authInvalidEmail);
      return;
    }

    try {
      await PasswordResetEmailService.send(email);
      _showMessage(AppStrings.resetEmailSent);
    } on FirebaseAuthException catch (e) {
      _showError(AppStrings.authErrorMessage(e.code));
    } catch (_) {
      _showError(AppStrings.authFailed);
    }
  }

  bool _isGoogleLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final googleSignIn = GoogleSignIn();

      // ১. সাইন-আউটের পর অ্যাকাউন্ট পিকার কল করা
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // ব্যবহারকারী যদি পিকার উইন্ডো ক্যানসেল (Cancel) করে ফিরে যান, 
      // তবে লোডিং স্টেট বন্ধ করতে হবে, তা না হলে স্ক্রিনটি চিরতরে লক (Freeze) হয়ে থাকবে।
      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return; 
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _ensureUserProfile();

      if (!mounted) return;

      // Check if course setup is completed
      final repo = UserRepository();
      final appUser = await repo.getById(FirebaseAuth.instance.currentUser!.uid);
      if (appUser != null && !appUser.courseSetupCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CourseSetupPage()),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      // ২. ব্যবহারকারী নিজে ব্যাক বাটন চেপে ক্যানসেল করলে যেন এরর ডায়ালগ না দেখায়
      if (e.toString().contains('sign_in_canceled') || e.toString().contains('12501')) {
        print("Google Sign-in cancelled by user.");
      } else {
        _showError('Google sign-in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }



  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _goToWelcome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) => Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAFF), Color(0xFFF4F8FD), Color(0xFFF9FBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _heroHeight,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: AuthAnimatedBackdrop(heroHeight: _heroHeight),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: _goToWelcome,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.22),
                                    ),
                                  ),
                                  child: Text(
                                    AppStrings.brandPill,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
        
                            const SizedBox(height: 22),
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25), 
                                child: Image.asset(
                                  'assets/Campus_Twin.png', 
                                  height: 80, 
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Center(
                              child: Text(
                                AppStrings.welcomeBack,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                AppStrings.signInContinue,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  AuthFeatureBadge(
                                    icon: Icons.security_outlined,
                                    label: AppStrings.secureSignIn,
                                  ),
                                  AuthFeatureBadge(
                                    icon: Icons.auto_awesome_outlined,
                                    label: AppStrings.personalizedSetup,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -_cardOverlap),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildLoginCard(context),
                  ),
                ),
                const SizedBox(height: 8),
                _buildRegisterPrompt(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.welcomeBack,
            style: TextStyle(
              color: AppPalette.textPrimary(context),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.signInCardSubtitle,
            style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 14.5),
          ),
          const SizedBox(height: 22),
          AppFieldLabel(AppStrings.universityEmail),
          const SizedBox(height: 10),
          AppTextField(
            controller: _emailController,
            hint: AppStrings.emailHint,
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AppFieldLabel(AppStrings.password),
          const SizedBox(height: 10),
          AppTextField(
            controller: _passwordController,
            hint: AppStrings.passwordHint,
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppPalette.textSecondary(context),
                size: 20,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              child: Text(AppStrings.forgotPassword),
            ),
          ),
          const SizedBox(height: 22),
          AppPrimaryButton(
            label: AppStrings.signIn,
            isLoading: _isLoading,
            onPressed: _handleSignIn,
          ),
          const SizedBox(height: 18),
          _buildDivider(context),
          const SizedBox(height: 18),
          AppGoogleButton(
            onPressed: _handleGoogleSignIn,
            isLoading: _isGoogleLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppPalette.border(context), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            AppStrings.or,
            style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppPalette.border(context), thickness: 1)),
      ],
    );
  }

  Widget _buildRegisterPrompt(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppStrings.dontHaveAccount,
            style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 14),
          ),
          GestureDetector(
            onTap: _goToRegister,
            child: Text(
              AppStrings.register,
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================