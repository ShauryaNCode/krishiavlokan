// lib/features/diagnosis/steps/step4_symptoms_screen.dart
//
// Continuous voice-driven symptom selection.
//
// Interaction model:
//   Tap once  → open mic, stay open, process each chunk as it arrives
//   Tap again → stop manually
//   Silence   → auto-stop after 5 s (handled by DiagnosisProvider)
//
// Symptoms are ADDED incrementally — never replaced.
// Manual card taps always work alongside voice.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../voice/voice_controller.dart';
import '../../../providers/diagnosis_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/shared_widgets.dart';

class Step4SymptomsScreen extends StatefulWidget {
  const Step4SymptomsScreen({super.key});

  @override
  State<Step4SymptomsScreen> createState() => _Step4SymptomsScreenState();
}

class _Step4SymptomsScreenState extends State<Step4SymptomsScreen> {
  // Tracks the last N unique newly-added keys so we can flash them once.
  // Only used for the subtle highlight animation; cleared after render.
  final Set<String> _recentlyAdded = {};
  late final VoiceController _voiceController;

  @override
  void initState() {
    super.initState();
    _voiceController = VoiceController(
      provider: context.read<DiagnosisProvider>(),
    );
  }

  @override
  void dispose() {
    _voiceController.dispose();
    context.read<DiagnosisProvider>().stopVoiceCompletely();
    super.dispose();
  }

  // ── Toggle handler ─────────────────────────────────────────────────────────

  Future<void> _handleVoiceTap(DiagnosisProvider provider) async {
    if (provider.isContinuousListening) {
      await _voiceController.stop(manual: true);
      if (mounted) _showSummarySnackbar(provider);
    } else {
      await _voiceController.start();
    }
  }

  // ── Snackbar — shown once on manual stop only ──────────────────────────────

