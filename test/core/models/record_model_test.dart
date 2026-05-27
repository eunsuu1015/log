// RecordModel 단위 테스트
// copyWith sentinel 패턴(nullable 필드 명시적 null 설정)과 == 연산자를 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/models/record_model.dart';

void main() {
  final base = RecordModel(
    id: 1,
    recordedAt: DateTime(2026, 5, 1, 9, 0),
    visited: true,
    mood: MoodLevel.good,
    memo: '테스트 메모',
    createdAt: DateTime(2026, 5, 1, 9, 0),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // copyWith — no-op
  // ─────────────────────────────────────────────────────────────────────────

  group('copyWith — 변경 없음', () {
    test('인수 없이 호출하면 원본과 동일한 값', () {
      final copy = base.copyWith();
      expect(copy.id, base.id);
      expect(copy.recordedAt, base.recordedAt);
      expect(copy.visited, base.visited);
      expect(copy.mood, base.mood);
      expect(copy.memo, base.memo);
      expect(copy.createdAt, base.createdAt);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // copyWith — non-nullable 필드 변경
  // ─────────────────────────────────────────────────────────────────────────

  group('copyWith — non-nullable 필드 변경', () {
    test('id 변경', () {
      final copy = base.copyWith(id: 99);
      expect(copy.id, 99);
      expect(copy.recordedAt, base.recordedAt); // 나머지는 유지
    });

    test('recordedAt 변경', () {
      final newDate = DateTime(2026, 6, 15, 14, 30);
      final copy = base.copyWith(recordedAt: newDate);
      expect(copy.recordedAt, newDate);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // copyWith — nullable 필드 변경 (sentinel 패턴)
  // ─────────────────────────────────────────────────────────────────────────

  group('copyWith — nullable 필드 변경', () {
    test('visited 값 변경 (true → false)', () {
      final copy = base.copyWith(visited: false);
      expect(copy.visited, false);
    });

    test('visited를 명시적으로 null 설정', () {
      final copy = base.copyWith(visited: null);
      expect(copy.visited, isNull);
    });

    test('mood 변경 (good → bad)', () {
      final copy = base.copyWith(mood: MoodLevel.bad);
      expect(copy.mood, MoodLevel.bad);
    });

    test('mood를 명시적으로 null 설정', () {
      final copy = base.copyWith(mood: null);
      expect(copy.mood, isNull);
    });

    test('memo 변경', () {
      final copy = base.copyWith(memo: '새 메모');
      expect(copy.memo, '새 메모');
    });

    test('memo를 명시적으로 null 설정', () {
      final copy = base.copyWith(memo: null);
      expect(copy.memo, isNull);
    });

    test('sentinel: visited 미지정 → 기존 값 유지', () {
      // visited를 인수로 넘기지 않으면 sentinel이 작동해 기존 값 보존
      final copy = base.copyWith(id: 2);
      expect(copy.visited, base.visited);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // == 연산자 (id + recordedAt 기준)
  // ─────────────────────────────────────────────────────────────────────────

  group('== 연산자', () {
    test('id·recordedAt 동일하면 equal', () {
      final other = RecordModel(
        id: 1,
        recordedAt: DateTime(2026, 5, 1, 9, 0),
        visited: false, // 다른 필드
        mood: MoodLevel.bad,
        memo: null,
        createdAt: DateTime(2026, 5, 1),
      );
      expect(base == other, isTrue);
    });

    test('id가 다르면 not equal', () {
      final other = base.copyWith(id: 2);
      expect(base == other, isFalse);
    });

    test('recordedAt이 다르면 not equal', () {
      final other = base.copyWith(recordedAt: DateTime(2026, 5, 2, 9, 0));
      expect(base == other, isFalse);
    });

    test('동일 인스턴스는 equal', () {
      expect(base == base, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // hashCode
  // ─────────────────────────────────────────────────────────────────────────

  group('hashCode', () {
    test('equal한 두 객체는 hashCode도 동일', () {
      final other = RecordModel(
        id: 1,
        recordedAt: DateTime(2026, 5, 1, 9, 0),
        visited: null,
        mood: null,
        memo: null,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(base.hashCode, other.hashCode);
    });
  });
}
