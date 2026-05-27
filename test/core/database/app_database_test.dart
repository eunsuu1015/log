// AppDatabase 단위 테스트
//
// 테스트 전략:
// • NativeDatabase.memory() 기반 인메모리 DB 사용 — 파일 I/O 없음
// • deleteAllEntries() — DROP + 재생성 방식이므로
//   데이터 삭제, INSERT 정상 동작, auto-increment 리셋 세 가지를 검증
// ---------------------------------------------------------------------------

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<int> _insert(AppDatabase db, {DateTime? recordedAt}) async {
  return db.insertEntry(
    EntriesCompanion(recordedAt: Value(recordedAt ?? DateTime.now())),
  );
}

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

void main() {
  group('upsertEntryByTime()', () {
    late AppDatabase db;

    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('동일 recordedAt 없으면 새 행 삽입된다', () async {
      final t = DateTime(2026, 1, 1, 9, 0);
      await db.upsertEntryByTime(
        EntriesCompanion(
          recordedAt: Value(t),
          visited: const Value(true),
          mood: const Value(0),
        ),
      );
      final rows = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(rows.length, 1);
      expect(rows.first.visited, true);
      expect(rows.first.mood, 0);
    });

    test('동일 recordedAt 있으면 기존 행을 덮어쓴다', () async {
      final t = DateTime(2026, 1, 1, 9, 0);
      await db.upsertEntryByTime(
        EntriesCompanion(
          recordedAt: Value(t),
          visited: const Value(true),
          mood: const Value(0),
          memo: const Value('초기 메모'),
        ),
      );
      await db.upsertEntryByTime(
        EntriesCompanion(
          recordedAt: Value(t),
          visited: const Value(false),
          mood: const Value(2),
          memo: const Value('수정된 메모'),
        ),
      );
      final rows = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(rows.length, 1); // 중복 삽입 없음
      expect(rows.first.visited, false);
      expect(rows.first.mood, 2);
      expect(rows.first.memo, '수정된 메모');
    });

    test('다른 recordedAt이면 별개 행으로 삽입된다', () async {
      final t1 = DateTime(2026, 1, 1, 9, 0);
      final t2 = DateTime(2026, 1, 1, 14, 0);
      await db.upsertEntryByTime(
        EntriesCompanion(recordedAt: Value(t1), visited: const Value(true)),
      );
      await db.upsertEntryByTime(
        EntriesCompanion(recordedAt: Value(t2), visited: const Value(false)),
      );
      final rows = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(rows.length, 2);
    });

    test('null 컬럼(버전 호환) — mood·memo가 없어도 삽입된다', () async {
      final t = DateTime(2026, 3, 1, 8, 0);
      await db.upsertEntryByTime(
        EntriesCompanion(
          recordedAt: Value(t),
          visited: const Value(null),
          mood: const Value(null),
          memo: const Value(null),
        ),
      );
      final rows = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(rows.length, 1);
      expect(rows.first.mood, isNull);
      expect(rows.first.memo, isNull);
    });
  });

  group('deleteAllEntries()', () {
    late AppDatabase db;

    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('기록이 있을 때 호출하면 테이블이 비어있다', () async {
      await _insert(db);
      await _insert(db);

      await db.deleteAllEntries();

      final entries = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(entries, isEmpty);
    });

    test('빈 테이블에서 호출해도 예외 없이 완료된다', () async {
      await expectLater(db.deleteAllEntries(), completes);
    });

    test('초기화 후 INSERT가 정상 동작한다', () async {
      await _insert(db);
      await db.deleteAllEntries();

      final id = await _insert(db, recordedAt: DateTime(2026, 1, 1));

      final entries = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(entries.length, 1);
      expect(entries.first.id, id);
    });

    test('초기화 후 auto-increment ID가 1부터 다시 시작한다', () async {
      // 먼저 여러 건 삽입해 ID를 높여 놓음
      await _insert(db);
      await _insert(db);
      await _insert(db);

      await db.deleteAllEntries();

      final newId = await _insert(db);
      expect(newId, 1);
    });
  });
}
