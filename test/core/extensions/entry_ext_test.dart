// EntryX·MoodLevelX 확장 단위 테스트
// moodColor·moodLabel·timeStr 변환 로직이 visited·mood 조합별로 올바른 값을 반환하는지 검증한다.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/database/app_database.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// 헬퍼
// ---------------------------------------------------------------------------

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

Future<Entry> _insertEntry(
  AppDatabase db, {
  required DateTime recordedAt,
  bool? visited,
  int? mood,
}) async {
  await db.insertEntry(EntriesCompanion(
    recordedAt: Value(recordedAt),
    visited: Value(visited),
    mood: Value(mood),
  ));
  return (await db.getEntriesInRange(DateTime(2000), DateTime(2200))).last;
}

// ---------------------------------------------------------------------------
// 테스트
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final base = DateTime(2026, 5, 1, 9, 0);

  // ─────────────────────────────────────────────────────────────────────────
  // MoodLevelX.color
  // ─────────────────────────────────────────────────────────────────────────

  group('MoodLevelX.color', () {
    test('good → moodGood (#3DA06C)', () {
      expect(MoodLevel.good.color, AppTheme.moodGood);
    });
    test('okay → moodOkay (#CC7D30)', () {
      expect(MoodLevel.okay.color, AppTheme.moodOkay);
    });
    test('bad → moodBad (#C64848)', () {
      expect(MoodLevel.bad.color, AppTheme.moodBad);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // MoodLevelX.label
  // ─────────────────────────────────────────────────────────────────────────

  group('MoodLevelX.label', () {
    test('good → "좋음"', () => expect(MoodLevel.good.label, '좋음'));
    test('okay → "보통"', () => expect(MoodLevel.okay.label, '보통'));
    test('bad → "나쁨"', () => expect(MoodLevel.bad.label, '나쁨'));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // EntryX.moodColor
  // ─────────────────────────────────────────────────────────────────────────

  group('EntryX.moodColor', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('visited=null → moodNone', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: null);
      expect(e.moodColor, AppTheme.moodNone);
    });

    test('visited=false → moodNotVisited', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: false);
      expect(e.moodColor, AppTheme.moodNotVisited);
    });

    test('visited=true + mood=null → moodNone', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: true, mood: null);
      expect(e.moodColor, AppTheme.moodNone);
    });

    test('visited=true + mood=0(good) → moodGood', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: true, mood: 0);
      expect(e.moodColor, AppTheme.moodGood);
    });

    test('visited=true + mood=1(okay) → moodOkay', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: true, mood: 1);
      expect(e.moodColor, AppTheme.moodOkay);
    });

    test('visited=true + mood=2(bad) → moodBad', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: true, mood: 2);
      expect(e.moodColor, AppTheme.moodBad);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // EntryX.moodLabel
  // ─────────────────────────────────────────────────────────────────────────

  group('EntryX.moodLabel', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('visited=null → "-"', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: null);
      expect(e.moodLabel, '-');
    });

    test('visited=false → "안 감"', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: false);
      expect(e.moodLabel, '안 감');
    });

    test('visited=true + mood=null → "다녀옴"', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: true, mood: null);
      expect(e.moodLabel, '다녀옴');
    });

    test('visited=true + mood=0 → "좋음"', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: true, mood: 0);
      expect(e.moodLabel, '좋음');
    });

    test('visited=true + mood=1 → "보통"', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: true, mood: 1);
      expect(e.moodLabel, '보통');
    });

    test('visited=true + mood=2 → "나쁨"', () async {
      final e = await _insertEntry(db, recordedAt: base, visited: true, mood: 2);
      expect(e.moodLabel, '나쁨');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // EntryX.timeStr — "오전/오후 H:mm" 형식
  // ─────────────────────────────────────────────────────────────────────────

  group('EntryX.timeStr', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('오전 9:05 → "오전 9:05"', () async {
      final e = await _insertEntry(db, recordedAt: DateTime(2026, 5, 1, 9, 5));
      expect(e.timeStr, '오전 9:05');
    });

    test('자정 0:00 → "오전 12:00"', () async {
      final e = await _insertEntry(db, recordedAt: DateTime(2026, 5, 1, 0, 0));
      expect(e.timeStr, '오전 12:00');
    });

    test('정오 12:00 → "오후 12:00"', () async {
      final e = await _insertEntry(db, recordedAt: DateTime(2026, 5, 1, 12, 0));
      expect(e.timeStr, '오후 12:00');
    });

    test('오후 1:30 → "오후 1:30"', () async {
      final e = await _insertEntry(db, recordedAt: DateTime(2026, 5, 1, 13, 30));
      expect(e.timeStr, '오후 1:30');
    });

    test('오후 11:59 → "오후 11:59"', () async {
      final e = await _insertEntry(db, recordedAt: DateTime(2026, 5, 1, 23, 59));
      expect(e.timeStr, '오후 11:59');
    });

    test('분이 한 자리 → 0 패딩 "오전 9:05"', () async {
      final e = await _insertEntry(db, recordedAt: DateTime(2026, 5, 1, 9, 5));
      expect(e.timeStr, '오전 9:05');
    });
  });
}
