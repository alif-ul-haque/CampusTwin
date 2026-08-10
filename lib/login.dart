import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/register.dart';
import 'package:campus_twin/app_widget.dart';
import 'package:campus_twin/twinDashboard.dart';
import 'package:campus_twin/welcome_page.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/app_settings.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
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

    setState(() => _isLoading = true);

    // TODO: Replace with real authentication call.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to the Twin Dashboard on success.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardPage()),
    );
  }

  static const _accountsChannel =
      MethodChannel('campus_twin/accounts');

  bool _isGoogleLoading = false;

  Future<List<String>> _getDeviceGoogleAccounts() async {
    try {
      final List<dynamic> raw =
          await _accountsChannel.invokeMethod('getGoogleAccounts');
      return raw.cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // 1. Fetch device accounts
    setState(() => _isGoogleLoading = true);
    final accounts = await _getDeviceGoogleAccounts();
    setState(() => _isGoogleLoading = false);

    if (!mounted) return;

    // 2. Show custom picker sheet
    final choice = await showModalBottomSheet<_AccountChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _GoogleAccountSheet(emails: accounts),
    );

    if (choice == null) return; // user tapped outside / cancelled

    // 3. Perform sign-in
    setState(() => _isGoogleLoading = true);
    try {
      final googleSignIn = GoogleSignIn();

      GoogleSignInAccount? googleUser;
      // Always signOut first so the account picker appears fresh,
      // letting the user confirm/pick the account they tapped in our sheet.
      await googleSignIn.signOut();
      googleUser = await googleSignIn.signIn();

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

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: ${e.toString()}'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
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
              onPressed: () {},
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
// Account choice model
// =============================================================================

class _AccountChoice {
  final String? email;
  final bool addNew;
  const _AccountChoice.existing(this.email) : addNew = false;
  const _AccountChoice.add()
      : email = null,
        addNew = true;
}

// =============================================================================
// Custom Google account picker bottom sheet
// =============================================================================

class _GoogleAccountSheet extends StatelessWidget {
  final List<String> emails;
  const _GoogleAccountSheet({required this.emails});

  @override
  Widget build(BuildContext context) {
    final hasAccounts = emails.isNotEmpty;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // ── Google G logo + title ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: const Center(
                      child: Text('G',
                          style: TextStyle(
                            color: Color(0xFF4285F4),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Choose an account',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937))),
                      Text(
                        hasAccounts
                            ? 'Select a Google account to continue'
                            : 'No Google accounts found on this device',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 4),
            // ── Account tiles ────────────────────────────────────────────
            if (hasAccounts)
              ...emails.map((email) => _AccountTile(
                    email: email,
                    onTap: () => Navigator.of(context)
                        .pop(_AccountChoice.existing(email)),
                  )),
            // ── Add account ──────────────────────────────────────────────
            _ActionTile(
              icon: Icons.add_circle_outline_rounded,
              iconColor: const Color(0xFF4285F4),
              label: hasAccounts ? 'Add another account' : 'Add account',
              onTap: () =>
                  Navigator.of(context).pop(const _AccountChoice.add()),
            ),
            const Divider(height: 1, indent: 24, endIndent: 24),
            const SizedBox(height: 4),
            // ── Cancel ───────────────────────────────────────────────────
            _ActionTile(
              icon: Icons.close_rounded,
              iconColor: const Color(0xFF6B7280),
              label: 'Cancel',
              onTap: () => Navigator.of(context).pop(null),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Reusable tiles ────────────────────────────────────────────────────────────

class _AccountTile extends StatelessWidget {
  final String email;
  final VoidCallback onTap;
  const _AccountTile({required this.email, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF4F46E5), const Color(0xFF0891B2),
      const Color(0xFF059669), const Color(0xFFD97706),
      const Color(0xFFDC2626), const Color(0xFF7C3AED),
    ];
    final color = colors[email.hashCode.abs() % colors.length];
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937))),
                  const Text('Google Account',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFD1D5DB), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: label == 'Cancel'
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF1F2937))),
          ],
        ),
      ),
    );
  }
}