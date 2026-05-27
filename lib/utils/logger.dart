// 앱 전역 로거 인스턴스. 개발 중 디버그 로그 출력에 사용한다.
// 프로덕션 빌드에서는 Logger 기본 필터(kReleaseMode 시 무시)가 적용된다.

import 'package:logger/logger.dart';

final logger = Logger(printer: PrettyPrinter(methodCount: 1));
