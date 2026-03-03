import 'package:danhmuctintuc_th3/models/news_article.dart';
import 'package:flutter/material.dart';

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({required this.article, super.key});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isCompact = screenWidth < 380;
    final double horizontalPadding = isCompact ? 12 : 16;
    final double detailImageHeight = (screenWidth * 0.6).clamp(190.0, 280.0);
    final bool hasImage = article.imageUrl.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết tin tức')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    article.imageUrl,
                    width: double.infinity,
                    height: detailImageHeight,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              if (hasImage) const SizedBox(height: 14),
              Text(
                article.title,
                style:
                    (isCompact ? textTheme.titleLarge : textTheme.headlineSmall)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text('Nguồn: ${article.sourceName}', style: textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(article.publishedAt, style: textTheme.labelMedium),
              const SizedBox(height: 16),
              Text(article.description, style: textTheme.bodyLarge),
              if (article.articleUrl.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                Text('Liên kết bài viết:', style: textTheme.titleSmall),
                const SizedBox(height: 6),
                SelectableText(article.articleUrl, style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
