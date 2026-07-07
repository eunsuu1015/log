// 타임라인 탭 화면.
// 전체 기록을 최신순·날짜별 그룹으로 표시하고 기분 필터를 제공한다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/core/ads/native_ad_widget.dart';
import 'package:poopoolog/features/timeline/timeline_provider.dart';
import 'package:poopoolog/features/timeline/widgets/date_header.dart';
import 'package:poopoolog/features/timeline/widgets/filter_chip_row.dart';
import 'package:poopoolog/shared/widgets/entry_card.dart';

import 'package:drift/drift.dart' show Value;

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/debug/debug_flags.dart';
import '../../shared/theme/app_theme.dart';
import '../calendar/calendar_provider.dart';
import '../record/record_provider.dart';
import '../record/record_screen.dart';
import '../stats/stats_provider.dart';

/// 타임라인 탭 루트 위젯. 필터 침 + 기록 리스트로 구성된다.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);
    final earliestAsync = ref.watch(earliestEntryDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('타임라인'),
        actions: [
          if (kDebugShowAdIds)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'AdMob IDs',
              onPressed: () => _showAdIdsDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          const FilterChipRow(),
          Expanded(
            child: timelineAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (timelineState) {
                if (timelineState.groups.isEmpty) {
                  final hasFilter =
                      ref.watch(timelineFilterProvider) != TimelineFilter.all;
                  if (hasFilter) return const _EmptyState(hasFilter: true);
                  return earliestAsync.when(
                    data: (earliest) => earliest == null
                        ? _TimelineNewUserEmptyState(
                            onPressed: () => _openRecord(context, ref),
                          )
                        : const _EmptyState(hasFilter: false),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const _EmptyState(hasFilter: false),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(earliestEntryDateProvider);
                    ref.invalidate(timelineProvider);
                    await ref.read(timelineProvider.future);
                  },
                  child: _TimelineList(
                    state: timelineState,
                    onEntryTap: (entry) =>
                        _openRecord(context, ref, entry: entry),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_timeline',
        onPressed: () => _openRecord(context, ref),
        tooltip: '기록 추가',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// AdMob App ID 및 광고 단위 ID 전체(Android·iOS)를 AlertDialog로 표시한다.
  Future<void> _showAdIdsDialog(BuildContext context) async {
    const channel = MethodChannel('com.tistory.es1015.poopoolog/widget');
    String appId = '(읽는 중...)';
    try {
      appId = await channel.invokeMethod<String>('getAdmobAppId') ?? '(없음)';
    } catch (_) {
      appId = '(읽기 실패)';
    }
    if (!context.mounted) return;

    const bannerA = String.fromEnvironment(
      'ADMOB_BANNER_ANDROID',
      defaultValue: '조회 실패',
    );
    const interstitialA = String.fromEnvironment(
      'ADMOB_INTERSTITIAL_ANDROID',
      defaultValue: '조회 실패',
    );
    const nativeA = String.fromEnvironment(
      'ADMOB_NATIVE_ANDROID',
      defaultValue: '조회 실패',
    );
    const bannerI = String.fromEnvironment(
      'ADMOB_BANNER_IOS',
      defaultValue: '조회 실패',
    );
    const interstitialI = String.fromEnvironment(
      'ADMOB_INTERSTITIAL_IOS',
      defaultValue: '조회 실패',
    );
    const nativeI = String.fromEnvironment(
      'ADMOB_NATIVE_IOS',
      defaultValue: '조회 실패',
    );
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AdMob IDs'),
        content: Text(
          '[App ID]\n'
          'Android: $appId\n\n'
          '[Android]\n'
          'BANNER: $bannerA\n'
          'INTERSTITIAL: $interstitialA\n'
          'NATIVE: $nativeA\n\n'
          '[테스트용]\n'
          'BANNER: $bannerI\n'
          'INTERSTITIAL: $interstitialI\n'
          'NATIVE: $nativeI',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 기록 생성(entry == null) 또는 수정(entry != null) 화면을 열고
  /// 닫힌 뒤 목록을 갱신한다.
  /// 신규 생성 시 이전 입력 내용이 남지 않도록 폼 상태를 초기화한다.
  void _openRecord(BuildContext context, WidgetRef ref, {Entry? entry}) {
    if (entry == null) ref.invalidate(recordFormProvider(null));
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordScreen(existingEntry: entry),
        fullscreenDialog: true,
      ),
    ).then((_) => _refresh(ref));
  }

  /// 타임라인·통계·캘린더·최초기록일 Provider를 모두 무효화해 데이터를 새로 로드한다.
  void _refresh(WidgetRef ref) {
    ref.invalidate(timelineProvider);
    ref.invalidate(statsResultProvider);
    ref.invalidate(earliestEntryDateProvider);
    final month = ref.read(calendarFocusedMonthProvider);
    ref.invalidate(monthlyEntriesProvider(month));
  }
}

// ---------------------------------------------------------------------------
// 타임라인 리스트
// ---------------------------------------------------------------------------

class _TimelineList extends ConsumerStatefulWidget {
  final TimelineState state;
  final void Function(Entry) onEntryTap;

  const _TimelineList({required this.state, required this.onEntryTap});

  @override
  ConsumerState<_TimelineList> createState() => _TimelineListState();
}

class _TimelineListState extends ConsumerState<_TimelineList> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(timelineProvider.notifier).loadMore();
    }
  }

  /// DB에서 기록을 삭제하고, 하단 SnackBar로 '복구하기' 옵션을 5초간 제공한다.
  Future<void> _deleteEntry(Entry entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final db = ref.read(appDatabaseProvider);
    await db.deleteEntry(entry.id);
    _invalidateAll();

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('삭제되었습니다.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '복구하기',
          onPressed: () => _undoDelete(entry),
        ),
      ),
    );
  }

  /// 삭제된 기록을 동일한 데이터로 재삽입해 복구한다.
  Future<void> _undoDelete(Entry entry) async {
    final db = ref.read(appDatabaseProvider);
    await db.insertEntry(
      EntriesCompanion(
        recordedAt: Value(entry.recordedAt),
        visited: Value(entry.visited),
        mood: Value(entry.mood),
        memo: Value(entry.memo),
      ),
    );
    _invalidateAll();
  }

  /// 타임라인·통계·캘린더·최초기록일 Provider를 일괄 무효화한다.
  void _invalidateAll() {
    ref.invalidate(timelineProvider);
    ref.invalidate(statsResultProvider);
    ref.invalidate(earliestEntryDateProvider);
    final month = ref.read(calendarFocusedMonthProvider);
    ref.invalidate(monthlyEntriesProvider(month));
  }

  @override
  Widget build(BuildContext context) {
    final items = <_ListItem>[];
    int entryCount = 0;
    for (final group in widget.state.groups) {
      items.add(_ListItem.header(group.date, group.entries.length));
      for (final entry in group.entries) {
        items.add(_ListItem.entry(entry));
        entryCount++;
        if (entryCount % 10 == 0) {
          items.add(_ListItem.nativeAd());
        }
      }
    }

    final dividerColor = context.cs.outlineVariant.withValues(alpha: 0.25);
    final hasMore = widget.state.hasMore;
    final isLoadingMore = widget.state.isLoadingMore;

    return SlidableAutoCloseBehavior(
      child: ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length + 1, // +1 푸터
      separatorBuilder: (_, i) {
        if (i >= items.length - 1) return const SizedBox.shrink();
        if (items[i + 1].isHeader) {
          return Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: dividerColor,
          );
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (_, i) {
        // 푸터
        if (i == items.length) {
          if (isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (hasMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(timelineProvider.notifier).loadMore();
                  },
                  child: const Text('이전 기록 더 보기'),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('모든 기록을 불러왔어요', style: context.tt.bodySmall),
            ),
          );
        }

        final item = items[i];
        if (item.isHeader) {
          return DateHeader(date: item.date!, count: item.count!);
        }
        if (item.isNativeAd) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: NativeAdWidget(),
          );
        }
        return EntryCard(
          entry: item.entry!,
          onTap: () => widget.onEntryTap(item.entry!),
          onDelete: () => _deleteEntry(item.entry!),
        );
      },
    ),
    );
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
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.edit_note_outlined,
            size: 48,
            color: cs.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? '해당 조건의 기록이 없어요' : '아직 기록이 없어요',
            style: context.tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter ? '필터를 변경해보세요' : '하단 + 버튼으로 첫 기록을 남겨보세요',
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

