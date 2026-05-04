import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 타임라인 탭 루트 위젯. 필터 침 + 기록 리스트로 구성된다.
class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: Text('타임라인'),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_timeline',
        onPressed: () => _openNew(context, ref),
        tooltip: '기록 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 타임라인 리스트
// ---------------------------------------------------------------------------

class _TimelineList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

void _openNew(BuildContext, WidgetRef ref) {}
