import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/app_widget.dart';
import 'package:campus_twin/l10n.dart';
import 'package:campus_twin/app_settings.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const double _heroHeight = 372;
  static const double _cardOverlap = 30;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.fillAllFields)),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.passwordTooShort)),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Replace with real registration call.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _goToLogin() {
    Navigator.pop(context);
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
                            _buildBackButton(context),
                            const SizedBox(height: 10),
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
                                AppStrings.createAccountHero,
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
                                AppStrings.setStudentProfile,
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
                                    icon: Icons.verified_outlined,
                                    label: AppStrings.fastOnboarding,
                                  ),
                                  AuthFeatureBadge(
                                    icon: Icons.lock_outline,
                                    label: AppStrings.privateProfile,
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
                    child: _buildRegisterCard(context),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLoginPrompt(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _goToLogin,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.arrow_back,
              color: AppPalette.textPrimary(context),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPalette.card(context),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppPalette.border(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 32,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.createAccountCardTitle,
            style: TextStyle(
              color: AppPalette.textPrimary(context),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.completeForm,
            style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 14.5),
          ),
          const SizedBox(height: 22),
          AppFieldLabel(AppStrings.fullName),
          const SizedBox(height: 10),
          AppTextField(
            controller: _nameController,
            hint: AppStrings.nameHint,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
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
          Text(
            AppStrings.passwordHelper,
            style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: AppStrings.createAccount,
            isLoading: _isLoading,
            onPressed: _handleCreateAccount,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: AppPalette.textSecondary(context), fontSize: 14),
          children: [
            TextSpan(text: AppStrings.alreadyHaveAccount),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: _goToLogin,
                child: Text(
                  AppStrings.signInLink,
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}