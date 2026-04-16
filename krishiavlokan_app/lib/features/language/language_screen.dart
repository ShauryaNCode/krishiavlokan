// lib/features/language/language_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DiagnosisProvider>();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header illustration
            Container(
              width: double.infinity,
              color: AppColors.deepGreen,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const Text('🧑‍🌾', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 10),
                  Text(
                    'Choose Your Language',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'अपनी भाषा चुनें',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),

            // Language list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: AppLanguages.languages.length,
                itemBuilder: (ctx, i) {
                  final lang = AppLanguages.languages[i];
                  final isSelected = _selected == lang['code'];

                  return _LanguageTile(
                    lang: lang,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selected = lang['code']),
                    index: i,
                  );
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () async {
                        await provider.setLanguage(_selected!);
                        if (context.mounted) context.go(AppRoutes.home);
                      },
                child: const Text('Continue / जारी रखें'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final Map<String, String> lang;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _LanguageTile({
    required this.lang,
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightGreen
              : AppColors.cardWhite,
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
            if (isSelected)
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            if (isSelected) const SizedBox(width: 12),
            Expanded(
              child: Text(
                lang['name']!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isSelected
                          ? AppColors.deepGreen
                          : AppColors.darkText,
                    ),
              ),
            ),
            Text(
              lang['english']!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.deepGreen, size: 22),
            ],
          ],
        ),
      )
          .animate(delay: (index * 60).ms)
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.1, end: 0),
    );
  }
}
