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
import 'package:flutter_svg/flutter_svg.dart';

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
      color: AppColors.offWhite,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
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
                        color: AppColors.deepGreen,
                      ),
                ),
                if (provider.farmerName.isNotEmpty)
                  Text(
                    provider.farmerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkBg,
                        ),
                  ),
              ],
            ),
          ),
          // Connectivity indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  size: 18,
                  color: provider.offlineMode
                      ? AppColors.amber
                      : AppColors.successGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  provider.offlineMode ? 'Offline' : 'Online',
                  style: TextStyle(
                    fontSize: 16,
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
    const String svgRawString = '''
    <svg width="298" height="84" viewBox="0 0 298 84" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect width="84" height="84" rx="16" fill="#FDAA35" fill-opacity="0.2"/>
      
      <g transform="translate(15, 15) scale(1.85) translate(-18, -17)">
        <path d="M29.7412 36.5H32.7412L32.9662 34.625C33.1662 34.55 33.3474 34.4625 33.5099 34.3625C33.6724 34.2625 33.8162 34.15 33.9412 34.025L35.6662 34.775L37.1662 32.225L35.6662 31.1C35.7162 30.9 35.7412 30.7 35.7412 30.5C35.7412 30.3 35.7162 30.1 35.6662 29.9L37.1662 28.775L35.6662 26.225L33.9412 26.975C33.8162 26.85 33.6724 26.7375 33.5099 26.6375C33.3474 26.5375 33.1662 26.45 32.9662 26.375L32.7412 24.5H29.7412L29.5162 26.375C29.3162 26.45 29.1349 26.5375 28.9724 26.6375C28.8099 26.7375 28.6662 26.85 28.5412 26.975L26.8162 26.225L25.3162 28.775L26.8162 29.9C26.7662 30.1 26.7412 30.3 26.7412 30.5C26.7412 30.7 26.7662 30.9 26.8162 31.1L25.3162 32.225L26.8162 34.775L28.5412 34.025C28.6662 34.15 28.8099 34.2625 28.9724 34.3625C29.1349 34.4625 29.3162 34.55 29.5162 34.625L29.7412 36.5V36.5M31.2412 32.75C30.6162 32.75 30.0849 32.5312 29.6474 32.0938C29.2099 31.6562 28.9912 31.125 28.9912 30.5C28.9912 29.875 29.2099 29.3438 29.6474 28.9062C30.0849 28.4688 30.6162 28.25 31.2412 28.25C31.8662 28.25 32.3974 28.4688 32.8349 28.9062C33.2724 29.3438 33.4912 29.875 33.4912 30.5C33.4912 31.125 33.2724 31.6562 32.8349 32.0938C32.3974 32.5312 31.8662 32.75 31.2412 32.75V32.75M22.2412 47V40.55C20.8162 39.25 19.7099 37.7312 18.9224 35.9937C18.1349 34.2562 17.7412 32.425 17.7412 30.5C17.7412 26.75 19.0537 23.5625 21.6787 20.9375C24.3037 18.3125 27.4912 17 31.2412 17C34.3662 17 37.1349 17.9187 39.5474 19.7562C41.9599 21.5937 43.5287 23.9875 44.2537 26.9375L46.2037 34.625C46.3287 35.1 46.2412 35.5313 45.9412 35.9188C45.6412 36.3063 45.2412 36.5 44.7412 36.5H41.7412V41C41.7412 41.825 41.4474 42.5312 40.8599 43.1187C40.2724 43.7062 39.5662 44 38.7412 44H35.7412V47H22.2412V47" fill="#FDAA35"/>
      </g>
    </svg>
    ''';
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
          const SizedBox(height: 12),
          Positioned.fill(
            child: SvgPicture.string(
              svgRawString,
              fit: BoxFit.fitWidth, // Ensures it covers the entire area
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Meri Fasal Kyun Kharab Hui?',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Apni baat batao, hum samjhayenge',
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontSize: 23,
                ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              // 1. First Button
              SizedBox(
                width: double.infinity, // Ensures the button takes full width
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.resetDiagnosis();
                    context.go(AppRoutes.step1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(
                        0, 54), // Increased height for better vertical look
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.mic_none_outlined, size: 20),
                  label: const Text('Bolkar Batao'),
                ),
              ),

              const SizedBox(height: 12), // Vertical spacing

              // 2. Second Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.resetDiagnosis();
                    context.go(AppRoutes.step1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.deepGreen,
                    minimumSize: const Size(0, 54),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.touch_app_rounded, size: 20),
                  label: const Text('Tap / Type Karo'),
                ),
              ),
            ],
          )
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
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
