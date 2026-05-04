// 타임라인 탭 화면
// 전체 기록을 최신순 날짜별 그룹으로 표시하고 기분 필터를 제공한다.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/features/calendar/calendar_provider.dart';
import 'package:poopoolog/features/record/record_screen.dart';
import 'package:poopoolog/features/timeline/timeline_provider.dart';

/// 타임라인 탭 루트 위젯. 필터 칩 + 기록 리스트로 구성된다.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    throw UnimplementedError();
  }

  /// 신규 기록 입력 화면을 열고 닫힌 뒤 목록을 갱신한다.
  void _openNew(BuildContext context, WidgetRef ref) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordScreen(),fullscreenDialog: true
    ),
    ).then((_) => _refresh(ref));
  }

  /// 기존 기록 수정 화면을 열고 닫힌 뒤 목록을 갱신한다.
  void _openEdit(BuildContext context, WidgetRef ref, Entry entry) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RecordScreen(existingEntry: entry,),
    fullscreenDialog: true)
,).then((_) => _refresh(ref));
  }

  /// 타임라인 통계 캘린더 Provider를 모두 무효화해 데이터를 새로 로드한다.
  void _refresh(WidgetRef ref) {
    ref.invalidate(timelineProvider);
    // TODO: 현재 없음. 나중에 만들고나면 주석 해제
    // ref.invalidate(statsResultProvider);
    // 캘린더도 같이 갱신
    final month = ref.read(calendarFocusedMonthProvider);
    ref.invalidate(monthlyEntriesProvider(month));
  }
}


// ---------------------------------------------------------------------------
// 타임라인 리스트
// ---------------------------------------------------------------------------
