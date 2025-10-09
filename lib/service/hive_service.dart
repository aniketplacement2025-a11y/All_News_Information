import 'package:hive_flutter/hive_flutter.dart';
import '../models/article.dart';
import '../models/auth_cache.dart';
import '../models/user_preferences.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ArticleAdapter());
    Hive.registerAdapter(UserPreferencesAdapter());
    Hive.registerAdapter(CachedUserAdapter());
    Hive.registerAdapter(CachedSessionAdapter());

    // Open boxes
    await Hive.openBox('auth_cache');
    await Hive.openBox('user_preferences');
    await Hive.openBox('news_cache');
  }

  static Future<void> close() async {
    await Hive.close();
  }
}
