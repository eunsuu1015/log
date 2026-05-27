// 기본 스모크 테스트 — AppTheme이 올바르게 생성되는지 확인한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

void main() {
  test('AppTheme 라이트·다크 테마 생성 성공', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.brightness, isNotNull);
    expect(dark.brightness, isNotNull);
  });
}
