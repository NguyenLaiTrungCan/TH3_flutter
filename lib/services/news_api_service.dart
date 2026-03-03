import 'dart:convert';

import 'package:danhmuctintuc_th3/models/news_article.dart';
import 'package:http/http.dart' as http;

class NewsPageResult {
  const NewsPageResult({required this.articles, required this.totalResults});

  final List<NewsArticle> articles;
  final int totalResults;
}

class NewsApiService {
  static const String _baseUrl = 'https://newsapi.org/v2/top-headlines';
  static const String _apiKey = '0655f111aa2b4702b738161a0cd8f600';

  Future<NewsPageResult> fetchTopHeadlines({
    required String category,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: <String, String>{
          'country': 'us',
          'category': category,
          'page': '$page',
          'pageSize': '$pageSize',
          'apiKey': _apiKey,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('Lỗi server: ${response.statusCode}');
      }

      final Map<String, dynamic> jsonBody =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (jsonBody['status'] != 'ok') {
        throw Exception(
          jsonBody['message'] ?? 'Không thể tải dữ liệu tin tức.',
        );
      }

      final int totalResults = (jsonBody['totalResults'] as num?)?.toInt() ?? 0;
      final List<dynamic> data = jsonBody['articles'] as List<dynamic>? ?? [];
      final List<NewsArticle> articles = data
          .map((dynamic e) => NewsArticle.fromJson(e as Map<String, dynamic>))
          .toList();

      return NewsPageResult(articles: articles, totalResults: totalResults);
    } on FormatException {
      throw Exception('Dữ liệu trả về không hợp lệ.');
    } on http.ClientException {
      throw Exception('Lỗi kết nối mạng. Vui lòng thử lại.');
    } catch (e) {
      throw Exception('Không thể tải dữ liệu: $e');
    }
  }
}
