// 앱 시작 시 표시하는 공지사항 팝업.
// '확인' 버튼은 단순 닫기, '다시 보지 않음' 선택 시 해당 공지 ID를 SharedPreferences에 저장한다.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notice/notice.dart';

/// 공지사항 팝업 다이얼로그.
/// [notice]의 id를 SharedPreferences에 저장해 다음 실행 시 재표시를 막는다.
class NoticeDialog extends StatelessWidget {
  final Notice notice;

  const NoticeDialog({super.key, required this.notice});

  /// 다시 보지 않음 처리. SharedPreferences에 공지 ID를 저장하고 닫는다.
  Future<void> _dismiss(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kNoticeDismissedKey, notice.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(notice.title),
      content: Text(
        notice.message,
        style: TextStyle(color: cs.onSurfaceVariant, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => _dismiss(context),
          child: Text(
            '다시 보지 않음',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
