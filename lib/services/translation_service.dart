import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslationService {
  static const String _googleTranslateBaseUrl =
      'https://translate.googleapis.com/translate_a/single';
  static const String _myMemoryBaseUrl =
      'https://api.mymemory.translated.net/get';

  Future<String> translateToVietnamese(String text) async {
    final String trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return trimmedText;
    }

    try {
      final Uri uri = Uri.parse(_googleTranslateBaseUrl).replace(
        queryParameters: <String, String>{
          'client': 'gtx',
          'sl': 'auto',
          'tl': 'vi',
          'dt': 't',
          'q': trimmedText,
        },
      );

      final http.Response response = await http
          .get(uri)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw Exception('Lỗi dịch: ${response.statusCode}');
      }

      final dynamic body = jsonDecode(response.body);
      if (body is! List || body.isEmpty || body.first is! List) {
        throw Exception('Dữ liệu dịch không đúng định dạng.');
      }

      final List<dynamic> firstLayer = body.first as List<dynamic>;
      final String translated = firstLayer
          .whereType<List<dynamic>>()
          .map((List<dynamic> part) => part.isNotEmpty ? '${part[0] ?? ''}' : '')
          .join()
          .trim();

      if (translated.isEmpty) {
        throw Exception('Không nhận được dữ liệu dịch.');
      }

      return translated;
    } on FormatException {
      throw Exception('Dữ liệu dịch không hợp lệ.');
    } on http.ClientException {
      throw Exception('Lỗi kết nối khi dịch.');
    } catch (_) {
      return _translateWithMyMemory(trimmedText);
    }
  }

  Future<String> _translateWithMyMemory(String text) async {
    final Uri uri = Uri.parse(_myMemoryBaseUrl).replace(
      queryParameters: <String, String>{
        'q': text,
        'langpair': 'en|vi',
      },
    );

    final http.Response response = await http
        .get(uri)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Lỗi dịch: ${response.statusCode}');
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final String? translated = body['responseData']?['translatedText'] as String?;

    if (translated == null || translated.trim().isEmpty) {
      throw Exception('Không nhận được dữ liệu dịch.');
    }

    final String status = '${body['responseStatus'] ?? ''}'.trim();
    if (status.isNotEmpty && status != '200') {
      throw Exception(
        body['responseDetails'] ?? 'Không thể dịch nội dung.',
      );
    }

    return translated.trim();
  }

  Future<({String title, String description})> translateArticle({
    required String title,
    required String description,
  }) async {
    try {
      final String translatedTitle = await translateToVietnamese(title);
      final String translatedDescription = await translateToVietnamese(
        description,
      );

      return (
        title: translatedTitle,
        description: translatedDescription,
      );
    } catch (e) {
      throw Exception('Không thể dịch nội dung: $e');
    }
  }
}
