// lib/features/results/results_screen.dart
//
// Redesigned to match the provided UI exactly:
//   • Hero card with gradient leaf image + cause overlay
//   • Explanation card (plain text)
//   • Weather Context — side-by-side phase cards (Early/Mid white, Late dark)
//   • Actionable Advice — icon-list layout
//   • Share + Save buttons + Naya Vishleshan Karo

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/advice_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../models/analysis_model.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/shared_widgets.dart';

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
            backgroundColor: AppColors.deepGreen,
            elevation: 0,
            leading: BackButton(
              color: Colors.white,
              onPressed: () => context.go(AppRoutes.home),
            ),
            title: const Text(
              'Your Analysis is Ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.volume_up_outlined,
                    color: Colors.white, size: 22),
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
              if (result.isLimitedAnalysis) const _LimitedBanner(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ── Hero cause card ──────────────────────────────────
                    _HeroCauseCard(result: result),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // ── Explanation ──────────────────────────────
                          _ExplanationCard(text: result.explanation),

                          const SizedBox(height: 20),

                          // ── Weather Context ──────────────────────────
                          _WeatherContextSection(phases: result.weatherPhases),

                          const SizedBox(height: 24),

                          // ── Actionable Advice ────────────────────────
                          _ActionableAdviceSection(
                              recs: result.recommendations),

                          const SizedBox(height: 28),

                          // ── Bottom buttons ───────────────────────────
                          _BottomButtons(
                            saved:   _saved,
                            onShare: () => _share(context, result),
                            onSave:  () {
                              if (!_saved) {
                                provider.saveCurrentToHistory();
                                setState(() => _saved = true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Saved to history ✅'),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                              }
                            },
                            onNewAnalysis: () {
                              provider.resetDiagnosis();
                              context.go(AppRoutes.step1);
                            },
                          ),

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
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
            '📤 ${result.causeTitle} — ${result.crop} (${result.seasonYear})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Cause Card
// Gradient leaf image background with cause overlay at bottom
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCauseCard extends StatelessWidget {
  final AnalysisResult result;
  const _HeroCauseCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // Leaf-green gradient simulates crop photo
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5D9E6E),
            Color(0xFF2D6A4F),
            Color(0xFF1B4332),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Decorative leaf shapes ─────────────────────────────────
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              top: 20, right: 30,
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Subtle leaf emoji watermark
            Positioned(
              right: 20, top: 16,
              child: Text(
                '🌿',
                style: TextStyle(
                    fontSize: 72,
                    color: Colors.white.withOpacity(0.15)),
              ),
            ),

            // ── Bottom gradient overlay + text ─────────────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // ── Cause text overlay ─────────────────────────────────────
            Positioned(
              left: 18, right: 18, bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Amber "PRIMARY CAUSE" badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PRIMARY CAUSE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Cause title
                  Text(
                    result.causeTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Subtitle
                  Text(
                    'Detected in ${result.crop} • ${result.district} Region',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, duration: 500.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Explanation Card — plain white card, just paragraph text
// ─────────────────────────────────────────────────────────────────────────────
class _ExplanationCard extends StatelessWidget {
  final String text;
  const _ExplanationCard({required this.text});

  // Keep the full backend explanation, only normalizing whitespace.
  String get _clean {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        _clean,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.65,
              color: AppColors.darkText,
            ),
      ),
    ).animate(delay: 150.ms).fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Weather Context Section
// ─────────────────────────────────────────────────────────────────────────────
class _WeatherContextSection extends StatelessWidget {
  final List<WeatherPhase> phases;
  const _WeatherContextSection({required this.phases});

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty) return const SizedBox.shrink();

    // Split: first 2 side-by-side, last one full-width dark
    final topPhases  = phases.length >= 2 ? phases.sublist(0, 2) : phases;
    final latePhase  = phases.length >= 3 ? phases[2] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Weather Context',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
            const Spacer(),
            Text(
              'GROWTH PHASES',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightGrey,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Top row: Early + Mid
        Row(
          children: topPhases
              .map((p) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: p == topPhases.first ? 8 : 0,
                      ),
                      child: _LightPhaseCard(phase: p),
                    ),
                  ))
              .toList(),
        ),

        if (latePhase != null) ...[
          const SizedBox(height: 10),
          _DarkPhaseCard(phase: latePhase),
        ],
      ],
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

// Light (white) phase card — used for Early and Mid
class _LightPhaseCard extends StatelessWidget {
  final WeatherPhase phase;
  const _LightPhaseCard({required this.phase});

  @override
  Widget build(BuildContext context) {
    final statusColor = _phaseStatusColor(phase.status);
    final statusLabel = _phaseStatusLabel(phase.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase label + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${phase.phase.toUpperCase()} PHASE',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.midGrey,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          // Icon + status badge row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _phaseIcon(phase.phase, phase.status),
                color: statusColor,
                size: 22,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Rainfall
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${phase.rainfallMm.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const TextSpan(
                  text: 'mm',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.midGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${phase.avgTempC.toStringAsFixed(0)}°C Avg',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.midGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Bottom accent line
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// Dark (deep green) phase card — used for Late phase
class _DarkPhaseCard extends StatelessWidget {
  final WeatherPhase phase;
  const _DarkPhaseCard({required this.phase});

  @override
  Widget build(BuildContext context) {
    final statusLabel = _phaseStatusLabel(phase.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.deepGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepGreen.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${phase.phase.toUpperCase()} PHASE',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white60,
                ),
              ),
              const Spacer(),
              // Decorative humidity badge top-right
              Text(
                '${phase.avgHumidityPct.toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _phaseIcon(phase.phase, phase.status),
                color: Colors.white70,
                size: 24,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${phase.rainfallMm.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const TextSpan(
                  text: 'mm',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${phase.avgTempC.toStringAsFixed(0)}°C Avg',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Actionable Advice Section
// ─────────────────────────────────────────────────────────────────────────────
class _ActionableAdviceSection extends StatelessWidget {
  final List<RecommendationItem> recs;
  const _ActionableAdviceSection({required this.recs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actionable Advice',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.deepGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
        ),
        const SizedBox(height: 14),
        ...recs.asMap().entries.map(
          (e) => _AdviceRow(rec: e.value, index: e.key),
        ),
      ],
    ).animate(delay: 350.ms).fadeIn(duration: 400.ms);
  }
}

class _AdviceRow extends StatelessWidget {
  final RecommendationItem rec;
  final int index;
  const _AdviceRow({required this.rec, required this.index});

  // Pick a Material icon based on position / content
  IconData _icon() {
    final t = rec.title.toLowerCase();
    if (t.contains('nutrient') || t.contains('check'))
      return Icons.biotech_outlined;
    if (t.contains('water') || t.contains('moisture') || t.contains('drip'))
      return Icons.water_drop_outlined;
    if (t.contains('apply') || t.contains('fertil') || t.contains('nutrition'))
      return Icons.science_outlined;
    if (t.contains('drain') || t.contains('channel'))
      return Icons.waves_outlined;
    if (t.contains('pest') || t.contains('insect'))
      return Icons.bug_report_outlined;
    if (t.contains('sow') || t.contains('date') || t.contains('time'))
      return Icons.calendar_today_outlined;
    if (t.contains('seed') || t.contains('variety'))
      return Icons.grass_outlined;
    if (index == 0) return Icons.remove_red_eye_outlined;
    if (index == 1) return Icons.science_outlined;
    return Icons.water_drop_outlined;
  }

  String? get _imageAsset => adviceImageAssetForKey(rec.adviceKey);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon(),
              color: AppColors.deepGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rec.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                              fontSize: 15,
                            ),
                      ),
                    ),
                    // Priority badge if present
                    if (rec.priority.isNotEmpty)
                      _PriorityBadge(priority: rec.priority),
                  ],
                ),
                if (_imageAsset != null) ...[
                  const SizedBox(height: 10),
                  _AdviceImageCard(assetPath: _imageAsset!),
                ],
                const SizedBox(height: 4),
                Text(
                  rec.detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.midGrey,
                        height: 1.5,
                      ),
                ),
                // Effort level tag
                if (rec.effortLevel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _EffortTag(level: rec.effortLevel),
                ],
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: (350 + index * 80).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }
}

class _AdviceImageCard extends StatelessWidget {
  final String assetPath;
  const _AdviceImageCard({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        assetPath,
        height: 132,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final isHigh = priority.toLowerCase() == 'high';
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isHigh
            ? AppColors.terracotta.withOpacity(0.12)
            : AppColors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isHigh ? AppColors.terracotta : AppColors.amber,
        ),
      ),
    );
  }
}

