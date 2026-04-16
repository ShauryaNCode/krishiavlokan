// lib/features/diagnosis/steps/step3_sowing_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/diagnosis_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/shared_widgets.dart';

class Step3SowingScreen extends StatefulWidget {
  const Step3SowingScreen({super.key});

  @override
  State<Step3SowingScreen> createState() => _Step3SowingScreenState();
}

class _Step3SowingScreenState extends State<Step3SowingScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear  = DateTime.now().year - 0;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _monthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String get _season {
    if (_selectedMonth >= 6 && _selectedMonth <= 9) return 'Kharif Season 🌧️';
    if (_selectedMonth >= 10 || _selectedMonth <= 3) return 'Rabi Season ❄️';
    return 'Zaid Season ☀️';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DiagnosisProvider>();

    return DiagnosisStepScaffold(
      step: 3,
      title: 'Baayi Ki Tarikh',
      showOfflineBanner: provider.offlineMode,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Text(
            'Aapne beej kab boya tha?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'When did you sow the seeds?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          VoiceButton(),
          const SizedBox(height: 24),

          // Month selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mahina / Month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.midGrey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_months.length, (i) {
                    final isSelected = _selectedMonth == i + 1;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedMonth = i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.deepGreen
                              : AppColors.offWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.deepGreen
                                : AppColors.lightGrey,
                          ),
                        ),
                        child: Text(
                          _months[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppColors.midGrey,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Year selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saal / Year',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.midGrey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () =>
                          setState(() => _selectedYear--),
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.deepGreen),
                    ),
                    Text(
                      '$_selectedYear',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: AppColors.deepGreen),
                    ),
                    IconButton(
                      onPressed: _selectedYear >= DateTime.now().year
                          ? null
                          : () => setState(() => _selectedYear++),
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _selectedYear >= DateTime.now().year
                            ? AppColors.lightGrey
                            : AppColors.deepGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary + season badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.successGreen),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.deepGreen, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${_monthsFull[_selectedMonth - 1]} $_selectedYear',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.deepGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SizedBox(width: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _season,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: AppColors.lightGrey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hum is date se aapke khet ka mausam khud nikal lenge',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomBar: KaNextButton(
        onPressed: () {
          provider.setSowingDate(DateTime(_selectedYear, _selectedMonth));
          context.go(AppRoutes.step4);
        },
      ),
    );
  }
}
