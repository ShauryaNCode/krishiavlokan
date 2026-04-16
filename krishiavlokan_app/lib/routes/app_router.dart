// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/splash_screen.dart';
import '../features/language/language_screen.dart';
import '../features/home/home_screen.dart';
import '../features/diagnosis/steps/step1_crop_screen.dart';
import '../features/diagnosis/steps/step2_location_screen.dart';
import '../features/diagnosis/steps/step3_sowing_screen.dart';
import '../features/diagnosis/steps/step4_symptoms_screen.dart';
import '../features/diagnosis/loading_screen.dart';
import '../features/results/results_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  static const splash    = '/';
  static const language  = '/language';
  static const home      = '/home';
  static const step1     = '/diagnosis/crop';
  static const step2     = '/diagnosis/location';
  static const step3     = '/diagnosis/sowing';
  static const step4     = '/diagnosis/symptoms';
  static const loading   = '/diagnosis/loading';
  static const results   = '/results';
  static const history   = '/history';
  static const settings  = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (ctx, state) => _slide(state, const SplashScreen()),
    ),
    GoRoute(
      path: AppRoutes.language,
      pageBuilder: (ctx, state) => _slide(state, const LanguageScreen()),
    ),
    GoRoute(
      path: AppRoutes.home,
      pageBuilder: (ctx, state) => _slide(state, const HomeScreen()),
    ),
    GoRoute(
      path: AppRoutes.step1,
      pageBuilder: (ctx, state) => _slide(state, const Step1CropScreen()),
    ),
    GoRoute(
      path: AppRoutes.step2,
      pageBuilder: (ctx, state) => _slide(state, const Step2LocationScreen()),
    ),
    GoRoute(
      path: AppRoutes.step3,
      pageBuilder: (ctx, state) => _slide(state, const Step3SowingScreen()),
    ),
    GoRoute(
      path: AppRoutes.step4,
      pageBuilder: (ctx, state) => _slide(state, const Step4SymptomsScreen()),
    ),
    GoRoute(
      path: AppRoutes.loading,
      pageBuilder: (ctx, state) => _fade(state, const LoadingScreen()),
    ),
    GoRoute(
      path: AppRoutes.results,
      pageBuilder: (ctx, state) => _slide(state, const ResultsScreen()),
    ),
    GoRoute(
      path: AppRoutes.history,
      pageBuilder: (ctx, state) => _slide(state, const HistoryScreen()),
    ),
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (ctx, state) => _slide(state, const SettingsScreen()),
    ),
  ],
);

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, anim, __, c) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
        child: c,
      ),
    );

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, anim, __, c) =>
          FadeTransition(opacity: anim, child: c),
    );
