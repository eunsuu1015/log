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
  static const _receiverName =
      'com.tistory.es1015.poopoolog.widget.PooPooWidgetReceiver';

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
      HomeWidget.saveWidgetData('last_mood_label', data.lastMoodLabel),
      HomeWidget.saveWidgetData('last_mood_color', data.lastMoodColor),
      HomeWidget.saveWidgetData('today_dots', data.todayDots),
      HomeWidget.saveWidgetData('date_label', data.dateLabel),
    ]);

    await HomeWidget.updateWidget(qualifiedAndroidName: _receiverName);
  }

  /// 오늘 기록 목록으로부터 위젯 표시 데이터를 계산한다.
  /// 테스트에서 직접 호출 가능하도록 별도 메서드로 분리한다.
  @visibleForTesting
  static WidgetData buildData(List<Entry> entries, DateTime now) {
    final visits = entries.where((e) => e.visited == true).toList();
    final last = visits.isNotEmpty ? visits.last : null;

    return WidgetData(
      visitCount: '${visits.length}',
      lastTime: last != null
          ? '${last.recordedAt.hour.toString().padLeft(2, '0')}:${last.recordedAt.minute.toString().padLeft(2, '0')}'
          : '',
      lastMoodLabel: last?.moodLabel ?? '',
      lastMoodColor: last != null ? _hex(last.moodColor) : '',
      todayDots: visits.map((e) => _hex(e.moodColor)).join(','),
      dateLabel: '${now.month}/${now.day}',
    );
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
  final String visitCount;
  final String lastTime;
  final String lastMoodLabel;
  final String lastMoodColor;
  final String todayDots;
  final String dateLabel;

  const WidgetData({
    required this.visitCount,
    required this.lastTime,
    required this.lastMoodLabel,
    required this.lastMoodColor,
    required this.todayDots,
    required this.dateLabel,
  });
}
