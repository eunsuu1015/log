// 앱 도메인 모델 파일. Freezed 없이 순수 Dart 클래스로 작성 — build_runner 불필요.
// MoodLevel enum의 색상·레이블 확장은 core/extensions/entry_ext.dart에 정의된다.

/// 기분 단계 (DB에는 index 정수로 저장)
enum MoodLevel {
  good, // 0: 좋음
  okay, // 1: 보통
  bad, // 2: 나쁨
}

/// 하나의 기록 엔티티. Drift Entry Row ↔ 앱 계층 변환용 불변 값 객체.
class RecordModel {
  const RecordModel({
    required this.id,
    required this.recordedAt,
    this.visited,
    this.mood,
    this.memo,
    required this.createdAt,
  });

  final int id;

  /// 사용자가 지정한 기록 날짜+시간 (수정 가능)
  final DateTime recordedAt;

  /// 화장실 방문 여부 (null = 미입력)
  final bool? visited;

  /// 기분 단계 (null = 미입력)
  final MoodLevel? mood;

  /// 자유 메모
  final String? memo;

  /// 앱이 저장한 실제 시각 (자동)
  final DateTime createdAt;

  /// 일부 필드만 변경한 새 인스턴스를 반환한다.
  /// nullable 필드(visited, mood, memo)를 명시적으로 null로 지정하려면 _sentinel 패턴을 사용한다.
  RecordModel copyWith({
    int? id,
    DateTime? recordedAt,
    Object? visited = _sentinel,
    Object? mood = _sentinel,
    Object? memo = _sentinel,
    DateTime? createdAt,
  }) => RecordModel(
    id: id ?? this.id,
    recordedAt: recordedAt ?? this.recordedAt,
    visited: visited == _sentinel ? this.visited : visited as bool?,
    mood: mood == _sentinel ? this.mood : mood as MoodLevel?,
    memo: memo == _sentinel ? this.memo : memo as String?,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  String toString() =>
      'RecordModel(id: $id, recordedAt: $recordedAt, visited: $visited, '
      'mood: $mood, memo: $memo, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordModel && other.id == id && other.recordedAt == recordedAt;

  @override
  int get hashCode => Object.hash(id, recordedAt);
}

const _sentinel = Object();
