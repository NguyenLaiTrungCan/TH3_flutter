import 'package:danhmuctintuc_th3/models/news_article.dart';
import 'package:danhmuctintuc_th3/screens/news_detail_screen.dart';
import 'package:danhmuctintuc_th3/services/news_api_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class NewsHomeScreen extends StatefulWidget {
  const NewsHomeScreen({super.key});

  @override
  State<NewsHomeScreen> createState() => _NewsHomeScreenState();
}

class _NewsHomeScreenState extends State<NewsHomeScreen> {
  static const int _pageSize = 10;

  final NewsApiService _newsApiService = NewsApiService();
  final ScrollController _categoryScrollController = ScrollController();
  final ScrollController _articleScrollController = ScrollController();

  final List<String> _categories = <String>[
    'general',
    'business',
    'entertainment',
    'health',
    'science',
    'sports',
    'technology',
  ];

  final Map<String, String> _categoryLabels = <String, String>{
    'general': 'Tổng hợp',
    'business': 'Kinh doanh',
    'entertainment': 'Giải trí',
    'health': 'Sức khỏe',
    'science': 'Khoa học',
    'sports': 'Thể thao',
    'technology': 'Công nghệ',
  };

  final List<NewsArticle> _articles = <NewsArticle>[];

  String _selectedCategory = 'general';
  String? _initialError;
  String? _loadMoreError;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  int _currentPage = 1;
  int _totalResults = 0;

  @override
  void initState() {
    super.initState();
    _articleScrollController.addListener(_onArticleScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    _articleScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _isInitialLoading = true;
      _initialError = null;
      _loadMoreError = null;
      _articles.clear();
      _currentPage = 1;
      _totalResults = 0;
      _hasMore = true;
    });

    try {
      final NewsPageResult result = await _newsApiService.fetchTopHeadlines(
        category: _selectedCategory,
        page: 1,
        pageSize: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _articles
          ..clear()
          ..addAll(result.articles);
        _totalResults = result.totalResults;
        _currentPage = 1;
        _hasMore =
            _articles.length < _totalResults && result.articles.isNotEmpty;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialError = '$e';
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final int nextPage = _currentPage + 1;
      final NewsPageResult result = await _newsApiService.fetchTopHeadlines(
        category: _selectedCategory,
        page: nextPage,
        pageSize: _pageSize,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _articles.addAll(result.articles);
        _totalResults = result.totalResults;
        _currentPage = nextPage;
        _hasMore =
            _articles.length < _totalResults && result.articles.isNotEmpty;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = '$e';
      });
    }
  }

  void _onArticleScroll() {
    if (!_articleScrollController.hasClients) {
      return;
    }

    if (_articleScrollController.position.extentAfter < 320) {
      _loadMore();
    }
  }

  void _onSelectCategory(String category) {
    if (_selectedCategory == category) {
      return;
    }

    setState(() {
      _selectedCategory = category;
    });
    _loadFirstPage();
  }

  void _openDetail(NewsArticle article) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewsDetailScreen(article: article),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Có lỗi xảy ra khi tải dữ liệu.\n${_initialError ?? ''}',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadFirstPage,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('Không có dữ liệu tin tức.'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadFirstPage,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleImage({
    required NewsArticle article,
    required ColorScheme colorScheme,
    required double imageHeight,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        article.imageUrl,
        height: imageHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        frameBuilder:
            (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
        loadingBuilder:
            (
              BuildContext context,
              Widget child,
              ImageChunkEvent? loadingProgress,
            ) {
              if (loadingProgress == null) {
                return child;
              }
              return Container(
                height: imageHeight,
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              );
            },
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildArticleCard({
    required NewsArticle article,
    required bool isCompact,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
    required double imageHeight,
  }) {
    final bool hasImage = article.imageUrl.trim().isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(article),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 10 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (hasImage)
                _buildArticleImage(
                  article: article,
                  colorScheme: colorScheme,
                  imageHeight: imageHeight,
                ),
              if (hasImage) SizedBox(height: isCompact ? 8 : 10),
              Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    (isCompact ? textTheme.titleSmall : textTheme.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                article.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      article.sourceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      article.publishedAt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreFooter() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton(
            onPressed: _loadMore,
            child: const Text('Lỗi tải thêm. Bấm để thử lại'),
          ),
        ),
      );
    }

    if (_hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: SizedBox.shrink(),
      );
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Center(child: Text('Đã hiển thị hết tin tức')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isCompact = screenWidth < 380;
    final double horizontalPadding = isCompact ? 10 : 12;
    final double cardImageHeight = (screenWidth * 0.5).clamp(150.0, 210.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TH3 - Nguyễn Lại Trung Cần - 2351060421'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                6,
              ),
              child: SizedBox(
                height: isCompact ? 40 : 42,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                    dragDevices: <PointerDeviceKind>{
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.unknown,
                    },
                  ),
                  child: ListView.separated(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (BuildContext context, int index) {
                      final String category = _categories[index];
                      final String categoryLabel =
                          _categoryLabels[category] ?? category;
                      return ChoiceChip(
                        label: Text(categoryLabel),
                        selected: _selectedCategory == category,
                        onSelected: (bool selected) {
                          if (!selected) {
                            return;
                          }
                          _onSelectCategory(category);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (BuildContext context) {
                  if (_isInitialLoading) {
                    return _buildLoadingState();
                  }

                  if (_initialError != null) {
                    return _buildErrorState(textTheme);
                  }

                  if (_articles.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    controller: _articleScrollController,
                    padding: EdgeInsets.all(horizontalPadding),
                    itemCount: _articles.length + 1,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: isCompact ? 10 : 8),
                    itemBuilder: (BuildContext context, int index) {
                      if (index == _articles.length) {
                        return _buildLoadMoreFooter();
                      }

                      final NewsArticle article = _articles[index];
                      return _buildArticleCard(
                        article: article,
                        isCompact: isCompact,
                        textTheme: textTheme,
                        colorScheme: colorScheme,
                        imageHeight: cardImageHeight,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
