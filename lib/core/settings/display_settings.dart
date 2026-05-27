// 캘린더 표시 설정 Provider.
// 주 시작 요일(일요일/월요일)을 SharedPreferences에 저장하고 앱 시작 시 main.dart에서 초기값을 주입한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 캘린더 시작 요일: true = 일요일(기본), false = 월요일
const kStartWeekdaySundayKey = 'start_weekday_sunday';
final startWeekdaySundayProvider = StateProvider<bool>((_) => true);
