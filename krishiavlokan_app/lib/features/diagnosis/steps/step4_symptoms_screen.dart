// lib/features/diagnosis/steps/step4_symptoms_screen.dart
//
// Voice-driven symptom selection.
// Uses a toggle-style voice interaction:
//   First tap  → start listening (mic active, live transcript shown)
//   Second tap → stop listening → run SymptomVoiceProcessor → apply results
//
// Architecture:
//   VoiceService        → raw audio → transcript (existing)
//   SymptomVoiceProcessor → transcript → List<String> symptom keys (new)
//   DiagnosisProvider   → applyVoiceSymptoms() (new method)
//   UI                  → shows state, result, manual fallback

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/diagnosis_provider.dart';
import '../../../routes/app_router.dart';
import '../../../services/voice_service.dart';
import '../../../services/symptom_voice_processor.dart';
import '../../../widgets/shared_widgets.dart';

class Step4SymptomsScreen extends StatefulWidget {
  const Step4SymptomsScreen({super.key});

  @override
  State<Step4SymptomsScreen> createState() => _Step4SymptomsScreenState();
}

class _Step4SymptomsScreenState extends State<Step4SymptomsScreen> {
  // ── Voice state local to this screen ──────────────────────────────────────
  bool   _isListening   = false;   // mic is open
  bool   _isProcessing  = false;   // running processor after STT stops
  String _liveTranscript = '';     // shown in real-time while mic is open

