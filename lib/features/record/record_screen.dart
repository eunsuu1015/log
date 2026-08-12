// 기록 생성 및 수정 화면. 방문 여부·기분·날짜시간·메모를 입력·저장·삭제한다.
// existingEntry 유무로 신규/수정 모드를 구분하며, 저장 후 AdService가 전면 광고 빈도를 관리한다.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/ads/ad_service.dart';
import 'package:poopoolog/core/database/database_provider.dart';
import 'package:poopoolog/core/iap/iap_provider.dart';
import 'package:poopoolog/shared/widgets/mood_indicator.dart';
import 'package:poopoolog/core/extensions/entry_ext.dart';
import 'package:poopoolog/core/models/mood_display_provider.dart';
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
    super.initState();
    _memoCtrl = TextEditingController(text: widget.existingEntry?.memo ?? '');
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: _buildFormFields(context, formState, notifier),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    RecordFormState formState,
    RecordFormNotifier notifier,
    AppDatabase db,
  ) {
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
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('삭제', style: TextStyle(fontSize: 15)),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: formState.isSaving
                    ? null
                    : () async {
                        await notifier.save(db);
                        if (!context.mounted) return;
                        // 저장 후 전면 광고 노출 (5회마다 1회), 완료 후 화면 닫기
                        AdService().onRecordSaved(
                          adsRemoved: ref.read(adsRemovedProvider),
                          onComplete: () {
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
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
  List<Widget> _buildFormFields(
    BuildContext context,
    RecordFormState formState,
    RecordFormNotifier notifier,
  ) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _SectionLabel(label: '날짜 · 시간'),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: () {
              notifier.setRecordedAt(DateTime.now());
              setState(() => _pickerKey = UniqueKey());
            },
            icon: const Icon(Icons.history, size: 16),
            label: const Text('지금', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              '오늘 이후 날짜는 선택할 수 없어요',
              style: context.tt.labelSmall?.copyWith(
                color: context.cs.onSurfaceVariant.withValues(alpha: 0.6),
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
      const SizedBox(height: 6),
      _VisitedToggle(value: formState.visited, onChanged: notifier.setVisited),
      const SizedBox(height: 16),
      const _SectionLabel(label: '기분'),
      const SizedBox(height: 6),
      _MoodSelector(selected: formState.mood, onChanged: notifier.setMood),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '메모',
              style: context.tt.labelMedium,
            ),
            const SizedBox(width: 6),
            Text(
              '탭하면 메모에 추가돼요',
              style: context.tt.labelSmall?.copyWith(
                color: context.cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
      _MemoField(controller: _memoCtrl, onChanged: notifier.setMemo),
      const SizedBox(height: 8),
      _MemoQuickTags(
        onTag: (tag) {
          final cur = _memoCtrl.text;
          final next = cur.isEmpty ? tag : '$cur $tag';
          _memoCtrl.text = next;
          notifier.setMemo(next);
        },
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
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await notifier.delete(db);
      if (ctx.mounted) Navigator.pop(ctx);
    }
  }
}

// ---------------------------------------------------------------------------
// 서브 위젯
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(label, style: context.tt.labelMedium);
}

class _CupertinoDatePicker extends ConsumerWidget {
  final DateTime recordedAt;
  final Entry? arg; // Provider에 전달할 파라미터가 있다면 함께 넘겨받기

  const _CupertinoDatePicker({super.key, required this.recordedAt, this.arg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 140,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(0.78)),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.dateAndTime,
          initialDateTime: recordedAt,
          minimumDate: DateTime(2026, 5),
          maximumDate: DateTime.now().copyWith(
            hour: 23,
            minute: 59,
            second: 59,
          ),
          use24hFormat: false,
          onDateTimeChanged: (DateTime newDate) {
            logger.d('select datetime : $newDate');
            ref.read(recordFormProvider(arg).notifier).setRecordedAt(newDate);
          },
        ),
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
        color: context.cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          title: Text('화장실에 다녀왔어요', style: context.tt.titleSmall),
          trailing: Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value ?? false,
              onChanged: onChanged,
              activeThumbColor: context.cs.primary,
            ),
          ),
          onTap: () => onChanged(!(value ?? false)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          minVerticalPadding: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

/// 좋음·보통·나쁨 세 개 버튼으로 기분을 선택하는 위젯.
/// 색상·레이블은 MoodLevelX 확장을 사용해 별도 맵·메서드를 제거했다.
/// 기분 표시 방식이 face일 때 아이콘 크기를 22px로 축소한다.
class _MoodSelector extends ConsumerWidget {
  final MoodLevel? selected;
  final void Function(MoodLevel?) onChanged;

  const _MoodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const moods = MoodLevel.values;
    final isFace = ref.watch(moodDisplayProvider) == MoodDisplay.face;
    final indicatorSize = isFace ? 22.0 : 28.0;
    return Row(
      children: moods.asMap().entries.map((e) {
        final i = e.key;
        final m = e.value;
        final sel = selected == m;
        final color = m.color;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < moods.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onChanged(sel ? null : m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel
                      ? color.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 28,
                      child: Center(
                        child: MoodIndicator(
                          mood: m,
                          visited: true,
                          size: indicatorSize,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      m.label,
                      style: context.tt.titleSmall?.copyWith(
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? color : context.cs.onSurfaceVariant,
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

  const _MemoField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          style: const TextStyle(fontSize: 12),
          controller: controller,
          onChanged: onChanged,
          maxLines: 4,
          minLines: 1,
          decoration: InputDecoration(
            hintText: '자유롭게 기록하세요',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            filled: true,
            fillColor: context.cs.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: context.cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// 메모 입력창 하단에 표시되는 카테고리별 빠른 태그 위젯.
/// 태그를 탭하면 메모 필드 끝에 해당 태그가 삽입된다.
class _MemoQuickTags extends StatelessWidget {
  final void Function(String) onTag;

  const _MemoQuickTags({required this.onTag});

  static const _categories = <(String, List<String>)>[
    ('상태', ['쾌변', '설사', '묽음', '딱딱함']),
    ('증상', ['배아픔', '잔변감', '급했음', '냄새 심함', '냄새 없음']),
    ('식사', ['식후', '공복']),
    ('기타', ['스트레스', '운동 후']),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,

      children: _categories.map((entry) {
        final (label, tags) = entry;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 6, bottom: 6),
              child: Text(
                label,
                style: context.tt.labelSmall?.copyWith(
                  color: context.cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags.map((tag) {
                  return ActionChip(
                    label: Text(tag),
                    labelStyle: context.tt.labelSmall?.copyWith(
                      color: context.cs.onSurfaceVariant,
                    ),
                    backgroundColor: context.cs.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: () => onTag(tag),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
