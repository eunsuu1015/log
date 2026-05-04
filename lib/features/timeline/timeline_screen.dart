// 타임라인 탭 화면.
// 전체 기록을 최신순·날짜별 그룹으로 표시하고 기분 필터를 제공한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/features/timeline/timeline_provider.dart';
import 'package:poopoolog/features/timeline/widgets/date_header.dart';
import 'package:poopoolog/features/timeline/widgets/filter_chip_row.dart';
import 'package:poopoolog/shared/widgets/entry_card.dart';

import '../../core/database/app_database.dart';
import '../../shared/theme/app_theme.dart';
import '../calendar/calendar_provider.dart';
import '../record/record_screen.dart';

/// 타임라인 탭 루트 위젯. 필터 침 + 기록 리스트로 구성된다.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('기록', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)
        ,),
          bottom: const PreferredSize(preferredSize: Size.fromHeight(48), child: FilterChipRow()
    ),
        ),
      body: timelineAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e'),),
          data: (groups) => groups.isEmpty
            ? _EmptyState(
            hasFilter: ref.watch(timelineFilterProvider) != TimelineFilter.all,
          )
            : RefreshIndicator(onRefresh: () async => ref.invalidate(timelineProvider), child: _TimelineList(groups: groups, onEntryTap: (entry) => _openEdit(context, ref, entry),
          ),
          ),
          ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_timeline',
        onPressed: () => _openNew(context, ref),
        tooltip: '기록 추가',
        child: const Icon(Icons.add),
      ),
    );
  }


  /// 신규 기록 입력 화면을 열고 닫힌 뒤 목록을 갱신한다.
  void _openNew(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecordScreen(),
        fullscreenDialog: true,
      ),
    ).then((_) => _refresh(ref));
  }

  /// 기존 기록 수정 화면을 열고 닫힌 뒤 목록을 갱신한다.
  void _openEdit(BuildContext context, WidgetRef ref, Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordScreen(existingEntry: entry),
        fullscreenDialog: true,
      ),
    ).then((_) => _refresh(ref));
  }

  /// 타임라인·통계·캘린더 Provider를 모두 무효화해 데이터를 새로 로드한다.
  void _refresh(WidgetRef ref) {
    ref.invalidate(timelineProvider);
    // TODO: Stats provider 생성 후 주석 풀기
    // ref.invalidate(statsResultProvider);
    // 캘린더도 같이 갱신
    final month = ref.read(calendarFocusedMonthProvider);
    ref.invalidate(monthlyEntriesProvider(month));
  }

}

// ---------------------------------------------------------------------------
// 타임라인 리스트
// ---------------------------------------------------------------------------

class _TimelineList extends StatelessWidget {
  final List<DayGroup> groups;
  final void Function(Entry) onEntryTap;

  const _TimelineList({required this.groups, required this.onEntryTap});

  @override
  Widget build(BuildContext context) {
    // 날짜 헤더 + 항목을 플랫 리스트로 변환
    final items = <_ListItem>[];
    for (final group in groups) {
      items.add(_ListItem.header(group.date, group.entries.length));
      for (final entry in group.entries) {
        items.add(_ListItem.entry(entry));
      }
    }

    // TODO: withOpacity deprecated -> withValue(alpha: )로 변경
    final dividerColor = context.cs.outlineVariant.withValues(alpha: 0.5);
    
    return ListView.separated(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: items.length,
        separatorBuilder: (_, i) {
          // 헤더 앞이나 헤더 뒤에는 구분선 없음
          final isCurrentHeader = items[i].isHeader;
          final isNextHeader = items[i + 1].isHeader;
          if (isCurrentHeader || isNextHeader) return const SizedBox.shrink();
          return Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: dividerColor,
          );
        },
        itemBuilder: (_, i) {
      final item = items[i];
      if (item.isHeader) {
        return DateHeader(date: item.date!, count: item.count!);
      }
      return EntryCard(entry: item.entry!, onTap: () => onEntryTap(item.entry!),
      );
    });
  }

}

// ---------------------------------------------------------------------------
// 빈 상태
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasFilter ? Icons.filter_list_off : Icons.edit_note_outlined,
          size: 48,
              color: cs.outlineVariant,
              ),
          const SizedBox(height: 16,),
          Text(hasFilter ? '해당 조건의 기록이 없어요' : '아직 기록이 없어요',
          // TODO: style 추가
          ),
          const SizedBox(height: 6,),
          Text(hasFilter ? '필터를 변경해보세요' : '오른쪽 아래 + 버튼으로 첫 기록을 남겨보세요'
          // TODO: style 추가
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 내부 모델 (헤더/항목 구분용)
// ---------------------------------------------------------------------------
class _ListItem {
  final bool isHeader;
  final DateTime? date;
  final int? count;
  final Entry? entry;

  _ListItem.entry(this.entry)
  : isHeader = false,
  date = null,
  count = null;

  _ListItem.header(this.date, this.count)
  : isHeader = true,
  entry = null;
}