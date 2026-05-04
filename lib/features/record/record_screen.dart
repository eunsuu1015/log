import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/features/record/record_provider.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';
import 'package:poopoolog/utils/logger.dart';

import '../../core/database/app_database.dart';

/// 기록 생성(existingEntry == null) 및 수정(existingEntry != null)을 담당하는 화면.
/// presetDate가 지정되면 해당 날짜로 날짜 필드를 초기화한다.
class RecordScreen extends ConsumerStatefulWidget {
  final DateTime? presetDate; // 화면에 세팅할 날짜 (달력에서 날짜를 선택했거나, 기록을 수정하는 경우)
  final Entry? existingEntry;
  final bool showAsSheet;

  const RecordScreen({
    super.key,
    this.presetDate,
    this.existingEntry,
    this.showAsSheet = false,
  });

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  late final TextEditingController _memoCtrl;
  Key _pickerKey = UniqueKey();

  @override
  void initState() {
    _memoCtrl = TextEditingController(text: widget.existingEntry?.memo ?? '');
    super.initState();
  }

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(recordFormProvider(widget.existingEntry));
    final notifier = ref.read(
      recordFormProvider(widget.existingEntry).notifier,
    );
    final db = ref.read(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 입력'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, formState, notifier, db),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        children: _buildFormFields(context, formState, notifier),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, formState, notifier, db) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (widget.existingEntry != null) ...[
              OutlinedButton(
                onPressed: () => _confirmDelete(context, notifier, db),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.cs.error,
                  side: BorderSide(color: context.cs.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: formState.isSaving
                    ? null
                    : () async {
                        await notifier.save(db);
                        if (context.mounted) Navigator.pop(context);
                      },
                child: formState.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '저장',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 날짜·시간, 방문 여부, 기분, 메모 폼 필드 목록을 반환한다.
  List<Widget> _buildFormFields(BuildContext context, formState, notifier) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _SectionLabel(label: '날짜 · 시간'),
          SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextButton.icon(
              onPressed: () {
                ref
                    .read(recordFormProvider(widget.existingEntry).notifier)
                    .setRecordedAt(DateTime.now());
                setState(() => _pickerKey = UniqueKey());
              },
              icon: const Icon(Icons.history, size: 16),
              label: Text('지금', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
      _CupertinoDatePicker(
        key: _pickerKey,
        recordedAt: formState.recordedAt,
        arg: widget.existingEntry,
      ),
      const _SectionLabel(label: '화장실'),
      _VisitedToggle(value: formState.visited, onChanged: notifier.setVisited),
      SizedBox(height: 16),
      const _SectionLabel(label: '기분'),
      _MoodSelector(selected: formState.mood, onChanged: notifier.setMood),
      SizedBox(height: 16),
      const _SectionLabel(label: '메모'),
      _MemoField(controller: _memoCtrl, onChanged: notifier.setMemo),
      SizedBox(height: 2),
      _MemoQuickTags(
        onTag: (tag) {
          final cur = _memoCtrl.text;
          final next = cur.isEmpty ? tag : '$cur $tag';
          _memoCtrl.text = next;
          notifier.setMemo(next);
        },
      ),
      const Text(
        '탭하면 메모에 추가돼요',
        style: TextStyle(fontSize: 12, color: Colors.black45),
      ),
      const SizedBox(height: 32),
    ];
  }

  /// 삭제 확인 다이얼로그를 표시하고 확인 시 기록을 삭제한다.
  Future<void> _confirmDelete(
    BuildContext ctx,
    RecordFormNotifier notifier,
    AppDatabase db,
  ) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 기록을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 서브 위젯
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: context.cs.onSurfaceVariant,
      ),
    ),
  );
}

class _CupertinoDatePicker extends ConsumerWidget {
  final DateTime recordedAt;
  final Entry? arg; // Provider에 전달할 파라미터가 있다면 함께 넘겨받기

  const _CupertinoDatePicker({super.key, required this.recordedAt, this.arg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 150,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.dateAndTime,
        initialDateTime: recordedAt,
        use24hFormat: false,
        onDateTimeChanged: (DateTime newDate) {
          logger.d('select datetime : ${newDate}');
          ref.read(recordFormProvider(arg).notifier).setRecordedAt(newDate);
        },
      ),
    );
  }
}

class _VisitedToggle extends StatelessWidget {
  final bool? value;
  final void Function(bool?) onChanged;

  const _VisitedToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        value: value ?? false,
        onChanged: onChanged,
        title: const Text('화장실에 다녀왔어요', style: TextStyle(fontSize: 14)),
        activeColor: context.cs.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// 좋음·보통·나쁨 세 개 버튼으로 기분을 선택하는 위젯.
/// 색상·레이블은 MoodLevelX 확장을 사용해 별도 맵·메서드를 제거했다.
class _MoodSelector extends StatelessWidget {
  final MoodLevel? selected;
  final void Function(MoodLevel?) onChanged;

  _MoodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MoodLevel.values.map((m) {
        final sel = selected == m;
        final color = m.color;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(sel ? null : m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: sel
                      ? color.withOpacity(0.15)
                      : Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: sel ? color : color.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel
                            ? color
                            : context.cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MemoField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  _MemoField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: TextStyle(fontSize: 14),
      controller: controller,
      onChanged: onChanged,
      maxLines: 4,
      minLines: 3,
      decoration: InputDecoration(
        hintText: '자유롭게 기록하세요',
        hintStyle: TextStyle(color: context.cs.outline, fontSize: 14),
        filled: true,
        fillColor: context.cs.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

class _MemoQuickTags extends StatelessWidget {
  final void Function(String) onTag;

  _MemoQuickTags({required this.onTag});

  static const _tags = ['쾌변', '설사', '묽음', '배아픔', '잔변감', '급했음'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map((tag) {
        return ActionChip(
          label: Text(tag),
          labelStyle: TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant),
          backgroundColor: context.cs.surfaceContainerHighest.withValues(alpha: 0.5),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          onPressed: () => onTag(tag),
        );
      }).toList(),
    );
  }
}
