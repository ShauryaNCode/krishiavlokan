// lib/features/learn/learn_screen.dart
//
// Learn feed — horizontally scrollable chip filters + article cards.
// Tapping a card pushes the detail view.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data/learn_content.dart';
import 'learn_detail_screen.dart';
import '../../providers/diagnosis_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/shared_widgets.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _activeFilter = 'All';

  List<LearnArticle> get _filtered {
    if (_activeFilter == 'All') return learnArticles;
    return learnArticles
        .where((a) => a.categoryLabel == _activeFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: AppColors.deepGreen,
            leading: const SizedBox.shrink(),
            flexibleSpace: FlexibleSpaceBar(
              background: _LearnHeader(),
            ),
          ),

          // ── Chip filter bar ────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterBarDelegate(
              activeFilter: _activeFilter,
              onChanged:    (f) => setState(() => _activeFilter = f),
            ),
          ),

          // ── Article cards ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final article = _filtered[i];
                  return _ArticleCard(
                    article: article,
                    index:   i,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LearnDetailScreen(articleId: article.id),
                        ),
                      );
                    },
                  );
                },
                childCount: _filtered.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _LearnBottomNav(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _LearnHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deepGreen, Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.amber,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LEARN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              const Text('📚', style: TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Crop Science & Field Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${learnArticles.length} research-based guides for Indian farmers',
            style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chip bar as a persistent header delegate
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final String activeFilter;
  final ValueChanged<String> onChanged;

  _FilterBarDelegate({required this.activeFilter, required this.onChanged});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final filters = ['All', ...learnCategories];

    return Container(
      color: AppColors.offWhite,
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final f = filters[i];
          final isActive = f == activeFilter;
          return GestureDetector(
            onTap: () => onChanged(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color:        isActive ? AppColors.deepGreen : AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.deepGreen : AppColors.lightGrey,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color:      AppColors.deepGreen.withOpacity(0.25),
                          blurRadius: 6,
                          offset:     const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                f,
                style: TextStyle(
                  color:      isActive ? Colors.white : AppColors.midGrey,
                  fontWeight: FontWeight.bold,
                  fontSize:   12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterBarDelegate old) =>
      old.activeFilter != activeFilter;
}

// ─────────────────────────────────────────────────────────────────────────────
// Article Card
// ─────────────────────────────────────────────────────────────────────────────
class _ArticleCard extends StatelessWidget {
  final LearnArticle article;
  final int index;
  final VoidCallback onTap;

  const _ArticleCard({
    required this.article,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color:        AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color:      AppColors.shadowColor,
                blurRadius: 10,
                offset:     Offset(0, 3)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ────────────────────────────────────────────────
              _ArticleThumbnail(article: article),

              // ── Content ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color:        article.lightColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.categoryLabel,
                        style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.bold,
                          color:      article.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize:   16,
                            height:     1.3,
                            color:      AppColors.darkText,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Summary
                    Text(
                      article.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:  AppColors.midGrey,
                            height: 1.5,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    // Read More button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onTap,
                            style: OutlinedButton.styleFrom(
                              minimumSize:      const Size(0, 38),
                              foregroundColor:  article.accentColor,
                              side:             BorderSide(
                                  color: article.accentColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Read More',
                                  style: TextStyle(
                                    color:      article.accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize:   13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: article.accentColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Article length indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color:        AppColors.offWhite,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 12, color: AppColors.lightGrey),
                              const SizedBox(width: 4),
                              Text(
                                '5 min',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.lightGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: (index * 70).ms)
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.06, end: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Article thumbnail — gradient hero with emoji
// ─────────────────────────────────────────────────────────────────────────────
class _ArticleThumbnail extends StatelessWidget {
  final LearnArticle article;
  const _ArticleThumbnail({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            article.accentColor.withOpacity(0.85),
            article.accentColor,
          ],
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -15, left: 20,
            child: Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Large emoji
          Positioned(
            right: 16, top: 0, bottom: 0,
            child: Center(
              child: Text(
                article.heroEmoji,
                style: TextStyle(
                  fontSize: 64,
                  shadows: [
                    Shadow(
                      color:  Colors.black.withOpacity(0.15),
                      offset: const Offset(2, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Category label bottom-left
          Positioned(
            left: 14, bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                article.categoryLabel.toUpperCase(),
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom nav — index 1 is now Learn
// ─────────────────────────────────────────────────────────────────────────────
class _LearnBottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
              color:      AppColors.shadowColor,
              blurRadius: 12,
              offset:     Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: 1,
          elevation:    0,
          backgroundColor: Colors.transparent,
          onTap: (i) {
            switch (i) {
              case 0: context.go(AppRoutes.home);
              case 2: context.go(AppRoutes.history);
              case 3: context.go(AppRoutes.settings);
            }
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded), label: 'Learn'),
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
