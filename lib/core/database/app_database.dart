// 앱의 단일 SQLite 데이터베이스 클래스. Drift ORM을 사용한다.
// Entries 테이블 CRUD, 월별 조회, 범위 조회, Upsert, 도메인 모델 변환 확장을 제공한다.
// 코드 생성 결과(app_database.g.dart)는 build_runner로 생성하며 직접 수정하지 않는다.

import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poopoolog/core/models/record_model.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// 테이블 정의
// ---------------------------------------------------------------------------

class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  BoolColumn get visited => boolean().nullable()();
  IntColumn get mood => integer().nullable()();
  TextColumn get memo => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ---------------------------------------------------------------------------
// DB 연결
// ---------------------------------------------------------------------------

/// 앱의 유일한 SQLite 데이터베이스 클래스.
/// Drift 코드 생성(_$AppDatabase)을 상속하며 CRUD 메서드를 제공한다.
@DriftDatabase(tables: [Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // ---------------------------------------------------
  // CRUD
  // ---------------------------------------------------

  /// 특정 날짜(date)의 기록을 오름차순으로 반환.
  /// 캘린더 날짜 선택 시 해당 날 기록 목록 표시에 사용된다.
  Future<List<Entry>> getEntriesForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return getEntriesInRange(start, start.add(const Duration(days: 1)));
  }

  /// [from] 이상 [to] 미만 범위의 기록을 오름차순으로 반환.
  /// 타임라인 전체 조회, 통계 기간 조회 등에서 공통으로 사용된다.
  Future<List<Entry>> getEntriesInRange(DateTime from, DateTime to) {
    return (select(entries)
          ..where(
            (e) =>
                e.recordedAt.isBiggerOrEqualValue(from) &
                e.recordedAt.isSmallerThanValue(to),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.recordedAt)]))
        .get();
  }

  /// 월별 기록 Map (캘린더 dot 표시용)
  Future<Map<DateTime, List<Entry>>> getEntriesForMonth(
    int year,
    int month,
  ) async {
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1);
    final rows = await getEntriesInRange(from, to);

    final Map<DateTime, List<Entry>> result = {};
    for (final row in rows) {
      final day = DateTime(
        row.recordedAt.year,
        row.recordedAt.month,
        row.recordedAt.day,
      );
      result.putIfAbsent(day, () => []).add(row);
    }
    return result;
  }

  /// 새 기록을 삽입하고 생성된 id를 반환한다.
  Future<int> insertEntry(EntriesCompanion companion) async {
    try {
      return await into(entries).insert(companion);
    } catch (e, s) {
      developer.log('insertEntry 실패', name: 'AppDatabase', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// companion.id에 해당하는 기록을 전체 교체(replace)한다.
  Future<bool> updateEntry(EntriesCompanion companion) async {
    try {
      return await update(entries).replace(companion);
    } catch (e, s) {
      developer.log('updateEntry 실패', name: 'AppDatabase', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// [id]에 해당하는 기록을 삭제하고 삭제된 행 수를 반환한다.
  Future<int> deleteEntry(int id) async {
    try {
      return await (delete(entries)..where((e) => e.id.equals(id))).go();
    } catch (e, s) {
      developer.log('deleteEntry 실패', name: 'AppDatabase', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// entries 테이블을 DROP 후 재생성하여 모든 데이터와 auto-increment 카운터를 초기화한다.
  Future<void> deleteAllEntries() async {
    await customStatement('DROP TABLE IF EXISTS "entries"');
    await createMigrator().createTable(entries);
  }

  /// recordedAt이 동일한 기록이 있으면 해당 행을 덮어쓰고, 없으면 새로 삽입한다.
  /// CSV 가져오기처럼 중복 없는 upsert가 필요할 때 사용한다.
  Future<void> upsertEntryByTime(EntriesCompanion companion) async {
    try {
      final existing = await (select(entries)
            ..where(
              (e) => e.recordedAt.equals(companion.recordedAt.value),
            ))
          .getSingleOrNull();
      if (existing != null) {
        await (update(entries)..where((e) => e.id.equals(existing.id)))
            .write(companion);
      } else {
        await into(entries).insert(companion);
      }
    } catch (e, s) {
      developer.log(
        'upsertEntryByTime 실패',
        name: 'AppDatabase',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// 가장 오래된 기록의 날짜를 반환한다. 기록이 없으면 null.
  Future<DateTime?> getOldestEntryDate() {
    return (select(entries)
          ..orderBy([(e) => OrderingTerm.asc(e.recordedAt)])
          ..limit(1))
        .getSingleOrNull()
        .then((e) => e?.recordedAt);
  }
}

// ---------------------------------------------------------------------------
// DB 파일 경로
// ---------------------------------------------------------------------------

/// 앱 문서 디렉토리에 poopoolog.sqlite 파일을 생성·연결한다.
/// 백그라운드 isolate에서 열어 UI 스레드 블로킹을 방지한다.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'poopoolog.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// ---------------------------------------------------------------------------
// Entry Row → RecordModel 변환
// ---------------------------------------------------------------------------

extension EntryMapper on Entry {
  /// Drift Entry 행을 앱 도메인 모델 RecordModel로 변환한다.
  RecordModel toModel() => RecordModel(
    id: id,
    recordedAt: recordedAt,
    visited: visited,
    mood: mood != null ? MoodLevel.values[mood!] : null,
    memo: memo,
    createdAt: createdAt,
  );
}

extension RecordModelMapper on RecordModel {
  /// RecordModel을 Drift insert/update 에 사용하는 EntriesCompanion으로 변환한다.
  /// id가 0이면 신규 삽입으로 판단해 Value.absent()를 사용한다.
  EntriesCompanion toCompanion() => EntriesCompanion(
    id: id == 0 ? const Value.absent() : Value(id),
    recordedAt: Value(recordedAt),
    visited: Value(visited),
    mood: Value(mood?.index),
    memo: Value(memo),
  );
}
