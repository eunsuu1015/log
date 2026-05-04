import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/database/app_database.dart';

/// 앱 전역 단일 AppDatabase 인스턴스를 제공하는 Provider.
/// Provider가 dispose될 때 DB 연결을 닫는다.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
