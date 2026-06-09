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

  // ─────────────────────────────────────────────────────────────────────────
  // insertEntry()
  // ─────────────────────────────────────────────────────────────────────────

  group('insertEntry()', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('삽입 후 조회하면 동일 행이 반환된다', () async {
      final t = DateTime(2026, 3, 15, 9, 0);
      final id = await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(t),
          visited: const Value(true),
          mood: const Value(0),
          memo: const Value('테스트'),
        ),
      );
      final rows = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(rows.length, 1);
      expect(rows.first.id, id);
      expect(rows.first.visited, true);
      expect(rows.first.mood, 0);
      expect(rows.first.memo, '테스트');
    });

    test('반환된 id는 1 이상의 정수', () async {
      final id = await _insert(db);
      expect(id, greaterThanOrEqualTo(1));
    });

    test('여러 건 삽입 시 id가 순증가한다', () async {
      final id1 = await _insert(db, recordedAt: DateTime(2026, 1, 1));
      final id2 = await _insert(db, recordedAt: DateTime(2026, 1, 2));
      expect(id2, greaterThan(id1));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // updateEntry()
  // ─────────────────────────────────────────────────────────────────────────

  group('updateEntry()', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('기존 행을 수정하면 변경된 값이 조회된다', () async {
      final id = await db.insertEntry(
        EntriesCompanion(
          recordedAt: Value(DateTime(2026, 3, 1, 9, 0)),
          visited: const Value(true),
          mood: const Value(0),
          memo: const Value('원본'),
        ),
      );
      await db.updateEntry(
        EntriesCompanion(
          id: Value(id),
          recordedAt: Value(DateTime(2026, 3, 1, 9, 0)),
          visited: const Value(false),
          mood: const Value(2),
          memo: const Value('수정됨'),
        ),
      );
      final rows = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(rows.length, 1);
      expect(rows.first.visited, false);
      expect(rows.first.mood, 2);
      expect(rows.first.memo, '수정됨');
    });

    test('수정 성공 시 true 반환', () async {
      final id = await _insert(db);
      final result = await db.updateEntry(
        EntriesCompanion(
          id: Value(id),
          recordedAt: Value(DateTime.now()),
          visited: const Value(true),
        ),
      );
      expect(result, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // deleteEntry()
  // ─────────────────────────────────────────────────────────────────────────

  group('deleteEntry()', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('삽입 후 삭제하면 목록에서 제거된다', () async {
      final id = await _insert(db);
      await db.deleteEntry(id);
      final rows = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(rows, isEmpty);
    });

    test('삭제 성공 시 반환값 1', () async {
      final id = await _insert(db);
      final count = await db.deleteEntry(id);
      expect(count, 1);
    });

    test('존재하지 않는 id 삭제 시 반환값 0', () async {
      final count = await db.deleteEntry(9999);
      expect(count, 0);
    });

    test('2건 중 1건 삭제 후 나머지 1건 유지', () async {
      final id1 = await _insert(db, recordedAt: DateTime(2026, 1, 1));
      await _insert(db, recordedAt: DateTime(2026, 1, 2));
      await db.deleteEntry(id1);
      final rows = await db.getEntriesInRange(DateTime(2000), DateTime(2200));
      expect(rows.length, 1);
      expect(rows.first.id, isNot(id1));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // getEntriesInRange() — 경계값
  // ─────────────────────────────────────────────────────────────────────────

  group('getEntriesInRange() — 경계값', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('from 경계: recordedAt == from 이면 포함된다', () async {
      final from = DateTime(2026, 5, 1, 0, 0);
      await db.insertEntry(EntriesCompanion(recordedAt: Value(from)));
      final rows = await db.getEntriesInRange(from, DateTime(2026, 5, 2));
      expect(rows.length, 1);
    });

    test('to 경계: recordedAt == to 이면 제외된다 (exclusive end)', () async {
      final to = DateTime(2026, 5, 2, 0, 0);
      await db.insertEntry(EntriesCompanion(recordedAt: Value(to)));
      final rows = await db.getEntriesInRange(DateTime(2026, 5, 1), to);
      expect(rows, isEmpty);
    });

    test('to 바로 1초 전은 포함된다', () async {
      final justBefore = DateTime(2026, 5, 1, 23, 59, 59);
      final to = DateTime(2026, 5, 2, 0, 0);
      await db.insertEntry(EntriesCompanion(recordedAt: Value(justBefore)));
      final rows = await db.getEntriesInRange(DateTime(2026, 5, 1), to);
      expect(rows.length, 1);
    });

    test('from 1초 전은 제외된다', () async {
      final justBefore = DateTime(2026, 4, 30, 23, 59, 59);
      final from = DateTime(2026, 5, 1, 0, 0);
      await db.insertEntry(EntriesCompanion(recordedAt: Value(justBefore)));
      final rows = await db.getEntriesInRange(from, DateTime(2026, 5, 2));
      expect(rows, isEmpty);
    });

    test('범위 밖 기록은 반환되지 않는다', () async {
      await _insert(db, recordedAt: DateTime(2026, 3, 1)); // 범위 전
      await _insert(db, recordedAt: DateTime(2026, 5, 15)); // 범위 내
      await _insert(db, recordedAt: DateTime(2026, 7, 1)); // 범위 후
      final rows = await db.getEntriesInRange(
        DateTime(2026, 5, 1),
        DateTime(2026, 6, 1),
      );
      expect(rows.length, 1);
    });

    test('반환 결과는 recordedAt 오름차순', () async {
      await _insert(db, recordedAt: DateTime(2026, 5, 3));
      await _insert(db, recordedAt: DateTime(2026, 5, 1));
      await _insert(db, recordedAt: DateTime(2026, 5, 2));
      final rows = await db.getEntriesInRange(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 4),
      );
      expect(rows[0].recordedAt.day, 1);
      expect(rows[1].recordedAt.day, 2);
      expect(rows[2].recordedAt.day, 3);
    });
  });
}
