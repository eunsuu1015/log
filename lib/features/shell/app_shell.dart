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
      // Remote Config를 한 번만 fetch해 업데이트·공지에 모두 사용한다
      final config = await RemoteConfigService.fetchAppConfig();

      final forceUpdated = await _checkForceUpdate(config);
      if (forceUpdated) return;

      await _handleWidgetAction();
      await _checkAndShowNotice(config);
    });
  }

  /// Remote Config에서 받은 플랫폼별 업데이트 정보로 버전을 비교한다.
  /// latest_version이 현재보다 높으면 팝업을 표시한다.
  /// force_update=true이면 닫기 차단 후 true 반환(이후 로직 중단),
  /// force_update=false이면 확인/취소 팝업 후 false 반환(앱 계속 이용 가능).
  Future<bool> _checkForceUpdate(AppConfig config) async {
    final update = Platform.isIOS ? config.ios : config.android;

    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;

    if (!update.isOutdated(currentVersion)) return false;

    if (mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: !update.forceUpdate,
        builder: (_) => UpdateDialog(
          latestVersion: update.latestVersion,
          forceUpdate: update.forceUpdate,
        ),
      );
    }
    return update.forceUpdate;
  }

  /// Remote Config에서 받은 공지를 확인하고, 사용자가 아직 숨기지 않은 경우 팝업을 표시한다.
  /// [kForceShowNotice]가 true이면 '다시 보지 않음' 여부를 무시하고 항상 표시한다.
  Future<void> _checkAndShowNotice(AppConfig config) async {
    final noticeConfig = config.notice;
    if (noticeConfig.isEmpty) return;

    if (!kForceShowNotice) {
      final prefs = await SharedPreferences.getInstance();
      final dismissedId = prefs.getString(kNoticeDismissedKey);
      if (dismissedId == noticeConfig.id) return;
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
    }
  }

  /// 홈 위젯에서 앱 진입 시 'record' 액션이 있으면 기록 화면을 열고 데이터를 갱신한다.
  Future<void> _handleWidgetAction() async {
    try {
      final action = await _widgetChannel.invokeMethod<String>('getInitialAction');
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
