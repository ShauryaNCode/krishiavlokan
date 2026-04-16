// lib/features/diagnosis/steps/step1_crop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/diagnosis_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/shared_widgets.dart';

class Step1CropScreen extends StatelessWidget {
  const Step1CropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        return DiagnosisStepScaffold(
          step: 1,
          title: 'Fasal Chuniye',
          showOfflineBanner: provider.offlineMode,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Text(
                'Aapne kaun si fasal ugayi thi?',
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Which crop did you grow?',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              VoiceButton(),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: AppCrops.crops.length,
                itemBuilder: (ctx, i) {
                  final crop = AppCrops.crops[i];
                  final isSelected =
                      provider.selectedCrop == crop['name'];
                  return _CropCard(
                    crop: crop,
                    isSelected: isSelected,
                    onTap: () => provider.setCrop(crop['name']!),
                    index: i,
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
          bottomBar: KaNextButton(
            label: 'Aage Badho →',
            isEnabled: provider.selectedCrop != null,
            onPressed: () => context.go(AppRoutes.step2),
          ),
        );
      },
    );
  }
}

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
          color: isSelected ? AppColors.lightGreen : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.deepGreen : AppColors.lightGrey,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 6,
              offset: Offset(0, 2),
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
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
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
            begin: const Offset(0.85, 0.85),
            duration: 300.ms,
            curve: Curves.easeOut,
          ),
    );
  }
}
