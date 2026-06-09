// 앱의 최상위 탭 컨테이너. 캘린더·타임라인·통계·더보기 4개 탭을 관리한다.
// 앱 시작 시: 강제 업데이트 확인 → 공지사항 팝업 → 홈 위젯 액션 순서로 처리한다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:poopoolog/features/calendar/calendar_provider.dart';
import 'package:poopoolog/features/more/more_screen.dart';
import 'package:poopoolog/features/record/record_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/debug/debug_flags.dart';
import '../../core/notice/notice.dart';
import '../../core/remote_config/app_config.dart';
import '../../core/remote_config/remote_config_service.dart';
import '../calendar/calendar_screen.dart';
import '../notice/notice_dialog.dart';
import '../record/record_screen.dart';
import '../stats/stats_screen.dart';
import '../timeline/timeline_provider.dart';
import '../timeline/timeline_screen.dart';
import '../update/force_update_dialog.dart';

final currentTabProvider = StateProvider<int>((ref) => 0);

const _widgetChannel = MethodChannel('com.tistory.es1015.poopoolog/widget');

/// 앱의 최상위 네비게이션 컨테이너
/// 캘린더·기록·통계 탭을 IndexedStack으로 유지하며 NavigationBar로 전환한다.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _screens = [
    CalendarScreen(),
    TimelineScreen(),
    StatsScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final config = await ref.read(appConfigProvider.future);

      final forceUpdated = await _checkForceUpdate(config);
      if (forceUpdated) return;

      await _handleWidgetAction();
      await _checkAndShowNotice(config);
    });
  }

  /// Remote Config에서 받은 플랫폼별 업데이트 정보로 버전을 비교한다.
  /// latest_version이 현재보다 높을 때 show 횟수에 따라 팝업 표시 여부를 결정한다.
  /// force_update=true이면 show 값 무관하게 항상 표시하며 닫기 차단 후 true 반환(이후 로직 중단),
  /// force_update=false이면 확인/취소 팝업 후 false 반환(앱 계속 이용 가능).
  Future<bool> _checkForceUpdate(AppConfig config) async {
    final update = Platform.isIOS ? config.ios : config.android;
    final platform = Platform.isIOS ? 'ios' : 'android';

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    if (!update.isOutdated(currentVersion)) return false;

    // force_update=false 이고 show >= 1인 경우 노출 횟수 확인
    // 단일 고정 키로 관리하며, 플랫폼_버전 조합이 바뀌면 카운트를 0으로 리셋한다.
    if (!update.forceUpdate && update.show >= 1) {
      final prefs = await SharedPreferences.getInstance();
      final currentId = '${platform}_${update.latestVersion}';
      final savedId = prefs.getString(kUpdateShowCountIdKey);
      final shownCount = savedId == currentId
          ? (prefs.getInt(kUpdateShowCountKey) ?? 0)
          : 0;
      if (shownCount >= update.show) return false;
    }

    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => UpdateDialog(
          latestVersion: update.latestVersion,
          forceUpdate: update.forceUpdate,
          releaseNotes: update.releaseNotes,
        ),
      );

      // 팝업을 실제로 표시한 경우 노출 횟수 증가 (force_update=false + show >= 1인 경우만)
      if (!update.forceUpdate && update.show >= 1) {
        final prefs = await SharedPreferences.getInstance();
        final currentId = '${platform}_${update.latestVersion}';
        final savedId = prefs.getString(kUpdateShowCountIdKey);
        final shownCount = savedId == currentId
            ? (prefs.getInt(kUpdateShowCountKey) ?? 0)
            : 0;
        await prefs.setString(kUpdateShowCountIdKey, currentId);
        await prefs.setInt(kUpdateShowCountKey, shownCount + 1);
      }
    }
    return update.forceUpdate;
  }

  /// Remote Config에서 받은 공지를 확인하고 팝업 표시 여부를 결정한다.
  /// show == 0이면 항상 표시, show >= 1이면 해당 횟수만큼만 표시한다.
  /// 사용자가 '다시 보지 않음'을 선택한 공지는 이후 노출하지 않는다.
  /// [kForceShowNotice]가 true이면 모든 조건을 무시하고 항상 표시한다.
  Future<void> _checkAndShowNotice(AppConfig config) async {
    final noticeConfig = config.notice;
    if (noticeConfig.isEmpty) return;

    if (!kForceShowNotice) {
      final prefs = await SharedPreferences.getInstance();

      // '다시 보지 않음' 선택 여부 확인
      final dismissedId = prefs.getString(kNoticeDismissedKey);
      if (dismissedId == noticeConfig.id) return;

      // show >= 1인 경우 노출 횟수 확인
      // 단일 고정 키로 관리하며, 공지 ID가 바뀌면 카운트를 0으로 리셋한다.
      if (noticeConfig.show >= 1) {
        final savedId = prefs.getString(kNoticeShowCountIdKey);
        final shownCount = savedId == noticeConfig.id
            ? (prefs.getInt(kNoticeShowCountKey) ?? 0)
            : 0;
        if (shownCount >= noticeConfig.show) return;
      }
    }

    final notice = Notice(
      id: noticeConfig.id,
      title: noticeConfig.title,
      message: noticeConfig.message,
    );

    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => NoticeDialog(notice: notice),
      );

      // 팝업을 실제로 표시한 경우 노출 횟수 증가 (show >= 1인 경우만)
      if (!kForceShowNotice && noticeConfig.show >= 1) {
        final prefs = await SharedPreferences.getInstance();
        final savedId = prefs.getString(kNoticeShowCountIdKey);
        final shownCount = savedId == noticeConfig.id
            ? (prefs.getInt(kNoticeShowCountKey) ?? 0)
            : 0;
        await prefs.setString(kNoticeShowCountIdKey, noticeConfig.id);
        await prefs.setInt(kNoticeShowCountKey, shownCount + 1);
      }
    }
  }

  /// 홈 위젯에서 앱 진입 시 'record' 액션이 있으면 기록 화면을 열고 데이터를 갱신한다.
  Future<void> _handleWidgetAction() async {
    try {
      final action = await _widgetChannel.invokeMethod<String>(
        'getInitialAction',
      );
      if (action == 'record' && mounted) {
        ref.invalidate(recordFormProvider(null));
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RecordScreen(),
            fullscreenDialog: true,
          ),
        );
        ref.invalidate(timelineProvider);
        final month = ref.read(calendarFocusedMonthProvider);
        ref.invalidate(monthlyEntriesProvider(month));
      }
    } catch (_) {
      // 위젯 채널 미지원 환경(iOS 등)에서 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: IndexedStack(index: currentTab, children: _screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.6),
          ),
          NavigationBar(
            selectedIndex: currentTab,
            onDestinationSelected: (index) =>
                ref.read(currentTabProvider.notifier).state = index,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: '캘린더',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_timeline_outlined),
                selectedIcon: Icon(Icons.view_timeline),
                label: '타임라인',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: '통계',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz_outlined),
                selectedIcon: Icon(Icons.more_horiz),
                label: '더보기',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
