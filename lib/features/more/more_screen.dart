import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/debug/debug_flags.dart';
import '../../core/remote_config/remote_config_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../core/iap/iap_provider.dart';
import '../../core/models/mood_display_provider.dart';
import '../../core/settings/display_settings.dart';
import '../calendar/calendar_provider.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/app_shell.dart';
import '../stats/stats_provider.dart';
import '../timeline/timeline_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

const _kAndroidStoreUrl =
    'https://play.google.com/store/apps/details?id=com.tistory.es1015.poopoolog';
const _kIosStoreUrl = 'https://apps.apple.com/app/id000000000';

/// SharedPreferences 저장 키
const kThemeModeKey = 'theme_mode';

/// 앱 전체 테마 모드. main.dart에서 초기값을 SharedPreferences로 주입한다.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// 앱 버전 문자열 (package_info_plus)
final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

/// 피드백 폼 URL — dart-define의 FEEDBACK_URL 값. 미설정 시 기본 URL 사용.
final feedbackUrlProvider = Provider<String>(
  (ref) => const String.fromEnvironment(
    'FEEDBACK_URL',
    defaultValue: 'https://forms.gle/n853LbpQMYwstytE7',
  ),
);

/// 개인정보처리방침 URL — dart-define의 PRIVACY_POLICY_URL 값. 미설정 시 기본 URL 사용.
final privacyPolicyUrlProvider = Provider<String>(
  (ref) => const String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://www.notion.so/366bfa1e647780e0a967f2409129fdf9',
  ),
);

String _themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => '기기 설정 사용',
  ThemeMode.dark => '다크 모드',
  ThemeMode.light => '라이트 모드',
};

String _moodDisplayLabel(MoodDisplay display) => switch (display) {
  MoodDisplay.dot => '색상 도트',
  MoodDisplay.face => '얼굴 아이콘',
};

// ---------------------------------------------------------------------------
// MoreScreen
// ---------------------------------------------------------------------------

