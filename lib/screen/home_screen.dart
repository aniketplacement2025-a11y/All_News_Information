import 'package:all_news_information_application/service/auth_service.dart';
import 'package:all_news_information_application/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../news_api.dart';
import 'package:all_news_information_application/widget/pagination_controls.dart';
import 'personal_info_screen.dart';
import 'corrections_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  // final NewsApi _newsApi = NewsApi();
  final NewsApi _newsApi = NewsApi(
    apiKey: '39fc8513af0648568fb3d8ca975195d4',
  ); //late Future<List<Article>> _articlesFuture;

  List<Article> _articles = [];
  String _selectedCategory = 'general';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoading = true;
  String? _errorMessage;

  static const int _pageSize = 10;

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

  Future<void> _fetchArticles({bool resetPage = false}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
        _articles = [];
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _newsApi.getTopHeadlines(
        category: _selectedCategory,
        // pageSize: _pageSize,
        page: _currentPage,
      );
      setState(() {
        _articles = response.articles;
        _totalPages = (response.totalResults / _pageSize).ceil();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _refreshArticles() async {
    await _fetchArticles(resetPage: true);
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
              if (newValue != null && newValue != _selectedCategory) {
                setState(() {
                  _selectedCategory = newValue;
                  //_fetchArticles();
                });
                _fetchArticles(resetPage: true);
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
                  //print('Personal Info selected');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PersonalInfoScreen(),
                    ),
                  );
                  break;
                case 'corrections':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CorrectionsScreen(),
                    ),
                  );
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _articles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: $_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return const Center(child: Text('No articles found.'));
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshArticles,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _articles.length,
              itemBuilder: (context, index) {
                final article = _articles[index];
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
          ),
        ),
        //if (!_isLoading) _buildPaginationControls(),
        if (!_isLoading)
          PaginationControls(
            currentPage: _currentPage,
            totalPages: _totalPages,
            onPreviousPage: () {
              setState(() => _currentPage--);
              _fetchArticles();
            },
            onNextPage: () {
              setState(() => _currentPage++);
              _fetchArticles();
            },
          ),
      ],
    );
  }
}

  // Widget _buildPaginationControls() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         ElevatedButton.icon(
  //           onPressed: _currentPage > 1
  //               ? () {
  //                   setState(() => _currentPage--);
  //                   _fetchArticles();
  //                 }
  //               : null,
  //           icon: const Icon(Icons.arrow_back),
  //           label: const Text('Previous'),
  //         ),
  //         Text('Page $_currentPage of $_totalPages'),
  //         ElevatedButton.icon(
  //           onPressed: _currentPage < _totalPages
  //               ? () {
  //                   setState(() => _currentPage++);
  //                   _fetchArticles();
  //                 }
  //               : null,
  //           label: const Text('Next'),
  //           icon: const Icon(Icons.arrow_forward),
  //         ),
  //       ],
  //     ),
  //   );
  // }
