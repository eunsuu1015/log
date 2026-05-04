import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poopoolog/features/more/more_screen.dart';

import '../calendar/calendar_screen.dart';
import '../stats/StatsScreen.dart';
import '../timeline/timeline_screen.dart';

final _currentTabProvider = StateProvider<int>((ref) => 0);

/// 앱의 최상위 네비게이션 컨테이너
/// 캘린더·기록·통계 탭을 IndexedStack으로 유지하며 NavigationBar로 전환한다.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  // build() 밖에 선언해 탭 전환마다 리스트가 재생성되지 않게 함
  static const _screens = [
    CalendarScreen(),
    TimelineScreen(),
    StatsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(_currentTabProvider);

    return Scaffold(
      body: IndexedStack(index: currentTab, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentTab,
        onDestinationSelected: (index) =>
            ref.read(_currentTabProvider.notifier).state = index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_timeline_outlined),
            selectedIcon: Icon(Icons.view_timeline),
            label: '기록',
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
    );
  }
}
