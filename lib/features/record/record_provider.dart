// 기록 입력·수정 화면의 폼 상태 관리 Provider.
// RecordFormState(불변 값 객체)와 RecordFormNotifier(상태 변이·저장·삭제)로 구성된다.

// ---------------------------------------------------------------------------
// 폼 상태 모델
// ---------------------------------------------------------------------------

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/models/record_model.dart';

const _s = Object();

/// 기록 폼의 현재 입력 상태를 닿는 불변 값 객체
class RecordFormState {
  final DateTime recordedAt;
  final bool? visited;
  final MoodLevel? mood;
  final String? memo;
  final bool isSaving;

  RecordFormState({
    required this.recordedAt,
    this.visited,
    this.mood,
    this.memo,
    this.isSaving = false,
  });

  RecordFormState copyWith({
    DateTime? recordedAt,
    Object? visited = _s,
    Object? mood = _s,
    String? memo,
    bool? isSaving,
  }) => RecordFormState(
    recordedAt: recordedAt ?? this.recordedAt,
    visited: visited == _s ? this.visited : visited as bool?,
    mood: mood == _s ? this.mood : mood as MoodLevel?,
    memo: memo ?? this.memo,
    isSaving: isSaving ?? this.isSaving,
  );
}

// ---------------------------------------------------------------------------
// FamilyNotifier
// ---------------------------------------------------------------------------

/// 폼 상태 변이(set*)와 DB 저장·삭제를 담당하는 Notifier.
/// arg(Entry?)가 null이면 신규 생성, 값이 있으면 수정 모드로 초기화된다.
class RecordFormNotifier extends FamilyNotifier<RecordFormState, Entry?> {
  Entry? get existingEntry => arg;

  @override
  RecordFormState build(Entry? arg) {
    if (arg != null) {
      return RecordFormState(
        recordedAt: arg.recordedAt,
        visited: arg.visited,
        mood: arg.mood != null ? MoodLevel.values[arg.mood!] : null,
        memo: arg.memo,
      );
    }
    return RecordFormState(recordedAt: DateTime.now());
  }

  /// 기록 날짜·시간을 변경한다.
  void setRecordedAt(DateTime dt) => state = state.copyWith(recordedAt: dt);

  /// 화장실 방문 여부를 설정한다.
  /// 미방문(false)으로 변경하면 기분도 함께 null로 초기화한다.
  void setVisited(bool? v) {
    state = state.copyWith(visited: v, mood: v == false ? null : state.mood);
  }

  /// 기분을 설정한다.
  /// 기분을 선택하면 visited가 자동으로 true로 설정된다.
  void setMood(MoodLevel? m) => state = state.copyWith(
    mood: m,
    visited: m != null ? true : state.visited,
  );

  /// 메모를 설정한다. 빈 문자열이면 null로 저장한다.
  void setMemo(String text) =>
      state = state.copyWith(memo: text.isEmpty ? null : text);

  /// 현재 폼 상태를 DB에 저장하고 홈 위젯을 갱신한다.
  /// existingEntry가 있으면 수정(update), 없으면 신규 삽입(insert)한다.
  Future<void> save(AppDatabase db) async {
    state = state.copyWith(isSaving: true);
    try {
      final companion = EntriesCompanion(
        id: existingEntry != null
            ? Value(existingEntry!.id)
            : const Value.absent(),
        recordedAt: Value(state.recordedAt),
        visited: Value(state.visited),
        mood: Value(state.mood?.index),
        memo: Value(state.memo),
      );

      if (existingEntry != null) {
        await db.updateEntry(companion);
      } else {
        await db.insertEntry(companion);
      }
      state = state.copyWith(isSaving: false);
    } catch (e, s) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  /// existingEntry를 DB에서 삭제한다.
  /// 신규 생성 모드(existingEntry == null)에서는 아무 작업도 하지 않는다.
  Future<void> delete(AppDatabase db) async {
    if (existingEntry == null) {
      return;
    }
    try {
      await db.deleteEntry(existingEntry!.id);
    } catch (e, s) {
      rethrow;
    }
  }
}

final recordFormProvider =
    NotifierProvider.family<RecordFormNotifier, RecordFormState, Entry?>(
      RecordFormNotifier.new,
    );