  final _processor = SymptomVoiceProcessor();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    VoiceService.instance.stopAll();
    super.dispose();
  }

  // ── Voice toggle handler ───────────────────────────────────────────────────
  //
  // Tap 1 → open mic, start listening
  // Tap 2 → close mic, process transcript, apply symptoms

  Future<void> _handleVoiceTap(DiagnosisProvider provider) async {
    if (_isProcessing) return; // guard during processing window

    if (!_isListening) {
      // ── START LISTENING ──────────────────────────────────────────────────
      await VoiceService.instance.stopAll(); // ensure clean state
      setState(() {
        _isListening    = true;
        _liveTranscript = '';
      });

      // Open mic with a 15s max window — user taps again to stop early
      // We fire-and-forget; the real stop happens via the second tap.
      _startListeningLoop();
    } else {
      // ── STOP LISTENING AND PROCESS ───────────────────────────────────────
      await VoiceService.instance.stopListening();
      final transcript = _liveTranscript.trim();

      setState(() {
        _isListening  = false;
        _isProcessing = true;
      });

      // Small yield so the UI can repaint to "Processing" state
      await Future.delayed(const Duration(milliseconds: 80));

      _processTranscript(transcript, provider);
    }
  }

  /// Opens the STT engine and continuously appends partial results to
  /// _liveTranscript so the user sees words appear as they speak.
  Future<void> _startListeningLoop() async {
    await VoiceService.instance.init();

    // We re-use the underlying STT directly here for live transcript display.
    // VoiceService.listenOnce is for single-shot; here we need streaming.
    // Implemented as a long-duration listen with partial-result callbacks
    // via the speech_to_text package used inside VoiceService.
    //
    // Since VoiceService wraps the package, we call listenOnce with a long
    // timeout and capture whatever arrives. The user's second tap calls
    // stopListening() which triggers finalResult early.

    final result = await VoiceService.instance.listenOnce(
      timeout: const Duration(seconds: 15),
    );

    // If STT resolved naturally (timeout / user stopped externally):
    if (mounted && _isListening) {
      setState(() {
        _liveTranscript = result ?? '';
        _isListening    = false;
        _isProcessing   = true;
      });
      await Future.delayed(const Duration(milliseconds: 80));
      _processTranscript(_liveTranscript, context.read<DiagnosisProvider>());
    }
  }

  /// Runs the NLP processor, applies results, shows feedback.
  void _processTranscript(String transcript, DiagnosisProvider provider) {
    if (transcript.isEmpty) {
      setState(() => _isProcessing = false);
      _showSnackbar(
        context,
        "Nothing heard. Please try again or select manually.",
        isError: true,
      );
      return;
    }

    final detected = _processor.detectSymptoms(transcript);

    setState(() => _isProcessing = false);

    if (detected.isEmpty) {
      _showSnackbar(
        context,
        "Could not clearly detect symptoms. Try again or select manually.",
        isError: true,
      );
      return;
    }

    // Apply to provider via the new applyVoiceSymptoms method
    provider.applyVoiceSymptoms(detected);

    // Build a readable label list for feedback
    final labels = detected
        .map(SymptomVoiceProcessor.labelFor)
        .join(', ');

    _showSnackbar(
      context,
      "Detected: $labels",
      isError: false,
    );
  }

  void _showSnackbar(BuildContext ctx, String message, {required bool isError}) {
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(
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
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor:
            isError ? AppColors.terracotta : AppColors.successGreen,
        duration: Duration(seconds: isError ? 3 : 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        final canProceed = provider.selectedSymptoms.isNotEmpty;

        return Stack(
          children: [
            DiagnosisStepScaffold(
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
                    'Select one or more, or describe in your own words.',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // ── Smart voice button ────────────────────────────────────
                  _SmartVoiceButton(
                    isListening:  _isListening,
                    isProcessing: _isProcessing,
                    onTap: () => _handleVoiceTap(provider),
                  ),

                  // ── Live transcript bubble ────────────────────────────────
                  if (_isListening || _liveTranscript.isNotEmpty)
                    _TranscriptBubble(
                      text:        _liveTranscript,
                      isListening: _isListening,
                    ),

                  const SizedBox(height: 20),

                  // ── Hint text ─────────────────────────────────────────────
                  if (!_isListening && !_isProcessing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.tips_and_updates_rounded,
                              size: 14, color: AppColors.amber),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'You can say things like: '
                              '"leaves are yellow", "white powder on stems", '
                              '"insects eating leaves", or speak naturally.',
                              style: Theme.of(ctx).textTheme.bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Symptom cards ─────────────────────────────────────────
                  ...AppSymptoms.symptoms.asMap().entries.map((entry) {
                    final i          = entry.key;
                    final symptom    = entry.value;
                    final isSelected =
                        provider.isSymptomSelected(symptom['key']!);
                    return _SymptomCard(
                      symptom:    symptom,
                      isSelected: isSelected,
                      onTap: () {
                        provider.stopVoiceCompletely();
                        provider.toggleSymptom(symptom['key']!);
                      },
                      index: i,
                    );
                  }),

                  const SizedBox(height: 80),
                ],
              ),
              bottomBar: KaNextButton(
                label:     'Analyse Now ✓',
                isEnabled: canProceed && !_isListening && !_isProcessing,
                onPressed: () {
                  provider.stopVoiceCompletely();
                  ctx.go(AppRoutes.loading);
                },
              ),
            ),

            // ── Processing overlay ────────────────────────────────────────
            if (_isProcessing)
              AbsorbPointer(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 52, height: 52,
                          child: CircularProgressIndicator(
                            color: AppColors.amber, strokeWidth: 3),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Understanding your answer...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart Voice Button — three states: idle | listening | processing
// ─────────────────────────────────────────────────────────────────────────────
class _SmartVoiceButton extends StatelessWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onTap;

  const _SmartVoiceButton({
    required this.isListening,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String   label;
    final Color    bg;
    final IconData icon;

    if (isProcessing) {
      label = 'Understanding...';
      bg    = AppColors.lightGrey;
      icon  = Icons.hourglass_top_rounded;
    } else if (isListening) {
      label = 'Tap to Stop & Analyse';
      bg    = AppColors.dangerRed;
      icon  = Icons.stop_rounded;
    } else {
      label = 'Describe Your Crop Problem';
      bg    = AppColors.amber;
      icon  = Icons.mic_rounded;
    }

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isProcessing
              ? []
              : [
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
                ? _PulsingIcon(icon: icon)
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
    ).animate().fadeIn(duration: 300.ms);
  }
}

// Pulsing mic animation during listening state
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  const _PulsingIcon({required this.icon});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: Icon(widget.icon, color: Colors.white, size: 22),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Live transcript bubble — shows what was heard in real time
// ─────────────────────────────────────────────────────────────────────────────
class _TranscriptBubble extends StatelessWidget {
  final String text;
  final bool   isListening;

  const _TranscriptBubble({required this.text, required this.isListening});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        isListening
            ? AppColors.dangerRed.withOpacity(0.07)
            : AppColors.lightGreen,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isListening ? AppColors.dangerRed.withOpacity(0.3)
                             : AppColors.successGreen.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isListening ? Icons.mic_rounded : Icons.record_voice_over_rounded,
            size:  16,
            color: isListening ? AppColors.dangerRed : AppColors.deepGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.isEmpty && isListening
                  ? 'Listening... speak now'
                  : text.isEmpty
                      ? 'Nothing heard'
                      : '"$text"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color:     isListening
                        ? AppColors.dangerRed
                        : AppColors.deepGreen,
                  ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Symptom card — identical to original, manual tap stops voice first
// ─────────────────────────────────────────────────────────────────────────────
class _SymptomCard extends StatelessWidget {
  final Map<String, String> symptom;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _SymptomCard({
    required this.symptom,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:  const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightGreen : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.deepGreen : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
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
                  Text(
                    symptom['title']!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color:    isSelected
                              ? AppColors.deepGreen
                              : AppColors.darkText,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    symptom['desc']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
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
                  color: isSelected ? AppColors.deepGreen : AppColors.lightGrey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      )
          .animate(delay: (index * 60).ms)
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.08, end: 0),
    );
  }
}
