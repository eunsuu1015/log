import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 연도·월을 빠르게 선택하는 바텀시트 피커
Future<DateTime?> showMonthPickerSheet({
  required BuildContext context,
  required DateTime current,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MonthPickerSheet(current: current),
  );
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime current;
  const _MonthPickerSheet({required this.current});

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;

  // 선택 가능 범위
  static const int _minYear = 2026;
  static final int _maxYear = DateTime.now().year;

  late final FixedExtentScrollController _yearCtrl;
  late final FixedExtentScrollController _monthCtrl;

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
    _month = widget.current.month;
    _yearCtrl = FixedExtentScrollController(initialItem: _year - _minYear);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 확인 버튼
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
                      color: colorScheme.primary,
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
                // 연도 피커
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _yearCtrl,
                    itemExtent: 40,
                    onSelectedItemChanged: (i) =>
                        setState(() => _year = _minYear + i),
                    children: [
                      for (int y = _minYear; y <= _maxYear; y++)
                        Center(
                          child: Text(
                            '$y년',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 월 피커
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _monthCtrl,
                    itemExtent: 40,
                    onSelectedItemChanged: (i) =>
                        setState(() => _month = i + i),
                    children: [
                      for (int m = 1; m <= 12; m++)
                        Center(
                          child: Text(
                            '$m월',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
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
