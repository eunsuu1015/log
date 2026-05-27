// 캘린더 탭의 상태 Provider 모음.
// 포커스된 달·선택된 날짜·월별 기록 Map·최초 기록일을 관리한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

/// 가장 오래된 기록의 날짜. 기록이 없으면 null.
/// 캘린더 firstDay, 바텀시트 minDate, 빈 화면 판단에 사용된다.
final earliestEntryDateProvider = FutureProvider<DateTime?>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  return db.getOldestEntryDate();
});

/// 캘린더에서 현재 보고 있는 달 (연-월만 사용, 초기값 = 이번 달)
final calendarFocusedMonthProvider = StateProvider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

/// 지정된 달의 기록을 날짜 키로 그룹화한 Map. 캘린더 도트 표시에 사용된다.
final monthlyEntriesProvider =
    FutureProvider.family<Map<DateTime, List<Entry>>, DateTime>((
      ref,
      month,
    ) async {
      final db = ref.watch(appDatabaseProvider);
      return db.getEntriesForMonth(month.year, month.month);
    });

/// 캘린더에서 현재 선택된 날짜 (초기값 = 오늘)
final selectedDayProvider = StateProvider<DateTime?>((_) => DateTime.now());
