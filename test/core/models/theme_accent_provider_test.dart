import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/models/theme_accent_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeAccentX', () {
    test('모든 색상이 고유한 한글 라벨을 가진다', () {
      final labels = ThemeAccent.values.map((a) => a.label).toSet();
      expect(labels.length, ThemeAccent.values.length);
    });

    test('green의 라이트·다크 primary는 기존 AppColors 값과 동일하다', () {
      expect(ThemeAccent.green.lightPrimary, const Color(0xFF2D6A4F));
      expect(ThemeAccent.green.darkPrimary, const Color(0xFF74C19A));
    });

    test('모든 색상의 primary는 완전 불투명하다 (alpha 손실 방지)', () {
      for (final accent in ThemeAccent.values) {
        expect(accent.lightPrimary.a, 1.0);
        expect(accent.darkPrimary.a, 1.0);
      }
    });

    test('검정의 스와치는 조정된 primary 대신 순흑을 보여준다', () {
      expect(ThemeAccent.black.swatchColor, Colors.black);
      expect(ThemeAccent.black.lightPrimary, isNot(Colors.black));
    });

    test('회색의 스와치는 조정 없이 lightPrimary(진회색) 그대로 보여준다', () {
      expect(ThemeAccent.gray.swatchColor, ThemeAccent.gray.lightPrimary);
      expect(ThemeAccent.gray.swatchColor, isNot(Colors.white));
    });

    test('검정을 제외한 나머지 색상의 스와치는 lightPrimary와 동일하다', () {
      for (final accent in ThemeAccent.values) {
        if (accent == ThemeAccent.black) continue;
        expect(accent.swatchColor, accent.lightPrimary);
      }
    });

    test('요청된 10개 색상이 모두 정의되어 있다', () {
      const expectedLabels = {
        '빨강',
        '주황',
        '노랑',
        '초록',
        '하늘',
        '파랑',
        '남색',
        '보라',
        '회색',
        '검정',
      };
      final actualLabels = ThemeAccent.values.map((a) => a.label).toSet();
      expect(actualLabels, expectedLabels);
    });
  });

  group('loadThemeAccent / saveThemeAccent', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('저장된 값이 없으면 green을 반환한다', () async {
      final result = await loadThemeAccent();
      expect(result, ThemeAccent.green);
    });

    test('저장 후 동일한 값을 읽어온다', () async {
      await saveThemeAccent(ThemeAccent.purple);
      final result = await loadThemeAccent();
      expect(result, ThemeAccent.purple);
    });

    test('범위를 벗어난 인덱스가 저장돼 있으면 green으로 폴백한다', () async {
      SharedPreferences.setMockInitialValues({'theme_accent': 999});
      final result = await loadThemeAccent();
      expect(result, ThemeAccent.green);
    });
  });
}
