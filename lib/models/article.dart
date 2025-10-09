import 'package:hive/hive.dart';

part 'article.g.dart';

@HiveType(typeId: 0)
class Article extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String urlToImage;

  @HiveField(4)
  final String sourceName;

  @HiveField(5)
  final String author;

  @HiveField(6)
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