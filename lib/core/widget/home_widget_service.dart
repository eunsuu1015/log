// Android 홈 화면 위젯 데이터 갱신 서비스.
// 기록 저장·삭제 후 오늘 통계를 SharedPreferences에 저장하고 위젯 리드로를 요청한다.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:home_widget/home_widget.dart';

import '../database/app_database.dart';
import '../extensions/entry_ext.dart';

/// 기록 저장·삭제 후 홈 화면 위젯 데이터를 SharedPreferences에 저장하고
/// Android 위젯 갱신을 요청한다.
class HomeWidgetService {
  static const _receiverSmall =
      'com.tistory.es1015.poopoolog.widget.PooPooWidgetReceiver';
  static const _receiverMedium =
      'com.tistory.es1015.poopoolog.widget.PooPooWidgetMediumReceiver';

  /// 오늘 기록을 DB에서 조회해 홈 위젯 SharedPreferences를 갱신하고
  /// Android 위젯 리드로를 요청한다. 기록 저장·삭제 후 fire-and-forget으로 호출한다.
  static Future<void> update(AppDatabase db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entries =
        await db.getEntriesInRange(today, today.add(const Duration(days: 1)));
    final data = buildData(entries, now);

    await Future.wait([
      HomeWidget.saveWidgetData('visit_count', data.visitCount),
      HomeWidget.saveWidgetData('last_time', data.lastTime),
      HomeWidget.saveWidgetData('last_mood_color', data.lastMoodColor),
      HomeWidget.saveWidgetData('today_records', data.todayRecords),
    ]);

    await Future.wait([
      HomeWidget.updateWidget(qualifiedAndroidName: _receiverSmall),
      HomeWidget.updateWidget(qualifiedAndroidName: _receiverMedium),
    ]);
  }

  /// 오늘 기록 목록으로부터 위젯 표시 데이터를 계산한다.
  /// 테스트에서 직접 호출 가능하도록 별도 메서드로 분리한다.
  @visibleForTesting
  static WidgetData buildData(List<Entry> entries, DateTime now) {
    final visits = entries.where((e) => e.visited == true).toList();
    final last = visits.isNotEmpty ? visits.last : null;

    return WidgetData(
      visitCount: '${visits.length}',
      lastTime: last != null ? _timeStr(last) : '',
      lastMoodColor: last != null ? _hex(last.moodColor) : '',
      todayRecords: visits.map((e) => '${_timeStr(e)}|${_hex(e.moodColor)}').join(','),
    );
  }

  static String _timeStr(Entry e) {
    final h = e.recordedAt.hour.toString().padLeft(2, '0');
    final m = e.recordedAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _hex(Color c) {
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}

/// [HomeWidgetService.buildData]의 반환 타입.
class WidgetData {
  /// 오늘 방문(visited=true) 횟수 문자열.
  final String visitCount;

  /// 마지막 방문 시각 "HH:mm". 방문 없으면 빈 문자열.
  final String lastTime;

  /// 마지막 방문 기분 색상 hex. 방문 없으면 빈 문자열.
  final String lastMoodColor;

  /// 오늘 방문 기록 전체. "HH:mm|#COLOR" 형식을 콤마로 구분. 방문 없으면 빈 문자열.
  final String todayRecords;

  const WidgetData({
    required this.visitCount,
    required this.lastTime,
    required this.lastMoodColor,
    required this.todayRecords,
  });
}
