// lib/features/diagnosis/loading_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  int _messageIndex = 0;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  final List<String> _messages = [
    'Aapke khet ka mausam dekh rahe hain...',
    'Data ka vishleshan ho raha hai...',
    'Aapke liye jawab taiyar ho raha hai...',
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _startDiagnosis();
    _cycleMessages();
  }

  void _cycleMessages() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _messageIndex = 1);
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _messageIndex = 2);
    });
  }

  Future<void> _startDiagnosis() async {
    final provider = context.read<DiagnosisProvider>();
    await provider.runDiagnosis();
    if (!mounted) return;

    if (provider.status == DiagnosisStatus.success) {
      context.go(AppRoutes.results);
    } else {
      // Show error and go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Analysis failed'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkBg, AppColors.deepGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated farm illustration
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 160 + (_pulseController.value * 20),
                      height: 160 + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white
                            .withOpacity(0.05 * (1 - _pulseController.value)),
                      ),
                    ),
                  ),
                  // Inner container
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🌾', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 4),
                        // Rotating magnifier
                        AnimatedBuilder(
                          animation: _rotateController,
                          builder: (_, child) => Transform.rotate(
                            angle: _rotateController.value * 2 * 3.14159,
                            child: child,
                          ),
                          child: const Text('🔍',
                              style: TextStyle(fontSize: 22)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'KrishiAvalokan',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.amber,
                    ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // Cycling status message
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _messages[_messageIndex],
                  key: ValueKey(_messageIndex),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),

              const SizedBox(height: 32),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.amber),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Yeh 5 second mein ho jayega',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
              ),

              const SizedBox(height: 40),

              // Step indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepDot(label: '📍', done: true),
                  _StepLine(),
                  _StepDot(label: '🌦️', done: _messageIndex >= 1),
                  _StepLine(),
                  _StepDot(label: '🤖', done: _messageIndex >= 2),
                  _StepLine(),
                  _StepDot(label: '✨', done: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  const _StepDot({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: done
            ? AppColors.amber.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? AppColors.amber : Colors.white24,
        ),
      ),
      child: Center(
          child: Text(label, style: const TextStyle(fontSize: 16))),
    );
  }
}

class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 1,
        color: Colors.white24,
      );
}
