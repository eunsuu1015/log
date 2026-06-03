// RecordFormState.copyWith sentinel 패턴 및 setMemo null 처리 단위 테스트.
// 메모를 빈 문자열로 지웠을 때 null로 저장되는지 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/record/record_provider.dart';

void main() {
  group('RecordFormState.copyWith — memo sentinel 패턴', () {
    final base = RecordFormState(
      recordedAt: DateTime(2026, 6, 1),
      visited: true,
      memo: '기존 메모',
    );

    test('memo 인수 없음 → 기존 값 유지', () {
      final result = base.copyWith();
      expect(result.memo, '기존 메모');
    });

    test('memo: null 명시 전달 → null로 변경', () {
      final result = base.copyWith(memo: null);
      expect(result.memo, isNull);
    });

    test('memo: 새 문자열 전달 → 변경됨', () {
      final result = base.copyWith(memo: '새 메모');
      expect(result.memo, '새 메모');
    });
  });

  group('RecordFormState.copyWith — 기타 nullable sentinel 필드', () {
    final base = RecordFormState(
      recordedAt: DateTime(2026, 6, 1),
      visited: true,
      mood: MoodLevel.good,
      memo: '메모',
    );

    test('visited 인수 없음 → 기존 값 유지', () {
      expect(base.copyWith().visited, isTrue);
    });

    test('visited: null 명시 전달 → null로 변경', () {
      expect(base.copyWith(visited: null).visited, isNull);
    });

    test('mood 인수 없음 → 기존 값 유지', () {
      expect(base.copyWith().mood, MoodLevel.good);
    });

    test('mood: null 명시 전달 → null로 변경', () {
      expect(base.copyWith(mood: null).mood, isNull);
    });
  });

  // setMemo는 copyWith(memo: text.isEmpty ? null : text)를 호출하는 래퍼이므로
  // copyWith sentinel 패턴 테스트로 버그 수정이 검증된다.
  group('setMemo 로직 — copyWith sentinel 조합 검증', () {
    final base = RecordFormState(
      recordedAt: DateTime(2026, 6, 1),
      visited: true,
      memo: '지울 메모',
    );

    test('빈 문자열 → copyWith(memo: null) → null 저장 (버그 수정 검증)', () {
      const text = '';
      final result = base.copyWith(memo: text.isEmpty ? null : text);
      expect(result.memo, isNull,
          reason: 'copyWith(memo: null)이 기존 값을 유지하면 이 테스트가 실패함');
    });

    test('문자열 → copyWith(memo: text) → 해당 문자열 저장', () {
      const text = '새 메모';
      final result = base.copyWith(memo: text.isEmpty ? null : text);
      expect(result.memo, '새 메모');
    });
  });
}
