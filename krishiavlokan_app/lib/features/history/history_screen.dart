// lib/features/history/history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/analysis_model.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/shared_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Filter: 'all' | 'Kharif' | 'Rabi'
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        final all = provider.history;

        // Apply season filter
        final filtered = _filter == 'all'
            ? all
            : all.where((r) => r.season == _filter).toList();

        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(
            title: const Text('Mera Itihas'),
            leading: BackButton(
              onPressed: () => context.go(AppRoutes.home),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: () => _showFilterSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              if (provider.offlineMode) const OfflineBanner(),

              // Filter tabs
              _FilterTabBar(
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),

              // List
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(filter: _filter)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _HistoryCard(
                          result: filtered[i],
                          index: i,
                          onTap: () {
                            // Set result as current and open results screen
                            // (In production, pass ID via router extra)
                            context.go(AppRoutes.results);
                          },
                          onToggleAdvice: () =>
                              provider.toggleAdviceTaken(filtered[i]),
                        ),
                      ),
              ),
            ],
          ),
          bottomNavigationBar: _HistoryBottomNav(),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Season',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...['all', 'Kharif', 'Rabi', 'Zaid'].map(
              (f) => ListTile(
                leading: Icon(
                  _filter == f
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: AppColors.deepGreen,
                ),
                title: Text(f == 'all' ? 'Sab (All)' : f),
                onTap: () {
                  setState(() => _filter = f);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Tab Bar ─────────────────────────────────────────────────────────
class _FilterTabBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterTabBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('all', 'Sab'),
      ('Kharif', 'Kharif 🌧️'),
      ('Rabi', 'Rabi ❄️'),
    ];

    return Container(
      color: AppColors.cardWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = selected == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.lightGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: AppColors.deepGreen)
                      : null,
                ),
                child: Text(
                  tab.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.deepGreen
                        : AppColors.lightGrey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── History Card ────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final AnalysisResult result;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onToggleAdvice;

  const _HistoryCard({
    required this.result,
    required this.index,
    required this.onTap,
    required this.onToggleAdvice,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Main row
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Crop emoji in circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.lightGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          causeEmoji(result.causeKey),
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.crop,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            result.seasonYear,
                            style:
                                Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          // Cause badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.lightAmber,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              result.causeTitle,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.lightGrey),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(result.analyzedAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Footer strip — advice taken toggle
              GestureDetector(
                onTap: onToggleAdvice,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  color: result.adviceTaken
                      ? AppColors.lightGreen
                      : AppColors.offWhite,
                  child: Row(
                    children: [
                      Icon(
                        result.adviceTaken
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: result.adviceTaken
                            ? AppColors.successGreen
                            : AppColors.lightGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result.adviceTaken
                            ? 'Salah Li — Advice Taken ✅'
                            : 'Salah Li? Tap to mark',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: result.adviceTaken
                              ? AppColors.successGreen
                              : AppColors.lightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: (index * 60).ms)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.08, end: 0),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} '
      '${_months[dt.month - 1]} '
      '${dt.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
}

// ── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            filter == 'all'
                ? 'Koi purana vishleshan nahi mila'
                : 'Koi $filter vishleshan nahi mila',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.midGrey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pehle ek naya vishleshan karo',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.step1),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Naya Vishleshan'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

// ── Bottom Nav ───────────────────────────────────────────────────────────────
class _HistoryBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: Offset(0, -3))
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: 2,
          elevation: 0,
          backgroundColor: Colors.transparent,
          onTap: (i) {
            switch (i) {
              case 0: context.go(AppRoutes.home);
              case 1:
                context.read<DiagnosisProvider>().resetDiagnosis();
                context.go(AppRoutes.step1);
              case 3: context.go(AppRoutes.settings);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.biotech_rounded), label: 'New Analysis'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
