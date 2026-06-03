// 캘린더 탭 화면
// 월간 달력에 기분 도트를 표시하고, 날짜 선택 시 해당 날의 기록 목록을 하단에 표시한다.
// 기분 색상, 레이블은 EntryX 확장(entry_ext.dart)을 사용한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/settings/display_settings.dart';
import 'package:poopoolog/features/calendar/calendar_provider.dart';
import 'package:poopoolog/features/calendar/widgets/month_picker_sheet.dart';
import 'package:poopoolog/features/calendar/widgets/mood_dot_row.dart';
import 'package:poopoolog/features/record/record_provider.dart';
import 'package:poopoolog/features/record/record_screen.dart';
import 'package:poopoolog/features/timeline/timeline_provider.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/database/app_database.dart';
import '../../shared/widgets/entry_card.dart';

/// 캘린더가 이동할 수 있는 가장 이른 날. 피커 minDate와 반드시 일치해야 한다.
final _kCalendarFirstDay = DateTime(2026, 5, 1);

/// 캘린더가 이동할 수 있는 가장 이른 달 (연-월만).
final _kCalendarFirstMonth = DateTime(
  _kCalendarFirstDay.year,
  _kCalendarFirstDay.month,
);

/// 캘린더 탭 루트 위젯. Provider를 구독하고 _CalendarBody에 데이터를 내려준다.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedMonth = ref.watch(calendarFocusedMonthProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final entriesAsync = ref.watch(monthlyEntriesProvider(focusedMonth));
    // 로딩 중에는 이전에 캐시된 데이터를 그대로 사용 (스와이프 시 캘린더가 사라지지 않게)
    final monthlyEntries = entriesAsync.valueOrNull ?? const {};
    final now = DateTime.now();
    final isCurrentMonth =
        focusedMonth.year == now.year && focusedMonth.month == now.month;
    final nowMonth = DateTime(now.year, now.month);
    final isPastMonth = focusedMonth.isBefore(nowMonth);

    // 최초 기록일 기반 바운더리
    final earliestDate = ref.watch(earliestEntryDateProvider).valueOrNull;
    // 피커 minDate: 캘린더 firstDay(_kCalendarFirstDay)보다 앞설 수 없도록 클램프.
    // earliestDate가 firstDay보다 이전이면 캘린더가 해당 달을 표시할 수 없으므로
    // firstDay 월을 하한으로 사용한다.
    final rawPickerMin = earliestDate != null
        ? DateTime(earliestDate.year, earliestDate.month)
        : nowMonth;
    final pickerMinDate = rawPickerMin.isBefore(_kCalendarFirstMonth)
        ? _kCalendarFirstMonth
        : rawPickerMin;
    final isBeforeEarliest =
        earliestDate != null &&
        focusedMonth.isBefore(DateTime(earliestDate.year, earliestDate.month));

    void goToToday() {
      final today = DateTime.now();
      ref.read(calendarFocusedMonthProvider.notifier).state = DateTime(
        today.year,
        today.month,
      );
      ref.read(selectedDayProvider.notifier).state = today;
    }

    Widget makeGoToTodayButton(bool isPast) {
      return ElevatedButton(
        onPressed: goToToday,
        style: ElevatedButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // 버튼 크기를 내용물에 맞춤
          children: [
            if (!isPast) const Icon(Icons.arrow_back_ios, size: 14),
            const Text('오늘'),
            if (isPast) const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          if (!isCurrentMonth)
            makeGoToTodayButton(isPastMonth),
          const SizedBox(width: 10),
        ],
      ),
      body: isBeforeEarliest
          ? _BeforeEarliestState(earliestDate: earliestDate)
          : entriesAsync.hasError
          ? Center(child: Text('오류: ${entriesAsync.error}'))
          : _CalendarBody(
              focusedMonth: focusedMonth,
              monthlyEntries: monthlyEntries,
              selectedDay: selectedDay,
              startSunday: ref.watch(startWeekdaySundayProvider),
              onMonthChanged: (month) {
                ref.read(calendarFocusedMonthProvider.notifier).state = month;
                ref.read(selectedDayProvider.notifier).state = null;
              },
              onDaySelected: (day) {
                ref.read(selectedDayProvider.notifier).state = day;
              },
              onMonthPickerTap: () async {
                final picked = await showMonthPickerSheet(
                  context: context,
                  current: focusedMonth,
                  minDate: pickerMinDate,
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
        onPressed: () => _openRecordScreen(context, ref, selectedDay),
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
        final today = DateTime(now.year, now.month, now.day);
        // 미래 날짜 선택 후 FAB 탭 시 날짜를 오늘로 대체
        final effectiveDate =
            presetDate.isAfter(today) ? today : presetDate;
        ref
            .read(recordFormProvider(null).notifier)
            .setRecordedAt(
              DateTime(
                effectiveDate.year,
                effectiveDate.month,
                effectiveDate.day,
                now.hour,
                now.minute,
              ),
            );
      }
    }
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
      ref.invalidate(earliestEntryDateProvider);
    });
  }
}

