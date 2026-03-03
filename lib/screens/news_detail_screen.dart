import 'package:danhmuctintuc_th3/models/news_article.dart';
import 'package:danhmuctintuc_th3/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({required this.article, super.key});

  final NewsArticle article;

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final TranslationService _translationService = TranslationService();

  bool _translateToVietnamese = false;
  bool _isTranslating = false;
  String? _translatedTitle;
  String? _translatedDescription;

  Future<void> _toggleTranslation(bool value) async {
    if (!value) {
      setState(() {
        _translateToVietnamese = false;
      });
      return;
    }

    if (_translatedTitle != null && _translatedDescription != null) {
      setState(() {
        _translateToVietnamese = true;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _translateToVietnamese = true;
    });

    try {
      final ({String title, String description}) translated =
          await _translationService.translateArticle(
            title: widget.article.title,
            description: widget.article.description,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _translatedTitle = translated.title;
        _translatedDescription = translated.description;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _translateToVietnamese = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể dịch bài viết: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  Future<void> _openArticleUrl(BuildContext context) async {
    final String rawUrl = widget.article.articleUrl.trim();
    if (rawUrl.isEmpty) {
      return;
    }

    final Uri? uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liên kết không hợp lệ.')),
      );
      return;
    }

    final bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở liên kết.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isCompact = screenWidth < 380;
    final double horizontalPadding = isCompact ? 12 : 16;
    final bool hasImage = widget.article.imageUrl.trim().isNotEmpty;
    final String title = _translateToVietnamese && _translatedTitle != null
        ? _translatedTitle!
        : widget.article.title;
    final String description =
        _translateToVietnamese && _translatedDescription != null
        ? _translatedDescription!
        : widget.article.description;

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
                _AdaptiveDetailImage(
                  imageUrl: widget.article.imageUrl,
                  screenWidth: screenWidth,
                ),
              if (hasImage) const SizedBox(height: 14),
              Text(
                title,
                style:
                    (isCompact ? textTheme.titleLarge : textTheme.headlineSmall)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Nguồn: ${widget.article.sourceName}',
                style: textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(widget.article.publishedAt, style: textTheme.labelMedium),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Dịch sang tiếng Việt',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  if (_isTranslating)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _translateToVietnamese,
                    onChanged: _isTranslating ? null : _toggleTranslation,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(description, style: textTheme.bodyLarge),
              if (widget.article.articleUrl.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                Text('Liên kết bài viết:', style: textTheme.titleSmall),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _openArticleUrl(context),
                  child: Text(
                    widget.article.articleUrl,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveDetailImage extends StatefulWidget {
  const _AdaptiveDetailImage({required this.imageUrl, required this.screenWidth});

  final String imageUrl;
  final double screenWidth;

  @override
  State<_AdaptiveDetailImage> createState() => _AdaptiveDetailImageState();
}

class _AdaptiveDetailImageState extends State<_AdaptiveDetailImage> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _resolveAspectRatio();
  }

  @override
  void didUpdateWidget(covariant _AdaptiveDetailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _aspectRatio = null;
      _resolveAspectRatio();
    }
  }

  Future<void> _resolveAspectRatio() async {
    final ImageProvider provider = NetworkImage(widget.imageUrl);
    final ImageStream stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo imageInfo, bool _) {
        if (!mounted) {
          stream.removeListener(listener);
          return;
        }
        final int width = imageInfo.image.width;
        final int height = imageInfo.image.height;
        if (width > 0 && height > 0) {
          setState(() {
            _aspectRatio = width / height;
          });
        }
        stream.removeListener(listener);
      },
      onError: (_, _) {
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final double fallbackHeight = (widget.screenWidth * 0.6).clamp(190.0, 280.0);
    final double adaptiveHeight = _aspectRatio != null && _aspectRatio! > 0
        ? (widget.screenWidth / _aspectRatio!).clamp(190.0, 460.0)
        : fallbackHeight;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: adaptiveHeight,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Image.network(
          widget.imageUrl,
          width: double.infinity,
          height: adaptiveHeight,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
