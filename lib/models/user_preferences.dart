import 'package:hive/hive.dart';

part 'user_preferences.g.dart';

@HiveType(typeId: 1)
class UserPreferences extends HiveObject {
  @HiveField(0)
  String? lastSelectedCategory;

  UserPreferences({this.lastSelectedCategory});
}
