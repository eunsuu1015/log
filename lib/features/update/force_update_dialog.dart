// 업데이트 안내 팝업.
// forceUpdate=true/false 모두 외부 탭·뒤로가기 차단.
// forceUpdate=true: 스토어 이동만 가능.
// forceUpdate=false: '나중에'(닫기) / '업데이트'(스토어 이동) 선택 가능.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: App Store Connect에 앱 등록 후 실제 ID로 교체
const _kAndroidStoreUrl =
    'https://play.google.com/store/apps/details?id=com.tistory.es1015.poopoolog';
const _kIosStoreUrl =
    'https://apps.apple.com/app/id000000000'; // 실제 App Store ID 필요

/// 업데이트 안내 다이얼로그.
/// [forceUpdate] true/false 모두 외부 탭·뒤로가기를 차단한다.
/// [forceUpdate]가 true이면 '업데이트' 버튼만 표시하고 스토어로 이동한다.
/// [forceUpdate]가 false이면 '나중에' 버튼으로 팝업을 닫고 앱을 계속 이용할 수 있다.
/// [releaseNotes]가 비어 있지 않으면 업데이트 내용을 본문에 표시한다.
class UpdateDialog extends StatelessWidget {
  final String latestVersion;
  final bool forceUpdate;
  final String releaseNotes;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.forceUpdate,
    this.releaseNotes = '',
  });

  Future<void> _openStore() async {
    final url = Uri.parse(Platform.isIOS ? _kIosStoreUrl : _kAndroidStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = releaseNotes.isNotEmpty;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('업데이트 안내'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최신 버전($latestVersion)이 출시되었습니다.\n'
              '업데이트 후 더 나은 서비스를 이용해 보세요.',
              style: const TextStyle(height: 1.6),
            ),
            if (hasNotes) ...[
              const SizedBox(height: 12),
              Text(
                '업데이트 내용',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                releaseNotes,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('나중에'),
            ),
          FilledButton(
            onPressed: _openStore,
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }
}
