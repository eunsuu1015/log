// 기분 표시 방식(도트/이모지 얼굴) Provider.
// SharedPreferences에 저장하고 앱 시작 시 main.dart에서 초기값을 주입한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kMoodDisplayKey = 'mood_display';

/// 기분 표시 방식
enum MoodDisplay { dot, face }

/// 기분 표시 방식 Provider. main.dart에서 초기값을 SharedPreferences로 주입한다.
final moodDisplayProvider = StateProvider<MoodDisplay>((_) => MoodDisplay.dot);

/// SharedPreferences에서 저장된 기분 표시 방식을 읽어온다.
Future<MoodDisplay> loadMoodDisplay() async {
  final prefs = await SharedPreferences.getInstance();
  final index = prefs.getInt(_kMoodDisplayKey);
  if (index == null || index >= MoodDisplay.values.length) {
    return MoodDisplay.dot;
  }
  return MoodDisplay.values[index];
}

/// SharedPreferences에 기분 표시 방식을 저장한다.
Future<void> saveMoodDisplay(MoodDisplay display) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kMoodDisplayKey, display.index);
}
