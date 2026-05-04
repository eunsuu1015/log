// 캘린더 탭 화면
// 월간 달력에 기분 도트를 표시하고, 날짜 선택 시 해당 날의 기록 목록을 하단에 표시한다.
// 기분 색상, 레이블은 EntryX 확장(entry_ext.dart)을 사용한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:poopoolog/features/calendar/calendar_provider.dart';
import 'package:poopoolog/features/calendar/widgets/month_picker_sheet.dart';
import 'package:poopoolog/features/calendar/widgets/mood_dot_row.dart';
import 'package:poopoolog/features/record/record_provider.dart';
import 'package:poopoolog/features/record/record_screen.dart';
import 'package:poopoolog/features/timeline/timeline_provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/database/app_database.dart';
import '../../shared/widgets/entry_card.dart';

/// 캘린더 탭 루트 위젯. Provider를 구독하고 _CalendarBody에 데이터를 내려준다.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(calendarFocusedMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final entriesAsync = ref.watch(monthlyEntriesProvider(focusedMonth));
    // 로딩 중에는 이전에 캐시된 데이터를 그대로 사용 (스와이프 시 캘린더가 사라지지 않게
    final monthlyEntries = entriesAsync.valueOrNull ?? const {};
    final now = DateTime.now();
    final isCurrentMonth =
        focusedMonth.year == now.year && focusedMonth.month == now.month;

    void goToToday() {
      final today = DateTime.now();
      ref.read(calendarFocusedMonthProvider.notifier).state = DateTime(
        today.year,
        today.month,
      );
      ref.read(selectedDayProvider.notifier).state = today;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          if (!isCurrentMonth)
            IconButton(
              tooltip: '오늘로 돌아가기',
              icon: const Icon(Icons.today_outlined),
              onPressed: goToToday,
            ),
        ],
      ),
      body: entriesAsync.hasError
          ? Center(child: Text('오류: ${entriesAsync.error}'))
          : _CalendarBody(
              focusedMonth: focusedMonth,
              monthlyEntries: monthlyEntries,
              onMonthChanged: (month) {
                ref.read(calendarFocusedMonthProvider.notifier).state = month;
                ref.read(selectedDayProvider.notifier).state = null;
              },
              onDaySelected: (day) {
                ref.read(selectedDayProvider.notifier).state = day;
                final dayKey = DateTime(day.year, day.month, day.day);
                final entries = monthlyEntries[dayKey] ?? [];
                if (entries.isEmpty) {
                  _openRecordScreen(context, ref, day);
                }
              },
              onMonthPickerTap: () async {
                final picked = await showMonthPickerSheet(
                  context: context,
                  current: focusedMonth,
                );
                if (picked != null) {
                  ref.read(calendarFocusedMonthProvider.notifier).state =
                      picked;
                }
              },
              onAddEntry: (day) => _openRecordScreen(context, ref, day),
              onEditEntry: (entry) =>
                  _openRecordScreen(context, ref, null, existingEntry: entry),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_calendar',
        onPressed: () => _openRecordScreen(context, ref, null),
        tooltip: '기록 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 기록 생성/수정 화면을 열고 닫힌 뒤 캘린더·타임라인·통계를 갱신한다.
  /// invalidate와 화면 열기 사이에 addPostFrameCallback을 사용해
  /// 빌드 중 상태 변경으로 인한 애니메이션 끊김을 방지한다.
  void _openRecordScreen(
    BuildContext context,
    WidgetRef ref,
    DateTime? presetDate, {
    Entry? existingEntry,
  }) {
    if (existingEntry == null) {
      ref.invalidate(recordFormProvider(null));
      // 시트 열기 전(빌드 외부)에 미리 세팅 -> initState/build 중 상태 변경 없음
      if (presetDate != null) {
        final now = DateTime.now();
        ref
            .read(recordFormProvider(null).notifier)
            .setRecordedAt(
              DateTime(
                presetDate.year,
                presetDate.month,
                presetDate.day,
                now.hour,
                now.minute,
              ),
            );
      }
    }
    // TODO: 애니메이션 프레임 작업? 일단 안 함
    // invalidate와 시트 오픈을 같은 프레임에 실행하면 애니메이션 첫 프레임이
    // rebuild 작업과 겹쳐서 오픈 애니메이션이 스킵되거나 끊김
    // 다음 프레임에 열어서 현재 프레임 작업을 먼저 완료시킴
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RecordScreen(presetDate: presetDate, existingEntry: existingEntry),
        fullscreenDialog: true,
      ),
    ).then((_) {
      final month = ref.read(calendarFocusedMonthProvider);
      ref.invalidate(monthlyEntriesProvider(month));
      ref.invalidate(timelineProvider);
      // TODO: statsResultProvider 추가 (주석 풀기)
      // ref.invalidate(statsResultProvider);
    });

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const RecordScreen()),
    // );
  }
}

