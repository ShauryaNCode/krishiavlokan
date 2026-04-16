// lib/main.dart
//
// KrishiAvalokan — AI-powered crop failure analyzer
// Entry point: initialises providers and launches the app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/diagnosis_provider.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for mobile-first experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KrishiAvalokanApp());
}

class KrishiAvalokanApp extends StatelessWidget {
  const KrishiAvalokanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Single shared provider that drives the entire app
        ChangeNotifierProvider(create: (_) => DiagnosisProvider()),
      ],
      child: Builder(
        builder: (ctx) {
          // Read text scale from provider for dynamic scaling
          final textScale =
              ctx.select<DiagnosisProvider, double>((p) => p.textScale);

          return MediaQuery(
            // Apply user-selected text scale from settings
            data: MediaQuery.of(ctx).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: MaterialApp.router(
              title: 'KrishiAvalokan',
              theme: AppTheme.light,
              routerConfig: appRouter,
              debugShowCheckedModeBanner: false,

              // Accessibility: ensure enough contrast everywhere
              builder: (ctx, child) => GestureDetector(
                // Dismiss keyboard on tap outside input fields
                onTap: () => FocusScope.of(ctx).unfocus(),
                child: child!,
              ),
            ),
          );
        },
      ),
    );
  }
}
