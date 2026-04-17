// lib/features/diagnosis/steps/step1_crop_screen.dart
//
// VOICE-WIRED sample screen. Apply the same pattern to Steps 2-4:
//   1. Convert to StatefulWidget
//   2. initState  → provider.startQuestionLoop(_kQuestion)
//   3. dispose    → provider.stopVoiceCompletely()
//   4. VoiceButton onTap → provider.listenForAnswer(...)
//   5. Manual tap/nav  → provider.stopVoiceCompletely() first

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/diagnosis_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/shared_widgets.dart';

// Question spoken on loop when screen opens.
const _kQuestion =
    'Which crop did you grow? '
    'Say wheat, rice, cotton, maize, soybean, pigeon pea, millet, or sugarcane.';

class Step1CropScreen extends StatefulWidget {
  const Step1CropScreen({super.key});

  @override
  State<Step1CropScreen> createState() => _Step1CropScreenState();
}

class _Step1CropScreenState extends State<Step1CropScreen> {
  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // One frame delay ensures BuildContext is valid for provider access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DiagnosisProvider>().startQuestionLoop(_kQuestion);
      }
    });
  }

  @override
  void dispose() {
    // Guaranteed stop regardless of how the user leaves this screen
    context.read<DiagnosisProvider>().stopVoiceCompletely();
    super.dispose();
  }

  // ── Crop matcher ───────────────────────────────────────────────────────────
  //
  // Maps lowercased recognised speech to the crop 'name' key in AppCrops.
  // Add more spoken variants here without touching anything else.

  String? _matchCrop(String spoken) {
    const aliases = <String, String>{
      'wheat'       : 'Gehu',
      'weed'        : 'Gehu',   // common STT mishear for "wheat"
      'gehu'        : 'Gehu',

      'rice'        : 'Dhan',
      'paddy'       : 'Dhan',
      'dhan'        : 'Dhan',

      'cotton'      : 'Kapas',
      'kapas'       : 'Kapas',

      'maize'       : 'Makka',
      'corn'        : 'Makka',
      'makka'       : 'Makka',

      'soybean'     : 'Soybean',
      'soya'        : 'Soybean',
      'soy'         : 'Soybean',
      'soyabean'    : 'Soybean',

      'pigeon pea'  : 'Tur',
      'pigeonpea'   : 'Tur',
      'tur'         : 'Tur',
      'toor'        : 'Tur',
      'arhar'       : 'Tur',

      'millet'      : 'Bajra',
      'bajra'       : 'Bajra',
      'pearl millet': 'Bajra',

      'sugarcane'   : 'Ganna',
      'sugar cane'  : 'Ganna',
      'ganna'       : 'Ganna',
    };

    for (final entry in aliases.entries) {
      if (spoken.contains(entry.key)) return entry.value;
    }
    return null;
  }

  // ── Voice button handler ───────────────────────────────────────────────────

  void _onVoiceTapped(BuildContext ctx, DiagnosisProvider provider) {
    if (provider.isVoiceProcessing) return; // already listening, ignore tap

    provider.listenForAnswer(
      question: _kQuestion,
      matcher:  _matchCrop,
      onMatch: (cropName) {
        provider.setCrop(cropName);
        // Short pause so selection highlight is visible before nav
        Future.delayed(const Duration(milliseconds: 380), () {
          if (ctx.mounted) ctx.go(AppRoutes.step2);
        });
      },
      onNoMatch: () {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text("Sorry, didn't catch that. Please try again."),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.terracotta,
            ),
          );
        }
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        return Stack(
          children: [
            // ── Main screen ────────────────────────────────────────────────
            DiagnosisStepScaffold(
              step:              1,
              title:             'Select Crop',
              showOfflineBanner: provider.offlineMode,
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Which crop did you grow?',
                    style: Theme.of(ctx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap a crop below or use your voice.',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),

                  // ── Voice button (enhanced state-aware) ──────────────────
                  _VoiceButtonEnhanced(
                    isProcessing: provider.isVoiceProcessing,
                    isActive:     provider.isVoiceActive,
                    onTap:        () => _onVoiceTapped(ctx, provider),
                  ),

                  const SizedBox(height: 20),

                  // ── Crop grid ────────────────────────────────────────────
                  GridView.builder(
                    shrinkWrap: true,
                    physics:    const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:   2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing:  12,
                    ),
                    itemCount: AppCrops.crops.length,
                    itemBuilder: (ctx, i) {
                      final crop       = AppCrops.crops[i];
                      final isSelected =
                          provider.selectedCrop == crop['name'];
                      return _CropCard(
                        crop:       crop,
                        isSelected: isSelected,
                        onTap: () {
                          // Manual tap → stop all voice then select
                          provider.stopVoiceCompletely();
                          provider.setCrop(crop['name']!);
                        },
                        index: i,
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
              bottomBar: KaNextButton(
                label:     'Next →',
                isEnabled: provider.selectedCrop != null &&
                    !provider.isVoiceProcessing,
                onPressed: () {
                  provider.stopVoiceCompletely();
                  ctx.go(AppRoutes.step2);
                },
              ),
            ),

            // ── Processing overlay ─────────────────────────────────────────
            // Shown only while STT is active. AbsorbPointer blocks all taps.
            if (provider.isVoiceProcessing) const _ProcessingOverlay(),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enhanced VoiceButton — three visual states
// ─────────────────────────────────────────────────────────────────────────────
class _VoiceButtonEnhanced extends StatelessWidget {
  final bool isProcessing;
  final bool isActive;
  final VoidCallback onTap;

  const _VoiceButtonEnhanced({
    required this.isProcessing,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String   label;
    final Color    bgColor;
    final IconData icon;

    if (isProcessing) {
      label   = 'Processing...';
      bgColor = AppColors.lightGrey;
      icon    = Icons.hourglass_top_rounded;
    } else if (isActive) {
      label   = 'Listening...';
      bgColor = AppColors.successGreen;
      icon    = Icons.hearing_rounded;
    } else {
      label   = 'Tap to Speak';
      bgColor = AppColors.amber;
      icon    = Icons.mic_rounded;
    }

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color:        bgColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isProcessing
              ? []
              : [
                  BoxShadow(
                    color:      bgColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset:     const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isActive && !isProcessing
                ? _PulsingIcon(icon: icon)
                : Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
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

// Pulsing icon — visible only in listening state
class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  const _PulsingIcon({required this.icon});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child:   Icon(widget.icon, color: Colors.white, size: 20),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Processing overlay — dims screen and blocks input during STT
// ─────────────────────────────────────────────────────────────────────────────
class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width:  52,
                height: 52,
                child:  CircularProgressIndicator(
                  color:       AppColors.amber,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'Processing your answer...',
                style: TextStyle(
                  color:      Colors.white,
                  fontSize:   16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Crop card — identical to original, onTap now calls stopVoiceCompletely first
// ─────────────────────────────────────────────────────────────────────────────
class _CropCard extends StatelessWidget {
  final Map<String, String> crop;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _CropCard({
    required this.crop,
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
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.lightGreen : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.deepGreen : AppColors.lightGrey,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color:      AppColors.shadowColor,
              blurRadius: 6,
              offset:     Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    crop['emoji']!,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    crop['label']!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.deepGreen
                              : AppColors.darkText,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top:   8,
                right: 8,
                child: Container(
                  width:  22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.deepGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      )
          .animate(delay: (index * 50).ms)
          .fadeIn(duration: 300.ms)
          .scale(
            begin:    const Offset(0.85, 0.85),
            duration: 300.ms,
            curve:    Curves.easeOut,
          ),
    );
  }
}