// ---------------------------------------------------------------------------

/// 캘린더 본문 — TableCalendar + 오늘 버튼 + 선택된 날 기록 패널
class _CalendarBody extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<DateTime, List<Entry>> monthlyEntries;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDaySelected;
  final VoidCallback onMonthPickerTap;
  final void Function(DateTime) onAddEntry;
  final void Function(Entry) onEditEntry;

  const _CalendarBody({
    required this.focusedMonth,
    this.selectedDay,
    required this.monthlyEntries,
    required this.onMonthChanged,
    required this.onDaySelected,
    required this.onMonthPickerTap,
    required this.onAddEntry,
    required this.onEditEntry,
  });

  List<Entry> _entriesForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return monthlyEntries[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedEntries = selectedDay != null
        ? _entriesForDay(selectedDay!)
        : <Entry>[];

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2026),
          lastDay: DateTime(DateTime.now().year, 12, 31),
          daysOfWeekHeight: 30,
          focusedDay: focusedMonth,
          rowHeight: 55,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          eventLoader: _entriesForDay,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarBuilders: CalendarBuilders(
            headerTitleBuilder: (context, day) => GestureDetector(
              onTap: onMonthPickerTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.year}년 ${day.month}월',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.expand_more,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            // 날짜 아래에 닷 만들어주기
            markerBuilder: (context, day, entries) {
              if (entries.isEmpty) return const SizedBox.shrink();
              return Positioned(
                bottom: 2,
                child: MoodDotRow(entries: entries.cast<Entry>()),
              );
            },
            selectedBuilder: (context, day, _) => Align(
              alignment: Alignment.center,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            todayBuilder: (context, day, _) => Align(
              alignment: Alignment.center,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          onDaySelected: (selected, _) => onDaySelected(selected),
          onPageChanged: (focused) =>
              onMonthChanged(DateTime(focused.year, focused.month)),
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: EdgeInsets.symmetric(vertical: 2),
            markersAlignment: Alignment.bottomCenter,
            markerDecoration: BoxDecoration(),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
            weekendStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 3, thickness: 3, color: Color(0x33808080)),
        if (selectedDay != null && selectedEntries.isNotEmpty) ...[
          _DayPanel(
            date: selectedDay!,
            entries: selectedEntries,
            onAddEntry: () => onAddEntry(selectedDay!),
            onEditEntry: onEditEntry,
          ),
        ],
      ],
    );
  }
}

/// 선택된 날짜의 기록 목록과 추가 버튼을 보여주는 하단 패널
class _DayPanel extends StatelessWidget {
  final DateTime date;
  final List<Entry> entries;
  final VoidCallback onAddEntry;
  final void Function(Entry) onEditEntry;

  _DayPanel({
    required this.date,
    required this.entries,
    required this.onAddEntry,
    required this.onEditEntry,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 2),
            child: Row(
              children: [
                Text(
                  '${date.month}월 ${date.day}일',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAddEntry,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('추가'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox.shrink(),
              itemBuilder: (_, i) => EntryCard(
                entry: entries[i],
                onTap: () => onEditEntry(entries[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