class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  int _versionTapCount = 0;

  @override
  void initState() {
    super.initState();
    ref.listenManual(purchaseNotifierProvider, (prev, next) {
      if (!mounted) return;
      if (next == IAPStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구매를 처리하는 중 오류가 발생했어요. 다시 시도해 주세요.')),
        );
        ref.read(purchaseNotifierProvider.notifier).clearError();
      } else if (next == IAPStatus.canceled) {
        // 구매 취소 — 조용히 idle로 복귀 (스낵바 없음)
        ref.read(purchaseNotifierProvider.notifier).clearCanceled();
      } else if (prev == IAPStatus.loading && next == IAPStatus.idle) {
        if (ref.read(adsRemovedProvider)) {
          // 구매 또는 복원 성공 → 팝업
          _showPurchaseSuccessDialog();
        } else {
          // restore() 완료 후 복원할 내역이 없는 경우
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이전 구매 내역을 찾을 수 없어요.')));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final moodDisplay = ref.watch(moodDisplayProvider);
    final startSunday = ref.watch(startWeekdaySundayProvider);
    final adsRemoved = ref.watch(adsRemovedProvider);
    final iapStatus = ref.watch(purchaseNotifierProvider);
    final versionAsync = ref.watch(_appVersionProvider);
    final configAsync = ref.watch(appConfigProvider);
    final config = configAsync.valueOrNull;
    final version = versionAsync.valueOrNull;
    final isOutdated = config != null && version != null
        ? (Platform.isIOS ? config.ios : config.android).isOutdated(version)
        : false;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow.withValues(alpha: 0.7),
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLow.withValues(alpha: 0.7),
        title: const Text('더보기'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ── 결제 ──────────────────────────────────────────────────────
          _RemoveAdsBanner(
            adsRemoved: adsRemoved,
            iapStatus: iapStatus,
            onBuy: () => ref.read(purchaseNotifierProvider.notifier).buy(),
            onRestore: () =>
                ref.read(purchaseNotifierProvider.notifier).restore(),
          ),
          const SizedBox(height: 20),

          // ── 설정 ──────────────────────────────────────────────────────
          const _SectionTitle(label: '설정'),
          _SectionCard(
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: '다크모드',
                trailing: Text(
                  _themeModeLabel(themeMode),
                  style: context.tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
                onTap: () => _showThemePicker(themeMode),
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.face_outlined,
                title: '기분 표시 방식',
                trailing: Text(
                  _moodDisplayLabel(moodDisplay),
                  style: context.tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
                onTap: () => _showMoodDisplayPicker(moodDisplay),
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.calendar_today_outlined,
                title: '주 시작 요일',
                trailing: Text(
                  startSunday ? '일요일' : '월요일',
                  style: context.tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.grey,
                  ),
                ),
                onTap: () => _showStartWeekdayPicker(startSunday),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 지원 ──────────────────────────────────────────────────────
          const _SectionTitle(label: '지원'),
          _SectionCard(
            children: [
              _SettingsTile(
                icon: Icons.menu_book_outlined,
                title: '앱 가이드',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(fromSettings: true),
                    fullscreenDialog: true,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.mail_outline,
                title: '피드백 보내기',
                onTap: _launchContactForm,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 데이터 ──────────────────────────────────────────────────────
          const _SectionTitle(label: '데이터'),
          _SectionCard(
            children: [
              _SettingsTile(
                icon: Icons.upload_outlined,
                title: '내보내기 (CSV)',
                onTap: _exportCsv,
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.download_outlined,
                title: '가져오기 (CSV)',
                onTap: _importCsv,
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.delete_forever_outlined,
                title: '데이터 초기화',
                titleColor: cs.error,
                iconColor: cs.error,
                onTap: _confirmReset,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 정보 ──────────────────────────────────────────────────────
          const _SectionTitle(label: '정보'),
          _SectionCard(
            children: [
              if (config != null && !config.notice.isEmpty) ...[
                _SettingsTile(
                  icon: Icons.campaign_outlined,
                  title: '공지사항',
                  onTap: () => _showNoticeDialog(config.notice.title, config.notice.message),
                ),
                const Divider(height: 1, indent: 52),
              ],
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                onTap: _launchPrivacyPolicy,
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: '오픈소스 라이선스',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: '푸푸로그',
                  applicationLegalese: '© 2026 은수우우. All rights reserved.',
                ),
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.info_outline,
                title: '앱 버전',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      version != null ? 'v $version' : '-',
                      style: context.tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                    if (isOutdated) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '업데이트',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: isOutdated ? _launchStore : _onVersionTap,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 설정 피커
  // ---------------------------------------------------------------------------

  /// 공지사항 내용을 확인 버튼만 있는 일반 다이얼로그로 표시한다.
  void _showNoticeDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 플랫폼별 앱 스토어로 이동한다.
  Future<void> _launchStore() async {
    final url = Platform.isIOS ? _kIosStoreUrl : _kAndroidStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showBottomSheet(Widget Function(BuildContext) builder) {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: builder,
    );
  }

  void _showThemePicker(ThemeMode current) {
    _showBottomSheet(
      (_) => _ListPickerSheet(
        title: '다크모드',
        labels: ThemeMode.values.map(_themeModeLabel).toList(),
        selectedIndex: current.index,
        onSelected: (i) async {
          final mode = ThemeMode.values[i];
          ref.read(themeModeProvider.notifier).state = mode;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(kThemeModeKey, mode.index);
        },
      ),
    );
  }

  void _showMoodDisplayPicker(MoodDisplay current) {
    _showBottomSheet(
      (_) => _ListPickerSheet(
        title: '기분 표시 방식',
        labels: MoodDisplay.values.map(_moodDisplayLabel).toList(),
        selectedIndex: current.index,
        onSelected: (i) async {
          final display = MoodDisplay.values[i];
          ref.read(moodDisplayProvider.notifier).state = display;
          await saveMoodDisplay(display);
        },
      ),
    );
  }

  void _showStartWeekdayPicker(bool startSunday) {
    _showBottomSheet(
      (_) => _ListPickerSheet(
        title: '주 시작 요일',
        labels: const ['월요일', '일요일'],
        selectedIndex: startSunday ? 1 : 0,
        onSelected: (i) async {
          final value = i == 1;
          ref.read(startWeekdaySundayProvider.notifier).state = value;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(kStartWeekdaySundayKey, value);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 다이얼로그 헬퍼
  // ---------------------------------------------------------------------------

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    String confirmLabel = '확인',
    bool isDestructive = false,
    bool isBarrierDismissible = true,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: isBarrierDismissible,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive
                ? TextButton.styleFrom(
                    foregroundColor: Theme.of(ctx).colorScheme.error,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// 인앱결제(광고 제거) 구매 또는 복원 성공 시 결과를 팝업으로 알린다.
  void _showPurchaseSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('구매 완료'),
        content: const Text('광고가 제거됐어요!\n앞으로 광고 없이 앱을 이용하실 수 있어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CSV 내보내기
  // ---------------------------------------------------------------------------

  Future<void> _exportCsv() async {
    final db = ref.read(appDatabaseProvider);
    final entries = await db.getEntriesInRange(DateTime(2000), DateTime(2200));

    if (entries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내보낼 기록이 없어요')));
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('recordedAt,visited,mood,memo');
    for (final e in entries) {
      buffer.writeln(
        [
          e.recordedAt.toIso8601String(),
          e.visited?.toString() ?? '',
          e.mood?.toString() ?? '',
          _escapeCsvField(e.memo),
        ].join(','),
      );
    }

    final now = DateTime.now();
    final ts =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final bytes = utf8.encode(buffer.toString());

    // 사용자가 내 파일 앱에서 저장 위치를 직접 선택한다.
    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: '저장 위치 선택',
      fileName: 'poopoolog_$ts.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
      bytes: Uint8List.fromList(bytes),
    );

    if (!mounted) return;
    if (savedPath != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장됐어요')));
    }
  }

  // ---------------------------------------------------------------------------
  // CSV 가져오기
  // ---------------------------------------------------------------------------

  Future<void> _importCsv() async {
    // 1. 파일 선택
    // FileType.any 사용 — FileType.custom은 Google Drive 등 외부 저장소에서
    // MIME 타입 불일치로 CSV 파일이 표시되지 않는 문제가 있다.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    // 2. 확장자 검증 (.csv만 허용)
    final name = result.files.first.name.toLowerCase();
    if (!name.endsWith('.csv')) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CSV 파일만 가져올 수 있어요')));
      return;
    }

    // 3. 바이트 읽기
    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('파일을 읽을 수 없어요')));
      return;
    }

    // 3. UTF-8 디코딩
    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일 인코딩이 올바르지 않아요 (UTF-8만 지원)')),
      );
      return;
    }

    // 4. 줄 분리 + 빈 줄 제거
    final lines = content
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('가져올 데이터가 없어요')));
      return;
    }

    // 5. 확인 다이얼로그
    if (!mounted) return;
    final confirmed = await _showConfirmDialog(
      title: '데이터 가져오기',
      content:
          '동일한 시간의 기록이 있으면 덮어쓰고, 없으면 새로 추가합니다.\n'
          '기존 기록은 삭제되지 않아요.\n\n'
          '계속하시겠어요?',
      confirmLabel: '가져오기',
      isBarrierDismissible: false,
    );
    if (!confirmed) return;

    if (!mounted) return;
    _showLoadingDialog('가져오는 중...');

    // 6. 헤더 기반 컬럼 인덱스 맵 구성 (버전업으로 컬럼이 추가·누락돼도 안전)
    final header = _parseCsvLine(lines[0]);
    final colIndex = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      colIndex[header[i].trim()] = i;
    }

    String? getField(List<String> fields, String col) {
      final idx = colIndex[col];
      if (idx == null || idx >= fields.length) return null;
      final v = fields[idx].trim();
      return v.isEmpty ? null : v;
    }

    // 7. 행별 upsert
    final db = ref.read(appDatabaseProvider);
    var newAddedCount = 0;
    var overwrittenCount = 0;
    var errorCount = 0;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      try {
        final fields = _parseCsvLine(line);

        final rawTime = getField(fields, 'recordedAt');
        if (rawTime == null) {
          errorCount++;
          continue;
        }

        final recordedAt = DateTime.parse(rawTime);
        final visitedRaw = getField(fields, 'visited');
        final visited = visitedRaw == null
            ? null
            : visitedRaw.toLowerCase() == 'true';
        final moodRaw = getField(fields, 'mood');
        final mood = moodRaw == null ? null : int.tryParse(moodRaw);
        final memo = getField(fields, 'memo');

        final isNewData = await db.upsertEntryByTime(
          EntriesCompanion(
            recordedAt: Value(recordedAt),
            visited: Value(visited),
            mood: Value(mood),
            memo: Value(memo),
          ),
        );
        if (isNewData) {
          newAddedCount++;
        } else {
          overwrittenCount++;
        }
      } catch (_) {
        errorCount++;
      }
    }

    _invalidateAll();

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('데이터 가져오기 완료'),
          content: Text(
            '중복된 \'$overwrittenCount개\' 기록을 제외하고,'
            '\n$newAddedCount개\' 기록을 가져왔어요.'
            '${errorCount > 0 ? '\n($errorCount개 오류 발생)' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //       '중복된 \'$overwrittenCount개\' 기록을 제외하고, \'$newAddedCount개\' 기록을 가져왔어요.'
    //       '${errorCount > 0 ? ' ($errorCount개 오류)' : ''}',
    //     ),
    //   ),
    // );
  }

  // ---------------------------------------------------------------------------
  // CSV 유틸
  // ---------------------------------------------------------------------------

  static String _escapeCsvField(String? value) {
    if (value == null || value.isEmpty) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var inQuotes = false;
    final field = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == ',' && !inQuotes) {
        fields.add(field.toString());
        field.clear();
      } else {
        field.write(c);
      }
    }
    fields.add(field.toString());
    return fields;
  }

  // ---------------------------------------------------------------------------
  // 기타 액션
  // ---------------------------------------------------------------------------

  /// 피드백 폼 URL을 열거나, URL 미설정 시 아무 동작도 하지 않는다
  Future<void> _launchContactForm() async {
    final url = ref.read(feedbackUrlProvider);
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 개인정보처리방침 URL을 열거나, URL 미설정 시 아무 동작도 하지 않는다
  Future<void> _launchPrivacyPolicy() async {
    final url = ref.read(privacyPolicyUrlProvider);
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmReset() async {
    final confirmed = await _showConfirmDialog(
      title: '데이터 초기화',
      content: '모든 기록이 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.\n\n정말 삭제하시겠습니까?',
      confirmLabel: '삭제',
      isDestructive: true,
    );
    if (!confirmed) return;

    final db = ref.read(appDatabaseProvider);
    await db.deleteAllEntries();
    _invalidateAll();

    final now = DateTime.now();
    ref.read(selectedDayProvider.notifier).state = now;
    ref.read(calendarFocusedMonthProvider.notifier).state = DateTime(
      now.year,
      now.month,
    );
    ref.read(currentTabProvider.notifier).state = 0;
  }

  void _onVersionTap() {
    if (kAppVersionAddData) {
      _versionTapCount++;
      if (_versionTapCount >= 11) {
        _versionTapCount = 0;
        _confirmGenerateTestData();
      }
    }
  }

  Future<void> _confirmGenerateTestData() async {
    final confirmed = await _showConfirmDialog(
      title: '테스트 데이터 추가',
      content: '2026년 5월부터 오늘까지\n랜덤 기록을 추가할까요?',
      confirmLabel: '추가',
    );
    if (!confirmed || !mounted) return;

    _showLoadingDialog('데이터 생성 중...');
    await _generateTestData();

    if (!mounted) return;
    Navigator.pop(context);
    _invalidateAll();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('테스트 데이터가 추가됐어요')));
  }

  Future<void> _generateTestData() async {
    final db = ref.read(appDatabaseProvider);
    final rng = Random();
    const memos = [
      '쾌변',
      '설사',
      '묽음',
      '배아픔',
      '잔변감',
      '급했음',
      '식후',
      '공복',
      '스트레스',
      '운동 후',
      '냄새 심함',
      '냄새 없음',
      '딱딱함',
    ];

    final start = DateTime(2026, 5, 1);
    final today = DateTime.now();

    var day = start;
    while (!day.isAfter(today)) {
      final count = rng.nextInt(2);
      for (int i = 0; i < count; i++) {
        final hour = rng.nextInt(24);
        final minute = rng.nextInt(60);
        final second = rng.nextInt(60);
        final recordedAt = DateTime(
          day.year,
          day.month,
          day.day,
          hour,
          minute,
          second,
        );
        final visited = rng.nextBool();
        final mood = visited ? rng.nextInt(3) : null;
        final memoRaw = rng.nextInt(8);
        final memo = memoRaw < 2 ? null : memos[memoRaw - 2];

        await db.insertEntry(
          EntriesCompanion(
            recordedAt: Value(recordedAt),
            visited: Value(visited),
            mood: Value(mood),
            memo: Value(memo),
          ),
        );
      }
      day = day.add(const Duration(days: 1));
    }
  }

  void _invalidateAll() {
    ref.invalidate(timelineProvider);
    ref.invalidate(monthlyEntriesProvider);
    ref.invalidate(statsResultProvider);
    ref.invalidate(earliestEntryDateProvider);
  }
}

// ---------------------------------------------------------------------------
// 바텀시트 위젯
// ---------------------------------------------------------------------------

class _ListPickerSheet extends StatelessWidget {
  final String title;
  final List<String> labels;
  final int selectedIndex;
  final void Function(int) onSelected;

  const _ListPickerSheet({
    required this.title,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const _DragHandle(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              title,
              style: context.tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          for (int i = 0; i < labels.length; i++)
            ListTile(
              title: Text(labels[i]),
              trailing: selectedIndex == i
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                onSelected(i);
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.outlineVariant,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

// ---------------------------------------------------------------------------
// 광고 제거 구매 배너
// ---------------------------------------------------------------------------

class _RemoveAdsBanner extends StatelessWidget {
  final bool adsRemoved;
  final IAPStatus iapStatus;
  final VoidCallback onBuy;
  final VoidCallback onRestore;

  const _RemoveAdsBanner({
    required this.adsRemoved,
    required this.iapStatus,
    required this.onBuy,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLoading = iapStatus == IAPStatus.loading;

    if (adsRemoved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: cs.primary, size: 20),
            const SizedBox(width: 10),
            Text(
              '광고 없이 앱을 이용 중이에요',
              style: context.tt.labelLarge?.copyWith(color: cs.primary),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: cs.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '광고 없애기',
                style: context.tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: isLoading ? null : onBuy,
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Text('₩2,900'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('앱 내 모든 광고를 영구적으로 제거해요', style: context.tt.bodySmall),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: isLoading ? null : onRestore,
            child: Text(
              '구매 복원',
              style: context.tt.bodySmall?.copyWith(
                color: cs.primary.withValues(alpha: 0.8),
                decoration: TextDecoration.underline,
                decorationColor: cs.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(
      label,
      style: context.tt.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor ?? cs.onSurfaceVariant),
      title: Text(
        title,
        style: context.tt.bodyMedium?.copyWith(color: titleColor),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, size: 18, color: cs.outlineVariant)
              : null),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 24,
    );
  }
}