  void _showSummarySnackbar(DiagnosisProvider provider) {
    final detected = provider.voiceDetectedSymptoms;
    if (detected.isEmpty) {
      _snack(
        'No symptoms detected. Please try again or select manually.',
        isError: true,
      );
    } else {
      final labels = detected
          .map((k) => _labelFor(k))
          .join(', ');
      _snack('Detected: $labels');
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14))),
          ],
        ),
        backgroundColor:
            isError ? AppColors.terracotta : AppColors.successGreen,
        duration: Duration(seconds: isError ? 3 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static String _labelFor(String key) => switch (key) {
        'drought'      => 'Drought Stress',
        'waterlogging' => 'Waterlogging',
        'nutrient'     => 'Nutrient Deficiency',
        'pest'         => 'Pest Damage',
        'fungal'       => 'Fungal Disease',
        'heat'         => 'Heat Stress',
        _              => key,
      };

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        final isListening = provider.isContinuousListening;
        final canProceed  = provider.selectedSymptoms.isNotEmpty && !isListening;

        return DiagnosisStepScaffold(
          step:              4,
          title:             'What did you observe?',
          showOfflineBanner: provider.offlineMode,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Text(
                'What did you see in your crop?',
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Select manually, or describe in your own words.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // ── Symptom cards ────────────────────────────────────────────
              ...AppSymptoms.symptoms.asMap().entries.map((e) {
                final i          = e.key;
                final symptom    = e.value;
                final key        = symptom['key']!;
                final isSelected = provider.isSymptomSelected(key);
                // Was this key added by voice in the current session?
                final isVoiceAdded =
                    provider.voiceDetectedSymptoms.contains(key);

                return _SymptomCard(
                  symptom:      symptom,
                  isSelected:   isSelected,
                  isVoiceAdded: isVoiceAdded && isListening,
                  onTap: () {
                    // Manual tap always works — stop voice if needed
                    if (isListening) _voiceController.stop(manual: true);
                    provider.toggleSymptom(key);
                  },
                  index: i,
                );
              }),

              const SizedBox(height: 80),
            ],
          ),
          bottomBar: KaNextButton(
            label:     'Analyse Now ✓',
            isEnabled: canProceed,
            onPressed: () {
              _voiceController.dispose();
              provider.stopVoiceCompletely();
              ctx.go(AppRoutes.loading);
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Continuous voice toggle button
// ─────────────────────────────────────────────────────────────────────────────
class _ContinuousVoiceButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  const _ContinuousVoiceButton({
    required this.isListening,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg    = isListening ? AppColors.dangerRed : AppColors.amber;
    final label = isListening ? 'Tap to Stop' : 'Describe Your Crop Problem';
    final icon  = isListening ? Icons.stop_circle_rounded : Icons.mic_rounded;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color:      bg.withOpacity(0.35),
              blurRadius: 14,
              offset:     const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isListening
                ? _PulsingMic()
                : Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color:      Colors.white,
                fontWeight: FontWeight.bold,
                fontSize:   15,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

// Pulsing mic animation
class _PulsingMic extends StatefulWidget {
  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.82, end: 1.18)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: const Icon(Icons.stop_circle_rounded,
            color: Colors.white, size: 22),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Listening status bar — shown while mic is open
// ─────────────────────────────────────────────────────────────────────────────
class _ListeningStatusBar extends StatelessWidget {
  const _ListeningStatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        AppColors.dangerRed.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.dangerRed.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded,
              size: 15, color: AppColors.dangerRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Listening… speak naturally. '
              'Auto-stops after silence.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:     AppColors.dangerRed,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint row
// ─────────────────────────────────────────────────────────────────────────────
class _HintRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.tips_and_updates_rounded,
            size: 14, color: AppColors.amber),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Say things like: "leaves are yellow and have black spots", '
            '"white powder on stems", "insects eating leaves", '
            '"plant drying up", or describe in any mix of English and Hindi.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symptom card — adds subtle green pulse when voice-detected live
// ─────────────────────────────────────────────────────────────────────────────
class _SymptomCard extends StatelessWidget {
  final Map<String, String> symptom;
  final bool isSelected;
  final bool isVoiceAdded;  // true while mic is on and this was just detected
  final VoidCallback onTap;
  final int index;

  const _SymptomCard({
    required this.symptom,
    required this.isSelected,
    required this.isVoiceAdded,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    // Voice-added cards get an extra green glow ring while listening
    final borderColor = isVoiceAdded
        ? AppColors.successGreen
        : isSelected
            ? AppColors.deepGreen
            : AppColors.lightGrey;
    final borderWidth = (isSelected || isVoiceAdded) ? 2.0 : 1.0;
    final bgColor     = isSelected ? AppColors.lightGreen : AppColors.cardWhite;

    Widget card = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:        bgColor,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            if (isVoiceAdded)
              BoxShadow(
                color:      AppColors.successGreen.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 1,
              )
            else
              const BoxShadow(
                color:      AppColors.shadowColor,
                blurRadius: 6,
                offset:     Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            if (isSelected)
              Container(
                width:  4,
                height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color:        AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Text(
              symptom['emoji']!,
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          symptom['title']!,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color:    isSelected
                                    ? AppColors.deepGreen
                                    : AppColors.darkText,
                                fontSize: 14,
                              ),
                        ),
                      ),
                      // "Voice detected" micro-badge
                      if (isVoiceAdded)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mic_rounded,
                                  size: 10,
                                  color: AppColors.successGreen),
                              const SizedBox(width: 3),
                              Text(
                                'voice',
                                style: TextStyle(
                                  fontSize: 9,
                                  color:    AppColors.successGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    symptom['desc']!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:  24,
              height: 24,
              decoration: BoxDecoration(
                color:  isSelected ? AppColors.deepGreen : Colors.transparent,
                shape:  BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.deepGreen
                      : AppColors.lightGrey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );

    // Pulse-in animation when voice-added during active session
    if (isVoiceAdded) {
      card = card
          .animate()
          .shimmer(
            duration: 600.ms,
            color:    AppColors.successGreen.withOpacity(0.2),
          );
    }

    return card
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.06, end: 0);
  }
}
