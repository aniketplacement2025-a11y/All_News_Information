import 'package:all_news_information_application/auth_service.dart';
import 'package:all_news_information_application/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'news_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  // final NewsApi _newsApi = NewsApi();
  final NewsApi _newsApi = NewsApi(
    apiKey:
        '39fc8513af0648568fb3d8ca975195d4', // <-- replace or pass from main (avoid hardcoding)
  );
  late Future<List<Article>> _articlesFuture;

  String _selectedCategory = 'general';

  final List<String> _categories = [
    'general',
    'entertainment',
    'business',
    'health',
    'science',
    'sports',
    'technology',
  ];

  @override
  void initState() {
    super.initState();
    // _articlesFuture = _newsApi.getTopHeadlines();
    _fetchArticles();
  }

  void _fetchArticles() {
    _articlesFuture = _newsApi.getTopHeadlines(category: _selectedCategory);
  }

  Future<void> _refreshArticles() async {
    setState(() {
      // _articlesFuture = _newsApi.getTopHeadlines();
      _fetchArticles();
    });
    // wait for completion so RefreshIndicator finishes nicely
    await _articlesFuture;
  }

  Future<void> _openArticle(String? url) async {
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No URL available')));
      return;
    }

    // try parse; if no scheme present, prepend https://
    Uri? uri = Uri.tryParse(url);
    if (uri == null || !(uri.hasScheme)) {
      uri = Uri.tryParse('https://$url');
    }

    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the article')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
    }
  }

  Widget _buildImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 56)),
      );
    }

    // Show image with loading/error handlers
    Uri? test = Uri.tryParse(url);
    if (test == null || !test.hasScheme) {
      // not a valid absolute url — show placeholder
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, size: 56)),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        height: 200,
        width: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          (progress.expectedTotalBytes ?? 1)
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image, size: 56)),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            'https://icon.horse/icon/newsapi.org',
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.article); // Fallback icon
            },
          ),
        ),
        title: const Text(
          'All News Information',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedCategory,
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedCategory = newValue;
                  _fetchArticles();
                });
              }
            },
          ),
          //Old Drop Down Button
          // IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
          //New Drop Down Button
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'personal_info':
                  // TODO: Implement navigation to Personal Info screen
                  print('Personal Info selected');
                  break;
                case 'corrections':
                  // TODO: Implement navigation to Corrections screen
                  print('Corrections selected');
                  break;
                case 'sign_out':
                  _signOut();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'personal_info',
                child: Text('Personal Info'),
              ),
              const PopupMenuItem<String>(
                value: 'corrections',
                child: Text('Corrections in Personal Info'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sign_out',
                child: Text('Sign Out'),
              ),
            ],
          ),
        ],
        centerTitle: true,
      ),
      body: FutureBuilder<List<Article>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No articles found.'));
          } else {
            final articles = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refreshArticles,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final article = articles[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 8.0,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openArticle(article.url),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImage(article.urlToImage),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  article.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  article.description.isNotEmpty
                                      ? article.description
                                      : 'No description available.',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (article.sourceName.isNotEmpty)
                                      Text(
                                        article.sourceName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    const Spacer(),
                                    if (article.publishedAt != null)
                                      Text(
                                        // simple formatting: date only
                                        article.publishedAt!
                                            .toLocal()
                                            .toIso8601String()
                                            .split('T')
                                            .first,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
