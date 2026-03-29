import 'package:flutter/material.dart';
import 'package:wholeseller/theme/app_theme.dart';
import 'package:wholeseller/widgets/primary_button.dart';
import 'package:wholeseller/widgets/secondary_button.dart';
import 'package:wholeseller/widgets/trust_indicator.dart';
import 'package:wholeseller/screens/login_screen.dart';
import 'package:wholeseller/screens/register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Illustration Placeholder
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.storefront,
                  size: 120,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 48),
              // Headline
              const Text(
                'Buy Wholesale. Sell Better.',
                style: AppTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                'Direct bulk purchasing from verified wholesalers',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Primary CTA
              PrimaryButton(
                text: 'Get Started',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Secondary CTA
              SecondaryButton(
                text: 'Login',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              // Trust Indicators
              Wrap(
                spacing: 24,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: const [
                  TrustIndicator(
                    icon: Icons.verified,
                    text: 'GST Verified',
                  ),
                  TrustIndicator(
                    icon: Icons.lock,
                    text: 'Secure Payments',
                  ),
                  TrustIndicator(
                    icon: Icons.shield,
                    text: 'Trusted Wholesalers',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