// ---------------------------------------------------------------------------
// 최초 사용자 빈 상태 (기록 0건)
// ---------------------------------------------------------------------------

/// 앱을 처음 설치하고 기록이 전혀 없는 신규 유저에게 표시하는 온보딩 빈 상태.
/// CTA 버튼을 누르면 기록 입력 화면으로 바로 이동한다.
class _TimelineNewUserEmptyState extends StatelessWidget {
  final VoidCallback onPressed;
  const _TimelineNewUserEmptyState({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 20),
            Text(
              '아직 기록이 없어요',
              style: context.tt.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 기록을 남겨보세요.\n작은 기록이 쌓여 소중한 데이터가 돼요.',
              style: context.tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('첫 기록 남기기'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 내부 모델 (헤더/항목 구분용)
// ---------------------------------------------------------------------------
class _ListItem {
  final bool isHeader;
  final bool isNativeAd;
  final DateTime? date;
  final int? count;
  final Entry? entry;

  _ListItem.entry(this.entry)
    : isHeader = false,
      isNativeAd = false,
      date = null,
      count = null;

  _ListItem.header(this.date, this.count)
    : isHeader = true,
      isNativeAd = false,
      entry = null;

  _ListItem.nativeAd()
    : isHeader = false,
      isNativeAd = true,
      date = null,
      count = null,
      entry = null;
}
