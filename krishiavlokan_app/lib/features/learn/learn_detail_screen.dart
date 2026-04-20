import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/data/learn_content.dart';
import '../../core/theme/app_colors.dart';

class LearnDetailScreen extends StatelessWidget {
  final String articleId;

  const LearnDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    final article = articleById(articleId);

    if (article == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Article Not Found'),
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('This article could not be found.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: article.accentColor,
        foregroundColor: Colors.white,
        title: Text(
          article.categoryLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareArticle(context, article),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(article: article),
          const SizedBox(height: 16),
          _MetaRow(article: article),
          const SizedBox(height: 16),
          Text(
            article.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            article.summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.midGrey,
                  height: 1.6,
                ),
          ),
          const SizedBox(height: 20),
          _VideoCard(article: article),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Deep Dive',
            icon: Icons.science_outlined,
            color: article.accentColor,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            child: Text(
              article.deepDive,
              style: const TextStyle(
                color: AppColors.darkText,
                height: 1.75,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Actionable Solutions',
            icon: Icons.checklist_rounded,
            color: article.accentColor,
          ),
          const SizedBox(height: 12),
          ...article.actionableSections.asMap().entries.map(
                (entry) => _ActionableCard(
                  index: entry.key,
                  section: entry.value,
                  accentColor: article.accentColor,
                  lightColor: article.lightColor,
                ),
              ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Research Corner',
            icon: Icons.biotech_outlined,
            color: article.accentColor,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: article.lightColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: article.accentColor.withOpacity(0.25),
              ),
            ),
            child: Text(
              article.researchCorner,
              style: const TextStyle(
                color: AppColors.darkText,
                height: 1.7,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  void _shareArticle(BuildContext context, LearnArticle article) {
    Clipboard.setData(ClipboardData(text: article.title));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Article title copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final LearnArticle article;

  const _HeroCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            article.accentColor,
            article.accentColor.withOpacity(0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text(
              article.heroEmoji,
              style: const TextStyle(fontSize: 56),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.categoryLabel.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final LearnArticle article;

  const _MetaRow({required this.article});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: article.lightColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            article.categoryLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: article.accentColor,
            ),
          ),
        ),
        const SizedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: AppColors.lightGrey),
              SizedBox(width: 4),
              Text(
                '5 min read',
                style: TextStyle(fontSize: 12, color: AppColors.lightGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkText,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _VideoCard extends StatelessWidget {
  final LearnArticle article;

  const _VideoCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 170,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.darkBg,
                  article.accentColor.withOpacity(0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  article.youtubeTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _launchYoutube(context, article.youtubeUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFFF0000).withOpacity(0.88),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_display_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Watch on YouTube',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded, color: Colors.white, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchYoutube(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('YouTube link copied: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ActionableCard extends StatelessWidget {
  final LearnSection section;
  final int index;
  final Color accentColor;
  final Color lightColor;

  const _ActionableCard({
    required this.section,
    required this.index,
    required this.accentColor,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: lightColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            section.heading,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.65,
              color: AppColors.midGrey,
            ),
          ),
        ],
      ),
    );
  }
}
