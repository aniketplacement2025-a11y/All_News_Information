// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class NewsApi {
//   final String apiKey =
//       "39fc8513af0648568fb3d8ca975195d4"; // Replace with your API key
//   final String baseUrl = "https://newsapi.org/v2/top-headlines";

//   Future<List<Article>> getArticles() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl?country=us&apiKey=$apiKey'),
//     );

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       final articles = (data['articles'] as List)
//           .map((article) => Article.fromJson(article))
//           .toList();
//       return articles;
//     } else {
//       throw Exception('Failed to load articles');
//     }
//   }
// }

// class Article {
//   final String title;
//   final String description;
//   final String url;
//   final String urlToImage;

//   Article({
//     required this.title,
//     required this.description,
//     required this.url,
//     required this.urlToImage,
//   });

//   factory Article.fromJson(Map<String, dynamic> json) {
//     return Article(
//       title: json['title'] ?? '',
//       description: json['description'] ?? '',
//       url: json['url'] ?? '',
//       urlToImage: json['urlToImage'] ?? '',
//     );
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsApiResponse {
  final List<Article> articles;
  final int totalResults;

  NewsApiResponse({required this.articles, required this.totalResults});
}

/// Simple NewsAPI client. Pass your API key in the constructor
/// (avoid hardcoding in production).
class NewsApi {
  final String apiKey;
  final String baseUrl;

  NewsApi({
    required this.apiKey,
    this.baseUrl = 'https://newsapi.org/v2/top-headlines',
  });

  /// Get top headlines. You can pass country (default 'us'), category, pageSize.
  Future<NewsApiResponse> getTopHeadlines({
    String country = 'us',
    String? category,
    // int pageSize = 10,
    int page = 1,
  }) async {
    final Map<String, String> query = {
      'apiKey': apiKey,
      'country': country,
      // 'pageSize': pageSize.toString(),
      'page': page.toString(),
    };
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: query);
    /*like  https://newsapi.org/v2/top-headlines?apiKey=39fc8513af0648568fb3d8ca975195d4&country=us&category=general 
  Url */
    final response = await http
        .get(uri)
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
              'Request timed out — please check your connection.',
            );
          },
        );

    if (response.statusCode != 200) {
      // NewsAPI returns helpful body messages; include them for debugging
      final body = response.body.isNotEmpty ? response.body : 'no body';
      throw Exception('NewsAPI request failed (${response.statusCode}): $body');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    if (data['status'] != 'ok') {
      throw Exception('NewsAPI error: ${data['message'] ?? data['status']}');
    }

    final int totalResults = data['totalResults'] ?? 0;
    final List articlesJson = data['articles'] ?? <dynamic>[];
    final List<Article> articles = articlesJson
        .map((a) => Article.fromJson(a as Map<String, dynamic>))
        // filter out entries without a valid URL
        .where((a) => a.url.isNotEmpty)
        .toList();

    return NewsApiResponse(articles: articles, totalResults: totalResults);
  }
}

class Article {
  final String title;
  final String description;
  final String url;
  final String urlToImage;
  final String sourceName;
  final String author;
  final DateTime? publishedAt;

  Article({
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.sourceName,
    required this.author,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    //final source = json['source'] ?? {};
    final source = json['source'];
    String sourceName = '';
    if (source is Map<String, dynamic>) {
      sourceName = (source['name'] ?? '').toString();
    }

    final published = json['publishedAt'];
    DateTime? when;
    if (published != null) {
      when = DateTime.tryParse(published.toString());
    }

    return Article(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      urlToImage: (json['urlToImage'] ?? '').toString(),
      //sourceName: (source['name'] ?? '').toString(),
      sourceName: sourceName,
      author: (json['author'] ?? '').toString(),
      publishedAt: when,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'source': {'name': sourceName},
      'author': author,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}
