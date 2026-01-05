import 'package:hive/hive.dart';

part 'auth_cache.g.dart';

@HiveType(typeId: 2)
class CachedUser extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final DateTime createdAt;

  CachedUser({required this.id, required this.email, required this.createdAt});
}

@HiveType(typeId: 3)
class CachedSession extends HiveObject {
  @HiveField(0)
  final String accessToken;

  @HiveField(1)
  final String refreshToken;

  @HiveField(2)
  final int expiresIn;

  @HiveField(3)
  final CachedUser user;

  CachedSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });
}