// ---------------------------------------------------------------------------

/// 캘린더 본문 — TableCalendar + 오늘 버튼 + 선택된 날 기록 패널
class _CalendarBody extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<DateTime, List<Entry>> monthlyEntries;
  final bool startSunday;
  final void Function(DateTime) onMonthChanged;
  final void Function(DateTime) onDaySelected;
  final VoidCallback onMonthPickerTap;
  final void Function(DateTime) onAddEntry;
  final void Function(Entry) onEditEntry;

  const _CalendarBody({
    required this.focusedMonth,
    this.selectedDay,
    required this.monthlyEntries,
    this.startSunday = false,
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

  Widget _buildDayCircle(
    BuildContext context,
    DateTime day, {
    required Color bgColor,
    required Color textColor,
  }) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Text(
          '${day.day}',
          style: context.tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final now = DateTime.now();
    final selectedEntries = selectedDay != null
        ? _entriesForDay(selectedDay!)
        : <Entry>[];

    return Column(
      children: [
        TableCalendar(
          firstDay: _kCalendarFirstDay,
          lastDay: DateTime(now.year, now.month + 2, 0),
          startingDayOfWeek: startSunday
              ? StartingDayOfWeek.sunday
              : StartingDayOfWeek.monday,
          daysOfWeekHeight: 20,
          focusedDay: focusedMonth,
          rowHeight: 50,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          eventLoader: _entriesForDay,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerPadding: EdgeInsets.zero,
          ),
          calendarBuilders: CalendarBuilders(
            dowBuilder: (context, day) {
              const labels = ['월', '화', '수', '목', '금', '토', '일'];
              final label = labels[day.weekday - 1];
              final isWeekend = day.weekday == 6 || day.weekday == 7;
              return Center(
                child: Text(
                  label,
                  style: context.tt.labelSmall?.copyWith(
                    color: isWeekend
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
            headerTitleBuilder: (context, day) => GestureDetector(
              onTap: onMonthPickerTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${day.year}년 ${day.month}월',
                    style: context.tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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
            // 선택한 날짜를 진한색 원으로 표시
            selectedBuilder: (context, day, _) => _buildDayCircle(
              context,
              day,
              bgColor: colorScheme.primary,
              textColor: colorScheme.onPrimary,
            ),
            // 오늘 날짜를 연한색 원으로 표시
            todayBuilder: (context, day, _) => _buildDayCircle(
              context,
              day,
              bgColor: context.cs.primary,
              textColor: Colors.white,
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
        ),
        const SizedBox(height: 15),
        const Divider(height: 1, thickness: 1, color: Color(0x33808080)),
        if (selectedDay != null) ...[
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

/// 최초 기록일 이전 달을 보고 있을 때 표시하는 안내 위젯
class _BeforeEarliestState extends StatelessWidget {
  final DateTime earliestDate;
  const _BeforeEarliestState({required this.earliestDate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: cs.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '푸푸로그를 시작하기 전이에요!',
            style: context.tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '첫 기록은 ${earliestDate.year}년 ${earliestDate.month}월 ${earliestDate.day}일입니다.',
            style: context.tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w400,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 선택된 날짜에 기록이 없을 때 하단 패널에 표시하는 빈 상태 위젯.
class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState();

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notes_outlined, size: 40, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            '저장된 기록이 없어요',
            style: context.tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '이 날의 기록을 추가해보세요',
            style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 선택된 날짜의 기록 목록과 추가 버튼을 보여주는 하단 패널
class _DayPanel extends StatelessWidget {
  final DateTime date;
  final List<Entry> entries;
  final VoidCallback onAddEntry;
  final void Function(Entry) onEditEntry;

  const _DayPanel({
    required this.date,
    required this.entries,
    required this.onAddEntry,
    required this.onEditEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 6, 12, 2),
            child: Row(
              children: [
                Text(
                  '${date.month}월 ${date.day}일',
                  style: context.tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
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
            child: entries.isEmpty
                ? const _EmptyDayState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 80),
                    itemCount: entries.length,
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
