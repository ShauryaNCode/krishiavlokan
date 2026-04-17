// lib/features/results/results_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/analysis_model.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<DiagnosisProvider>(
      builder: (ctx, provider, _) {
        final result = provider.currentResult;
        if (result == null) {
          return const Scaffold(
            body: Center(child: Text('No result found')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.offWhite,
          appBar: AppBar(
            title: const Text('Aapka Vishleshan'),
            leading: BackButton(
              onPressed: () => context.go(AppRoutes.home),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voice reading coming soon!'),
                    duration: Duration(seconds: 1),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (result.isLimitedAnalysis) _LimitedBanner(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _CauseCard(result: result),
                    const SizedBox(height: 14),
                    _WeatherStripCard(result: result),
                    const SizedBox(height: 14),
                    _RecommendationsCard(result: result),
                    const SizedBox(height: 20),
                    _ActionButtons(
                      saved: _saved,
                      onShare: () => _share(context, result),
                      onSave: () {
                        if (!_saved) {
                          provider.saveCurrentToHistory();
                          setState(() => _saved = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  '✅ Itihas mein save ho gaya!'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {
                        provider.resetDiagnosis();
                        context.go(AppRoutes.step1);
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Naya Vishleshan Karo'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _share(BuildContext ctx, AnalysisResult result) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(
          '📤 Sharing: ${result.causeTitle} — ${result.crop} '
          '(${result.seasonYear})',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Limited Analysis Banner ──────────────────────────────────────────────────
class _LimitedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.lightAmber,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Seemit Vishleshan — Cached data used (Offline Mode)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cause Card ───────────────────────────────────────────────────────────────
class _CauseCard extends StatelessWidget {
  final AnalysisResult result;
  const _CauseCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return KaCard(
      accentColor: AppColors.amber,
      backgroundColor: AppColors.lightGreen,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                causeEmoji(result.causeKey),
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.causeTitle,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.deepGreen,
                              ),
                    ),
                    Text(
                      '${result.crop} · ${result.seasonYear}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    // Confidence badge — new from real API
                    if (result.confidenceScore > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.deepGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Confidence: ${(result.confidenceScore * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.volume_up_rounded,
                    color: AppColors.deepGreen, size: 20),
              ),
            ],
          ),
          const Divider(height: 20),
          Text(
            result.explanation,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, duration: 500.ms);
  }
}

// ── Weather Strip Card ────────────────────────────────────────────────────────
class _WeatherStripCard extends StatelessWidget {
  final AnalysisResult result;
  const _WeatherStripCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return KaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MAUSAM KA HAAL',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.midGrey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Weather Summary — Traffic Light',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: result.weatherPhases
                .map((phase) => Expanded(
                      child: _WeatherPhaseBox(phase: phase),
                    ))
                .toList(),
          ),
        ],
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 400.ms);
  }
}

class _WeatherPhaseBox extends StatelessWidget {
  final WeatherPhase phase;
  const _WeatherPhaseBox({required this.phase});

  @override
  Widget build(BuildContext context) {
    final color  = weatherStatusColor(phase.status);
    final label  = weatherStatusLabel(phase.status);
    final isNorm = phase.status == 'normal';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: isNorm
            ? AppColors.lightGreen
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(phase.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            phase.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.midGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          // Rainfall deviation from real API
          if (phase.rainfallDeviationPct != 0) ...[
            const SizedBox(height: 2),
            Text(
              '${phase.rainfallDeviationPct > 0 ? '+' : ''}'
              '${phase.rainfallDeviationPct.toStringAsFixed(0)}% rain',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Recommendations Card ──────────────────────────────────────────────────────
class _RecommendationsCard extends StatelessWidget {
  final AnalysisResult result;
  const _RecommendationsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return KaCard(
      accentColor: AppColors.deepGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AGLE SEASON KE LIYE SALAH',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.midGrey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 14),
          ...result.recommendations.asMap().entries.map((e) {
            final i   = e.key;
            final rec = e.value;
            return _RecommendationRow(rec: rec, index: i);
          }),
        ],
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 400.ms);
  }
}

class _RecommendationRow extends StatelessWidget {
  final RecommendationItem rec;
  final int index;
  const _RecommendationRow({required this.rec, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rec.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 14,
                        color: AppColors.deepGreen,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.detail,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
                minWidth: 28, minHeight: 28),
            onPressed: () {},
            icon: const Icon(Icons.volume_up_outlined,
                size: 18, color: AppColors.lightGrey),
          ),
        ],
      ),
    )
        .animate(delay: (400 + index * 100).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.08, end: 0);
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final bool saved;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _ActionButtons({
    required this.saved,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: saved ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  saved ? AppColors.successGreen : AppColors.deepGreen,
            ),
            icon: Icon(
              saved
                  ? Icons.check_circle_rounded
                  : Icons.bookmark_add_rounded,
              size: 18,
            ),
            label: Text(saved ? 'Saved ✓' : 'Save'),
          ),
        ),
      ],
    );
  }
}