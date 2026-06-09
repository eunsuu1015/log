// 기분·방문 여부에 따라 얼굴 아이콘을 직접 그리는 CustomPainter.
// MoodIndicator 위젯에서 face 표시 모드일 때 사용된다.

import 'package:flutter/material.dart';
import 'package:poopoolog/core/models/record_model.dart';
import 'package:poopoolog/shared/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// 색상 정의
// ---------------------------------------------------------------------------

class _FaceColors {
  const _FaceColors({
    required this.bg,
    required this.face,
    required this.pupil,
  });
  final Color bg;
  final Color face;
  final Color pupil;

  static _FaceColors forMood(MoodLevel? mood, bool? visited) {
    if (visited == false) {
      return const _FaceColors(
        bg: Color(0xFFEEF1F0),
        face: AppTheme.moodNotVisited,
        pupil: Color(0xFF666666),
      );
    }
    if (visited != true) {
      return const _FaceColors(
        bg: Color(0xFFF0EFEC),
        face: AppTheme.moodNone,
        pupil: Color(0xFF555555),
      );
    }
    return switch (mood) {
      MoodLevel.good => const _FaceColors(
          bg: Color(0xFFEAF3DE),
          face: AppTheme.moodGood,
          pupil: Color(0xFF2A5200),
        ),
      MoodLevel.okay => const _FaceColors(
          bg: Color(0xFFFAEEDA),
          face: AppTheme.moodOkay,
          pupil: Color(0xFF5C3200),
        ),
      MoodLevel.bad => const _FaceColors(
          bg: Color(0xFFFCEBEB),
          face: AppTheme.moodBad,
          pupil: Color(0xFF6B0000),
        ),
      null => const _FaceColors(
          bg: Color(0xFFF0EFEC),
          face: AppTheme.moodNone,
          pupil: Color(0xFF555555),
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// CustomPainter
// ---------------------------------------------------------------------------

/// 기분·방문 여부에 따라 얼굴 아이콘을 커스텀 페인팅하는 Painter.
/// 좋음: 웃는 입, 보통/미입력: 일자 입, 나쁨: 찡그린 입 + 주름진 눈썹.
class MoodFacePainter extends CustomPainter {
  const MoodFacePainter({
    required this.mood,
    required this.visited,
  });

  final MoodLevel? mood;
  final bool? visited;

  @override
  void paint(Canvas canvas, Size size) {
    final c = _FaceColors.forMood(mood, visited);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final bgPaint = Paint()..color = c.bg;
    final facePaint = Paint()..color = c.face;
    final whitePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = c.pupil;
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.095;

    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final faceR = r * 0.78;
    final faceCy = cy - r * 0.055;
    canvas.drawCircle(Offset(cx, faceCy), faceR, facePaint);

    _drawEyes(canvas, cx, faceCy, faceR, whitePaint, pupilPaint);
    _drawMouth(canvas, cx, faceCy, faceR, mouthPaint);

    if (mood == MoodLevel.bad && visited == true) {
      _drawFurrowedBrows(canvas, cx, faceCy, faceR);
    }
  }

  void _drawEyes(Canvas canvas, double cx, double cy, double r,
      Paint whitePaint, Paint pupilPaint) {
    final eyeY = cy - r * 0.18;
    final eyeOffX = r * 0.30;
    final eyeRx = r * 0.145;
    final eyeRy = r * 0.185;

    for (final sign in [-1.0, 1.0]) {
      final ex = cx + sign * eyeOffX;
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(ex, eyeY), width: eyeRx * 2, height: eyeRy * 2),
        whitePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ex + eyeRx * 0.08, eyeY + eyeRy * 0.12),
          width: eyeRx * 1.2,
          height: eyeRy * 1.2,
        ),
        pupilPaint,
      );
      canvas.drawCircle(
        Offset(ex + eyeRx * 0.15, eyeY - eyeRy * 0.1),
        r * 0.045,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawMouth(
      Canvas canvas, double cx, double cy, double r, Paint paint) {
    final mouthY = cy + r * 0.28;
    final mouthHalfW = r * 0.38;

    if (mood == MoodLevel.good && visited == true) {
      final path = Path()
        ..moveTo(cx - mouthHalfW, mouthY - r * 0.06)
        ..quadraticBezierTo(
            cx, mouthY + r * 0.26, cx + mouthHalfW, mouthY - r * 0.06);
      canvas.drawPath(path, paint);
    } else if (mood == MoodLevel.bad && visited == true) {
      final path = Path()
        ..moveTo(cx - mouthHalfW, mouthY + r * 0.06)
        ..quadraticBezierTo(
            cx, mouthY - r * 0.22, cx + mouthHalfW, mouthY + r * 0.06);
      canvas.drawPath(path, paint);
    } else {
      canvas.drawLine(
        Offset(cx - mouthHalfW, mouthY),
        Offset(cx + mouthHalfW, mouthY),
        paint..color = paint.color.withValues(alpha: visited == true ? 1.0 : 0.7),
      );
    }
  }

  /// 나쁨 기분일 때만 추가로 주름진 눈썹을 그린다. paint()에서 mood == bad일 때만 호출된다.
  void _drawFurrowedBrows(
      Canvas canvas, double cx, double cy, double r) {
    final browY = cy - r * 0.46;
    final browOffX = r * 0.30;
    final browHalfW = r * 0.18;
    final browPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = r * 0.07;

    for (final sign in [-1.0, 1.0]) {
      final bx = cx + sign * browOffX;
      final path = Path()
        ..moveTo(bx - browHalfW * sign, browY + r * 0.06)
        ..quadraticBezierTo(
            bx, browY - r * 0.06, bx + browHalfW * sign, browY + r * 0.06);
      canvas.drawPath(path, browPaint);
    }
  }

  @override
  bool shouldRepaint(MoodFacePainter old) =>
      old.mood != mood || old.visited != visited;
}