class _EffortTag extends StatelessWidget {
  final String level;
  const _EffortTag({required this.level});

  @override
  Widget build(BuildContext context) {
    final isEasy = level.toLowerCase() == 'easy';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isEasy ? Icons.bolt_rounded : Icons.build_outlined,
          size: 12,
          color: isEasy ? AppColors.successGreen : AppColors.amber,
        ),
        const SizedBox(width: 3),
        Text(
          level,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isEasy ? AppColors.successGreen : AppColors.amber,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Buttons
// ─────────────────────────────────────────────────────────────────────────────
class _BottomButtons extends StatelessWidget {
  final bool saved;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onNewAnalysis;

  const _BottomButtons({
    required this.saved,
    required this.onShare,
    required this.onSave,
    required this.onNewAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Share + Save row
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onShare,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  side: const BorderSide(color: AppColors.deepGreen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.share_rounded,
                    size: 16, color: AppColors.deepGreen),
                label: const Text(
                  'Share',
                  style: TextStyle(
                      color: AppColors.deepGreen, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: saved ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      saved ? AppColors.successGreen : AppColors.deepGreen,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  saved
                      ? Icons.check_circle_rounded
                      : Icons.bookmark_add_rounded,
                  size: 16,
                ),
                label: Text(
                  saved ? 'Saved ✓' : 'Save',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Naya Vishleshan Karo — full width
        OutlinedButton.icon(
          onPressed: onNewAnalysis,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: AppColors.deepGreen),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.refresh_rounded,
              size: 16, color: AppColors.deepGreen),
          label: const Text(
            'Naya Vishleshan Karo',
            style: TextStyle(
                color: AppColors.deepGreen, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Limited analysis banner (offline mode)
// ─────────────────────────────────────────────────────────────────────────────
class _LimitedBanner extends StatelessWidget {
  const _LimitedBanner();

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
              'Limited Analysis — Cached data used (Offline Mode)',
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

// ─────────────────────────────────────────────────────────────────────────────
// Phase helpers (local to this file)
// ─────────────────────────────────────────────────────────────────────────────

/// Returns a weather icon suited for the phase + status combo.
IconData _phaseIcon(String phase, String status) {
  final p = phase.toLowerCase();
  final s = status.toLowerCase();
  if (p == 'early') return Icons.cloud_outlined;
  if (p == 'mid')   return Icons.water_drop_outlined;
  // Late phase — show temperature if hot, else rain
  if (s.contains('high') || s.contains('veryHigh'))
    return Icons.thermostat_outlined;
  return Icons.thermostat_outlined;
}

Color _phaseStatusColor(String status) {
  final s = status.toLowerCase();
  if (s == 'verylow' || s == 'veryhigh') return AppColors.dangerRed;
  if (s == 'low'     || s == 'high')     return AppColors.amber;
  return AppColors.successGreen;
}

String _phaseStatusLabel(String status) {
  return switch (status.toLowerCase()) {
    'verylow'  => 'Very Low',
    'low'      => 'Low',
    'high'     => 'High',
    'veryhigh' => 'Very High',
    _          => 'Normal',
  };
}
