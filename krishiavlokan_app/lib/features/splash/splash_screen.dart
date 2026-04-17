// lib/features/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Initialise provider from storage
    final provider = context.read<DiagnosisProvider>();
    await provider.init();

    // Wait for splash to display
    await Future.delayed(const Duration(milliseconds: 2600));

    if (!mounted) return;

    // If language is already saved, go home; else language selection
    if (provider.selectedLanguage.isNotEmpty) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.deepGreen, Color(0xFF40916C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container
              Image.asset(
                'assets/KrishiAvloakan_skel.png',
                width: 350,
                height: 350,
                fit: BoxFit.contain,
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.6, 0.6), duration: 600.ms),

              const SizedBox(height: 34),

              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.cardWhite,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              Text(
                AppConstants.taglineHi,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms),

              Text(
                AppConstants.taglineEn,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white54,
                    ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 70),

              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.cardWhite,
                  strokeWidth: 2.5,
                ),
              ).animate(delay: 800.ms).fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              Text(
                AppConstants.krishiini,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
              )
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
