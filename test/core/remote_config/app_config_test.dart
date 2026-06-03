// AppConfig JSON 파싱 단위 테스트
// fromJsonString, 기본값 처리, NoticeConfig.isEmpty, AppConfig.fallback을 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:poopoolog/core/remote_config/app_config.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // AppConfig.fromJsonString — 정상 파싱
  // ─────────────────────────────────────────────────────────────────────────

  group('AppConfig.fromJsonString — 정상 파싱', () {
    const fullJson = '''
{
  "notice": {
    "id": "notice-001",
    "title": "서버 점검",
    "message": "오늘 오전 2시에 점검이 있습니다.",
    "notice_date": "2026-05-01",
    "created_at": "2026-04-30",
    "show": 2
  },
  "android": {
    "latest_version": "1.2.3",
    "force_update": true,
    "show": 3
  },
  "ios": {
    "latest_version": "1.1.0",
    "force_update": false,
    "show": 0
  }
}
''';

    late AppConfig config;
    setUp(() => config = AppConfig.fromJsonString(fullJson));

    test('notice.id 파싱', () => expect(config.notice.id, 'notice-001'));
    test('notice.title 파싱', () => expect(config.notice.title, '서버 점검'));
    test('notice.message 파싱', () => expect(config.notice.message, '오늘 오전 2시에 점검이 있습니다.'));
    test('notice.noticeDate 파싱', () => expect(config.notice.noticeDate, '2026-05-01'));
    test('notice.createdAt 파싱', () => expect(config.notice.createdAt, '2026-04-30'));
    test('notice.show 파싱', () => expect(config.notice.show, 2));

    test('android.latestVersion 파싱', () => expect(config.android.latestVersion, '1.2.3'));
    test('android.forceUpdate = true 파싱', () => expect(config.android.forceUpdate, isTrue));
    test('android.show 파싱', () => expect(config.android.show, 3));

    test('ios.latestVersion 파싱', () => expect(config.ios.latestVersion, '1.1.0'));
    test('ios.forceUpdate = false 파싱', () => expect(config.ios.forceUpdate, isFalse));
    test('ios.show = 0 파싱', () => expect(config.ios.show, 0));
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AppConfig.fromJsonString — 필드 누락 시 기본값
  // ─────────────────────────────────────────────────────────────────────────

  group('AppConfig.fromJsonString — 누락 필드 기본값', () {
    test('notice 필드 없으면 빈 문자열 기본값', () {
      final config = AppConfig.fromJsonString('{"android":{},"ios":{}}');
      expect(config.notice.id, '');
      expect(config.notice.title, '');
      expect(config.notice.message, '');
    });

    test('android 없으면 latest_version = "1.0.0"', () {
      final config = AppConfig.fromJsonString('{"notice":{},"ios":{}}');
      expect(config.android.latestVersion, '1.0.0');
    });

    test('android force_update 누락 → false', () {
      final config = AppConfig.fromJsonString('{"notice":{},"android":{"latest_version":"2.0.0"},"ios":{}}');
      expect(config.android.forceUpdate, isFalse);
    });

    test('ios 없으면 latest_version = "1.0.0"', () {
      final config = AppConfig.fromJsonString('{"notice":{},"android":{}}');
      expect(config.ios.latestVersion, '1.0.0');
    });

    test('show 필드 누락 → 기본값 0', () {
      final config = AppConfig.fromJsonString('{"notice":{"id":"n1"},"android":{},"ios":{}}');
      expect(config.notice.show, 0);
      expect(config.android.show, 0);
      expect(config.ios.show, 0);
    });

    test('빈 JSON 객체 → 모든 필드 기본값', () {
      final config = AppConfig.fromJsonString('{}');
      expect(config.notice.id, '');
      expect(config.android.latestVersion, '1.0.0');
      expect(config.android.forceUpdate, isFalse);
      expect(config.android.show, 0);
      expect(config.ios.latestVersion, '1.0.0');
      expect(config.ios.forceUpdate, isFalse);
      expect(config.ios.show, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // NoticeConfig.isEmpty
  // ─────────────────────────────────────────────────────────────────────────

  group('NoticeConfig.isEmpty', () {
    test('id가 빈 문자열이면 isEmpty = true', () {
      const notice = NoticeConfig(id: '', title: '제목', message: '내용', noticeDate: '', createdAt: '', show: 0);
      expect(notice.isEmpty, isTrue);
    });

    test('id가 있으면 isEmpty = false', () {
      const notice = NoticeConfig(id: 'n-1', title: '제목', message: '내용', noticeDate: '', createdAt: '', show: 1);
      expect(notice.isEmpty, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AppConfig.fallback
  // ─────────────────────────────────────────────────────────────────────────

  group('AppConfig.fallback', () {
    test('notice.isEmpty = true (공지 없음)', () {
      expect(AppConfig.fallback.notice.isEmpty, isTrue);
    });

    test('notice.show = 0', () {
      expect(AppConfig.fallback.notice.show, 0);
    });

    test('android.latestVersion = "0.1.0"', () {
      expect(AppConfig.fallback.android.latestVersion, '0.1.0');
    });

    test('android.forceUpdate = false', () {
      expect(AppConfig.fallback.android.forceUpdate, isFalse);
    });

    test('android.show = 0', () {
      expect(AppConfig.fallback.android.show, 0);
    });

    test('ios.latestVersion = "0.1.0"', () {
      expect(AppConfig.fallback.ios.latestVersion, '0.1.0');
    });

    test('ios.forceUpdate = false', () {
      expect(AppConfig.fallback.ios.forceUpdate, isFalse);
    });

    test('ios.show = 0', () {
      expect(AppConfig.fallback.ios.show, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // isOutdated 버전 비교
  // ─────────────────────────────────────────────────────────────────────────

  group('UpdateConfig.isOutdated()', () {
    UpdateConfig cfg(String latest) =>
        UpdateConfig(latestVersion: latest, forceUpdate: false);
    test('동일 버전 → false', () => expect(cfg('1.0.0').isOutdated('1.0.0'), isFalse));
    test('현재가 더 높음 → false', () => expect(cfg('1.9.9').isOutdated('2.0.0'), isFalse));
    test('patch만 낮음 → true', () => expect(cfg('1.0.1').isOutdated('1.0.0'), isTrue));
    test('minor가 낮음 → true', () => expect(cfg('1.1.0').isOutdated('1.0.5'), isTrue));
    test('major가 낮음 → true', () => expect(cfg('1.0.0').isOutdated('0.9.9'), isTrue));
    test('잘못된 버전 문자열 → false (예외 없음)', () => expect(cfg('1.0.0').isOutdated('bad'), isFalse));
  });
}
