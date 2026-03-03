class NewsArticle {
  final String title;
  final String description;
  final String imageUrl;
  final String sourceName;
  final String publishedAt;
  final String articleUrl;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.sourceName,
    required this.publishedAt,
    required this.articleUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'Không có tiêu đề',
      description: (json['description'] as String?)?.trim().isNotEmpty == true
          ? json['description'] as String
          : 'Không có mô tả',
      imageUrl: json['urlToImage'] as String? ?? '',
      sourceName:
          (json['source']?['name'] as String?)?.trim().isNotEmpty == true
          ? json['source']['name'] as String
          : 'Nguồn không xác định',
      publishedAt: json['publishedAt'] as String? ?? '',
      articleUrl: json['url'] as String? ?? '',
    );
  }
}
