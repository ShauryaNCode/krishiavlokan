// lib/features/diagnosis/steps/step4_symptoms_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/diagnosis_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/shared_widgets.dart';

class Step4SymptomsScreen extends StatelessWidget {
  const Step4SymptomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        final canProceed = provider.selectedSymptoms.isNotEmpty;

        return DiagnosisStepScaffold(
          step: 4,
          title: 'Lakshan Chuniye',
          showOfflineBanner: provider.offlineMode,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Text(
                'Aapki fasal mein kya dikha?',
                style: Theme.of(ctx).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Ek ya zyada chuniye (Select one or more)',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              VoiceButton(),
              const SizedBox(height: 20),
              ...AppSymptoms.symptoms.asMap().entries.map((entry) {
                final i       = entry.key;
                final symptom = entry.value;
                final isSelected =
                    provider.isSymptomSelected(symptom['key']!);
                return _SymptomCard(
                  symptom: symptom,
                  isSelected: isSelected,
                  onTap: () => provider.toggleSymptom(symptom['key']!),
                  index: i,
                );
              }),
              const SizedBox(height: 80),
            ],
          ),
          bottomBar: KaNextButton(
            label: 'Vishleshan Karo ✓',
            isEnabled: canProceed,
            onPressed: () {
              context.go(AppRoutes.loading);
            },
          ),
        );
      },
    );
  }
}

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
        margin: const EdgeInsets.only(bottom: 10),
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
              color: AppColors.shadowColor,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left accent bar
            if (isSelected)
              Container(
                width: 4,
                height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
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
                          color: isSelected
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
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.deepGreen : Colors.transparent,
                shape: BoxShape.circle,
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
      )
          .animate(delay: (index * 60).ms)
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.08, end: 0),
    );
  }
}
