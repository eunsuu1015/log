// 업데이트 안내 팝업.
// forceUpdate=true: 닫기·뒤로가기 차단, 스토어 이동만 가능.
// forceUpdate=false: 확인(스토어 이동) / 취소(팝업 닫고 앱 계속 이용) 선택 가능.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: App Store Connect에 앱 등록 후 실제 ID로 교체
const _kAndroidStoreUrl =
    'https://play.google.com/store/apps/details?id=com.tistory.es1015.poopoolog';
const _kIosStoreUrl =
    'https://apps.apple.com/app/id000000000'; // 실제 App Store ID 필요

/// 업데이트 안내 다이얼로그.
/// [forceUpdate]가 true이면 닫기를 차단하고 스토어 이동만 허용한다.
/// [forceUpdate]가 false이면 취소 버튼으로 팝업을 닫고 앱을 계속 이용할 수 있다.
class UpdateDialog extends StatelessWidget {
  final String latestVersion;
  final bool forceUpdate;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    required this.forceUpdate,
  });

  Future<void> _openStore() async {
    final url = Uri.parse(Platform.isIOS ? _kIosStoreUrl : _kAndroidStoreUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !forceUpdate,
      child: AlertDialog(
        title: const Text('업데이트 안내'),
        content: Text(
          '최신 버전($latestVersion)이 출시되었습니다.\n'
          '업데이트 후 더 나은 서비스를 이용해 보세요.',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
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
