// lib/features/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/analysis_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.offWhite,
          body: Column(
            children: [
              if (provider.offlineMode) const OfflineBanner(),
              _HomeHeader(provider: provider),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _PrimaryActionCard(provider: provider),
                    const SizedBox(height: 16),
                    if (provider.lastAnalysis != null)
                      _LastAnalysisCard(result: provider.lastAnalysis!),
                    const SizedBox(height: 16),
                    _QuickTipsCard(),
                  ],
                ),
              ),
              _BottomNavBar(currentIndex: 0),
            ],
          ),
        );
      },
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final DiagnosisProvider provider;
  const _HomeHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.deepGreen,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jai Kisan 🌾',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.amber,
                      ),
                ),
                if (provider.farmerName.isNotEmpty)
                  Text(
                    provider.farmerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
              ],
            ),
          ),
          // Connectivity indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: provider.offlineMode
                  ? AppColors.amber.withOpacity(0.2)
                  : AppColors.successGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: provider.offlineMode
                    ? AppColors.amber
                    : AppColors.successGreen,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  provider.offlineMode
                      ? Icons.cloud_off_rounded
                      : Icons.wifi_rounded,
                  size: 14,
                  color: provider.offlineMode
                      ? AppColors.amber
                      : AppColors.successGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  provider.offlineMode ? 'Offline' : 'Online',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: provider.offlineMode
                        ? AppColors.amber
                        : AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Primary Action Card ───────────────────────────────────────────────────────
class _PrimaryActionCard extends StatelessWidget {
  final DiagnosisProvider provider;
  const _PrimaryActionCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepGreen, Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x442D6A4F),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Meri Fasal Kyun Kharab Hui?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Apni baat batao, hum samjhayenge',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: VoiceButton(label: 'Bolkar Batao'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.resetDiagnosis();
                    context.go(AppRoutes.step1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.deepGreen,
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.touch_app_rounded, size: 18),
                  label: const Text('Tap Karo'),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms);
  }
}

// ── Last Analysis Card ────────────────────────────────────────────────────────
class _LastAnalysisCard extends StatelessWidget {
  final AnalysisResult result;
  const _LastAnalysisCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return KaCard(
      accentColor: AppColors.amber,
      onTap: () => context.go(AppRoutes.results),
      child: Row(
        children: [
          Text(causeEmoji(result.causeKey),
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pichla Vishleshan',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.midGrey,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  result.crop,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  result.seasonYear,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightAmber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.causeTitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.lightGrey),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

// ── Quick Tips Card ───────────────────────────────────────────────────────────
class _QuickTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      ('🌧️', 'Baarish kam hone par drip sinchai use karein'),
      ('🌱', 'Beej bone se pehle mitti ki jaanch karein'),
      ('📅', 'Sahi samay par fasal badlav karein'),
    ];

    return KaCard(
      backgroundColor: AppColors.lightGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kisan Tips 💡',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.deepGreen,
                ),
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.$1, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.$2,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 400.ms);
  }
}

// ── Bottom Nav Bar ────────────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const _BottomNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          elevation: 0,
          backgroundColor: Colors.transparent,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go(AppRoutes.home);
              case 1:
                context.read<DiagnosisProvider>().resetDiagnosis();
                context.go(AppRoutes.step1);
              case 2:
                context.go(AppRoutes.history);
              case 3:
                context.go(AppRoutes.settings);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.biotech_rounded),
              label: 'New Analysis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
