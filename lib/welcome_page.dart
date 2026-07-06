import 'package:flutter/material.dart';
import 'package:campus_twin/theme.dart';
import 'package:campus_twin/app_widget.dart';
import 'package:campus_twin/login.dart';
import 'package:campus_twin/register.dart';

/// The very first screen the user sees.
/// Shows the CampusTwin brand, a short pitch, and lets the user
/// go to Sign In or Create Account.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF163DDB), Color(0xFF2563EB), Color(0xFF22C1C3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative floating orbs for depth (same visual language
            // as the hero backdrop on Login / Register).
            Positioned(
              top: 60,
              right: -60,
              child: _Orb(size: 160, color: Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              top: 220,
              left: -40,
              child: _Orb(size: 100, color: Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: 260,
              right: 30,
              child: _Orb(
                size: 70,
                color: AppColors.purpleLight.withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              bottom: 140,
              left: 10,
              child: _Orb(size: 30, color: Colors.white.withValues(alpha: 0.16)),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 50),
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25), 
                                child: Image.asset(
                                  'assets/Campus_Twin.png', 
                                  height: 100, 
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                            const Text(
                              'Meet your\ndigital twin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'CampusTwin unifies your studies, habits, stress and '
                              'expenses into one AI-powered system — so it can guide '
                              'you, not just track you.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                AuthFeatureBadge(
                                  icon: Icons.auto_awesome_outlined,
                                  label: 'AI recommendations',
                                ),
                                AuthFeatureBadge(
                                  icon: Icons.insights_outlined,
                                  label: 'Stress prediction',
                                ),
                                AuthFeatureBadge(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Smart scheduling',
                                ),
                              ],
                            ),
                            const Spacer(),
                            _buildActions(context),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary: Sign In
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.purple,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Secondary: Create account
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}