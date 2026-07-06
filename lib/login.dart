import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/register.dart';
import 'package:campus_twin/app_widget.dart';
import 'package:campus_twin/twinDashboard.dart';
import 'package:campus_twin/welcome_page.dart';

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
        const SnackBar(content: Text('Please fill in all fields')),
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

  void _handleGoogleSignIn() {
    // TODO: Hook up Google sign-in.
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
    return Scaffold(
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
                                  child: const Text(
                                    'CampusTwin',
                                    style: TextStyle(
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
                            const Center(
                              child: Text(
                                'Welcome back',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Center(
                              child: Text(
                                'Sign in to continue your CampusTwin experience.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  AuthFeatureBadge(
                                    icon: Icons.security_outlined,
                                    label: 'Secure sign in',
                                  ),
                                  AuthFeatureBadge(
                                    icon: Icons.auto_awesome_outlined,
                                    label: 'Personalized setup',
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
                    child: _buildLoginCard(),
                  ),
                ),
                const SizedBox(height: 8),
                _buildRegisterPrompt(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
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
          const Text(
            'Welcome back',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to continue where your student profile left off.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14.5),
          ),
          const SizedBox(height: 22),
          const AppFieldLabel('University Email'),
          const SizedBox(height: 10),
          AppTextField(
            controller: _emailController,
            hint: 'you@university.edu',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          const AppFieldLabel('Password'),
          const SizedBox(height: 10),
          AppTextField(
            controller: _passwordController,
            hint: 'Min. 6 characters',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
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
              child: const Text('Forgot password?'),
            ),
          ),
          const SizedBox(height: 22),
          AppPrimaryButton(
            label: 'Sign In',
            isLoading: _isLoading,
            onPressed: _handleSignIn,
          ),
          const SizedBox(height: 18),
          _buildDivider(),
          const SizedBox(height: 18),
          AppGoogleButton(onPressed: _handleGoogleSignIn),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }

  Widget _buildRegisterPrompt() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          GestureDetector(
            onTap: _goToRegister,
            child: const Text(
              'Register',
              style: TextStyle(
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