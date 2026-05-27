// 캘린더 헤더 탭 시 표시되는 연도·월 선택 바텀시트.
// minDate로 이전 날짜 선택을 제한하며, 연도 변경 시 월 범위를 자동으로 클램프한다.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

/// 연도·월을 빠르게 선택하는 바텀시트 피커.
/// [minDate]로 선택 가능한 최솟값을 제한한다.
Future<DateTime?> showMonthPickerSheet({
  required BuildContext context,
  required DateTime current,
  required DateTime minDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MonthPickerSheet(current: current, minDate: minDate),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime current;
  final DateTime minDate;
  const _MonthPickerSheet({required this.current, required this.minDate});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;

  int get _minYear => widget.minDate.year;
  int get _minMonth => widget.minDate.month;
  // late final로 선언해 initState() 시점에 계산. static final은 클래스 최초 로드 시 고정되어
  // 앱이 연말~연초 사이 백그라운드 유지 중 열리면 _maxYear/_currentMonth가 구년도에 묶임.
  late final int _maxYear;
  late final int _currentMonth;

  late final FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;

  /// 현재 선택된 연도에서의 최소 월
  int get _minMonthForYear => _year == _minYear ? _minMonth : 1;

  /// 현재 선택된 연도에서의 최대 월
  int get _maxMonth => _year == _maxYear ? _currentMonth : 12;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _maxYear = now.year;
    _currentMonth = now.month;
    _year = widget.current.year;
    final minM = _year == _minYear ? _minMonth : 1;
    final maxM = _year == _maxYear ? _currentMonth : 12;
    _month = widget.current.month.clamp(minM, maxM);
    _yearCtrl = FixedExtentScrollController(initialItem: _year - _minYear);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - minM);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    super.dispose();
  }

  void _onYearChanged(int i) {
    final newYear = _minYear + i;
    final newMinMonth = newYear == _minYear ? _minMonth : 1;
    final newMaxMonth = newYear == _maxYear ? _currentMonth : 12;
    final clampedMonth = _month.clamp(newMinMonth, newMaxMonth);

    final oldCtrl = _monthCtrl;
    _monthCtrl = FixedExtentScrollController(
      initialItem: clampedMonth - newMinMonth,
    );

    setState(() {
      _year = newYear;
      _month = clampedMonth;
    });

    oldCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, DateTime(_year, _month)),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _yearCtrl,
                    itemExtent: 40,
                    onSelectedItemChanged: _onYearChanged,
                    children: [
                      for (int y = _minYear; y <= _maxYear; y++)
                        Center(
                          child: Text(
                            '$y년',
                            style: context.tt.bodyLarge,
                          ),
                        ),
                    ],
                  ),
                ),
                // 월 피커 — ValueKey(_year)로 연도 변경 시 완전 재생성
                Expanded(
                  child: CupertinoPicker(
                    key: ValueKey(_year),
                    scrollController: _monthCtrl,
                    itemExtent: 40,
                    onSelectedItemChanged: (i) =>
                        setState(() => _month = i + _minMonthForYear),
                    children: [
                      for (int m = _minMonthForYear; m <= _maxMonth; m++)
                        Center(
                          child: Text(
                            '$m월',
                            style: context.tt.bodyLarge,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
