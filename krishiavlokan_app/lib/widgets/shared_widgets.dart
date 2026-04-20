// lib/widgets/shared_widgets.dart
//
// Reusable UI building blocks used across multiple screens.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../providers/diagnosis_provider.dart';
import '../routes/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// KA App Card — base card with optional left accent border
// ─────────────────────────────────────────────────────────────────────────────
class KaCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const KaCard({
    super.key,
    required this.child,
    this.accentColor,
    this.backgroundColor,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (accentColor != null)
                Container(width: 5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step Progress Bar
// ─────────────────────────────────────────────────────────────────────────────
class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightAmber,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${((currentStep / totalSteps) * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightAmber,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            minHeight: 8,
            backgroundColor: AppColors.lightGreen,
            valueColor: const AlwaysStoppedAnimation(AppColors.medGreen),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Voice Input Pill Button
// ─────────────────────────────────────────────────────────────────────────────
class VoiceButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const VoiceButton({
    super.key,
    this.onTap,
    this.label = 'Bolkar Batao',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice input coming soon!'),
                  duration: Duration(seconds: 1),
                ),
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33F4A22D),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Next/Confirm Button
// ─────────────────────────────────────────────────────────────────────────────
class KaNextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const KaNextButton({
    super.key,
    this.label = 'Aage Badho',
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(label),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Offline Banner
// ─────────────────────────────────────────────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.amber,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aap offline hain — Seemit Vishleshan Uplabdh',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    ).animate().slideY(
          begin: -1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOut,
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diagnosis Step Screen wrapper
// Back button routes correctly per step and stops voice activity.
// ─────────────────────────────────────────────────────────────────────────────
class DiagnosisStepScaffold extends StatelessWidget {
  final int step;
  final String title;
  final Widget body;
  final Widget bottomBar;
  final bool showOfflineBanner;

  const DiagnosisStepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.body,
    required this.bottomBar,
    this.showOfflineBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<DiagnosisProvider>().stopVoiceCompletely();
            switch (step) {
              case 2:  context.go(AppRoutes.step1);  break;
              case 3:  context.go(AppRoutes.step2);  break;
              case 4:  context.go(AppRoutes.step3);  break;
              default: context.go(AppRoutes.home);   break;
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StepProgressBar(currentStep: step, totalSteps: 4),
          ),
        ),
      ),
      body: Column(
        children: [
          if (showOfflineBanner) const OfflineBanner(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: bottomBar,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cause Emoji helper
// Handles both mock keys and live API causeKey values.
// ─────────────────────────────────────────────────────────────────────────────
String causeEmoji(String key) {
  final k = key.toLowerCase();
  if (k.contains('waterlog') || k.contains('flood')) return '💧';
  if (k.contains('drought')  || k.contains('dry'))   return '🏜️';
  if (k.contains('pest')     || k.contains('insect')) return '🐛';
  if (k.contains('fungal')   || k.contains('blight')) return '🍂';
  if (k.contains('heat')     || k.contains('temp'))   return '🌡️';
  if (k.contains('nutrient') || k.contains('defic'))  return '🟡';
  return '🌿';
}

// ─────────────────────────────────────────────────────────────────────────────
// Weather phase helpers
// ─────────────────────────────────────────────────────────────────────────────
Color weatherStatusColor(String status) {
  final s = status.toLowerCase();
  if (s == 'verylow'  || s == 'veryhigh')   return AppColors.dangerRed;
  if (s == 'low'      || s == 'high')       return AppColors.amber;
  if (s.contains('severe'))                  return AppColors.dangerRed;
  if (s.contains('moderate'))               return AppColors.amber;
  if (s.contains('mild'))                   return AppColors.amber;
  return AppColors.successGreen;
}

String weatherStatusLabel(String status) {
  final s = status.toLowerCase();
  if (s == 'verylow')  return 'Very Low';
  if (s == 'low')      return 'Low';
  if (s == 'high')     return 'High';
  if (s == 'veryhigh') return 'Very High';
  if (s.contains('severe'))   return 'Severe';
  if (s.contains('moderate')) return 'Moderate';
  if (s.contains('mild'))     return 'Mild';
  return 'Normal';
}