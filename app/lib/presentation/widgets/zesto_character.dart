library;

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Zesto's expressions, mapped from the mascot triggers that drive
/// [ZestoOverlay] and used for the onboarding debut.
enum ZestoExpression { idle, wave, celebrate, tip }

/// Zesto — the ZeroSpoils avocado mascot, drawn in pure Flutter (no assets) so
/// one rig powers every appearance (onboarding debut + in-app overlay).
///
/// Animations (idle bob, blink, wave) are skipped when the platform asks to
/// reduce motion (or when [animate] is false): the character renders as a
/// calm, static pose. Geometry is authored in a 1024×1024 space and scaled to
/// [size].
class ZestoCharacter extends StatefulWidget {
  const ZestoCharacter({
    super.key,
    this.expression = ZestoExpression.idle,
    this.size = 160,
    this.animate = true,
    this.loop = true,
    this.semanticLabel = 'Zesto',
  });

  final ZestoExpression expression;
  final double size;

  /// When false, no animation runs and a static pose is painted. Callers
  /// should pass `false` when `MediaQuery.disableAnimations` is true.
  final bool animate;

  /// When true (overlay), the idle/bob/blink loop runs continuously. When false
  /// (onboarding debut), it plays a single finite cycle then rests, so the
  /// screen settles (important for `pumpAndSettle` and for not perpetually
  /// animating a permanent page element).
  final bool loop;

  final String semanticLabel;

  @override
  State<ZestoCharacter> createState() => _ZestoCharacterState();
}

class _ZestoCharacterState extends State<ZestoCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animate) _start();
  }

  void _start() => widget.loop ? _loop.repeat() : _loop.forward(from: 0);

  @override
  void didUpdateWidget(covariant ZestoCharacter old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_loop.isAnimating && !_loop.isCompleted) {
      _start();
    } else if (!widget.animate && _loop.isAnimating) {
      _loop.stop();
      _loop.value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _loop,
          builder: (context, _) {
            final t = widget.animate ? _loop.value : 0.0;
            return CustomPaint(
              painter: _ZestoPainter(
                expression: widget.expression,
                t: t,
                animate: widget.animate,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ZestoPainter extends CustomPainter {
  _ZestoPainter({
    required this.expression,
    required this.t,
    required this.animate,
  });

  final ZestoExpression expression;
  final double t; // 0..1 master clock
  final bool animate;

  // palette
  static const _skinTop = Color(0xFF3AA24C);
  static const _skinBot = Color(0xFF1F6F30);
  static const _fleshTop = Color(0xFFEDF5CC);
  static const _fleshBot = Color(0xFFD6E89A);
  static const _pitInner = Color(0xFFCB9255);
  static const _pitOuter = Color(0xFF985D2D);
  static const _pitHi = Color(0xFFE6BE8A);
  static const _limb = Color(0xFF2F9E44);
  static const _limbDark = Color(0xFF23823A);
  static const _pupil = Color(0xFF2B3A1E);
  static const _cheek = Color(0xFFF2A188);
  static const _smile = Color(0xFF3C5A2A);
  static const _stem = Color(0xFF7A5A33);
  static const _leaf = Color(0xFF69BE4D);
  static const _mouthOpen = Color(0xFF7A3B2B);
  static const _tongue = Color(0xFFF0907E);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1024, size.height / 1024);

    final twoPi = 2 * math.pi;
    final bobY = animate ? math.sin(t * twoPi) * 10 : 0.0;
    final wavePhase = animate ? math.sin(t * twoPi * 3) : 0.0;
    // one quick blink per loop, in a short window near the end
    double blink = 0;
    if (animate) {
      const start = 0.86, end = 0.94, mid = 0.90;
      if (t >= start && t <= end) {
        blink = t < mid ? (t - start) / (mid - start) : (end - t) / (end - mid);
      }
    }

    canvas.save();
    canvas.translate(0, bobY);

    _legs(canvas);
    _arms(canvas, wavePhase);
    _body(canvas);
    _stemLeaf(canvas);
    _pit(canvas);
    _cheeks(canvas);
    _eyes(canvas, blink);
    _mouth(canvas);
    _extras(canvas);

    canvas.restore();
  }

  Paint get _fill => Paint()..isAntiAlias = true;

  void _capsule(Canvas c, Offset a, Offset b, double w, Color color) {
    c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );
  }

  void _legs(Canvas c) {
    _capsule(c, const Offset(464, 748), const Offset(458, 842), 48, _limb);
    _capsule(c, const Offset(560, 748), const Offset(566, 842), 48, _limb);
    final foot = _fill..color = _limbDark;
    c.drawOval(
      Rect.fromCenter(center: const Offset(450, 850), width: 84, height: 42),
      foot,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(574, 850), width: 84, height: 42),
      foot,
    );
  }

  void _arms(Canvas c, double wavePhase) {
    final handPaint = _fill..color = _limbDark;
    switch (expression) {
      case ZestoExpression.idle:
      case ZestoExpression.tip:
        _capsule(c, const Offset(356, 556), const Offset(300, 648), 48, _limb);
        c.drawCircle(const Offset(296, 652), 31, handPaint);
        if (expression == ZestoExpression.idle) {
          _capsule(
            c,
            const Offset(668, 556),
            const Offset(724, 648),
            48,
            _limb,
          );
          c.drawCircle(const Offset(728, 652), 31, handPaint);
        } else {
          // tip: right arm raised holding a bulb (bulb drawn in _extras)
          final hand = const Offset(750, 440);
          final path = Path()
            ..moveTo(668, 552)
            ..quadraticBezierTo(726, 500, hand.dx, hand.dy);
          _strokePath(c, path, 48, _limb);
          c.drawCircle(hand, 31, handPaint);
        }
        break;
      case ZestoExpression.wave:
        _capsule(c, const Offset(356, 556), const Offset(300, 648), 48, _limb);
        c.drawCircle(const Offset(296, 652), 31, handPaint);
        final hand = Offset(756 + wavePhase * 16, 420 - wavePhase * 5);
        final path = Path()
          ..moveTo(672, 548)
          ..quadraticBezierTo(734, 496, hand.dx, hand.dy);
        _strokePath(c, path, 48, _limb);
        c.drawCircle(hand, 31, handPaint);
        break;
      case ZestoExpression.celebrate:
        final lp = Path()
          ..moveTo(356, 552)
          ..quadraticBezierTo(300, 500, 286, 432);
        final rp = Path()
          ..moveTo(668, 552)
          ..quadraticBezierTo(724, 500, 738, 432);
        _strokePath(c, lp, 48, _limb);
        _strokePath(c, rp, 48, _limb);
        c.drawCircle(const Offset(282, 426), 31, handPaint);
        c.drawCircle(const Offset(742, 426), 31, handPaint);
        break;
    }
  }

  void _strokePath(Canvas c, Path p, double w, Color color) {
    c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  void _body(Canvas c) {
    final skin = Path()
      ..moveTo(512, 230)
      ..cubicTo(624, 230, 712, 360, 718, 520)
      ..cubicTo(724, 656, 632, 786, 512, 786)
      ..cubicTo(392, 786, 300, 656, 306, 520)
      ..cubicTo(312, 360, 400, 230, 512, 230)
      ..close();
    c.drawPath(
      skin,
      _fill
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skinTop, _skinBot],
        ).createShader(const Rect.fromLTWH(306, 230, 412, 556)),
    );
    final flesh = Path()
      ..moveTo(512, 268)
      ..cubicTo(606, 268, 676, 374, 682, 516)
      ..cubicTo(687, 632, 612, 748, 512, 748)
      ..cubicTo(412, 748, 337, 632, 342, 516)
      ..cubicTo(348, 374, 418, 268, 512, 268)
      ..close();
    c.drawPath(
      flesh,
      _fill
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_fleshTop, _fleshBot],
        ).createShader(const Rect.fromLTWH(337, 268, 345, 480)),
    );
  }

  void _stemLeaf(Canvas c) {
    final stemPaint = _fill..color = _stem;
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(503, 184, 18, 54),
        const Radius.circular(9),
      ),
      stemPaint,
    );
    final leaf = Path()
      ..moveTo(521, 204)
      ..cubicTo(574, 178, 626, 186, 642, 196)
      ..cubicTo(612, 240, 560, 244, 521, 222)
      ..close();
    c.drawPath(leaf, _fill..color = _leaf);
  }

  void _pit(Canvas c) {
    c.drawCircle(
      const Offset(512, 636),
      92,
      _fill
        ..shader =
            const RadialGradient(
              center: Alignment(-0.2, -0.3),
              radius: 0.85,
              colors: [_pitInner, _pitOuter],
            ).createShader(
              Rect.fromCircle(center: const Offset(512, 636), radius: 92),
            ),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(487, 612), width: 64, height: 48),
      _fill
        ..shader = null
        ..color = _pitHi.withValues(alpha: 0.5),
    );
  }

  void _cheeks(Canvas c) {
    final p = _fill
      ..shader = null
      ..color = _cheek.withValues(alpha: 0.55);
    c.drawOval(
      Rect.fromCenter(center: const Offset(418, 476), width: 54, height: 30),
      p,
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(606, 476), width: 54, height: 30),
      p,
    );
  }

  void _eyes(Canvas c, double blink) {
    if (expression == ZestoExpression.celebrate) {
      // happy closed arcs ^^
      final paint = Paint()
        ..color = _pupil
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
      c.drawPath(
        Path()
          ..moveTo(428, 446)
          ..quadraticBezierTo(458, 414, 488, 446),
        paint,
      );
      c.drawPath(
        Path()
          ..moveTo(536, 446)
          ..quadraticBezierTo(566, 414, 596, 446),
        paint,
      );
      return;
    }
    final open = (1 - blink).clamp(0.0, 1.0);
    for (final cx in const [458.0, 566.0]) {
      final ry = 47 * open;
      if (open < 0.16) {
        // closed: a short downward lash line
        _strokePath(
          c,
          Path()
            ..moveTo(cx - 26, 432)
            ..quadraticBezierTo(cx, 444, cx + 26, 432),
          10,
          _pupil,
        );
        continue;
      }
      c.drawOval(
        Rect.fromCenter(center: Offset(cx, 432), width: 76, height: ry * 2),
        _fill
          ..shader = null
          ..color = Colors.white,
      );
      if (open > 0.4) {
        final px = cx + 8;
        c.drawCircle(Offset(px, 446), 19, _fill..color = _pupil);
        c.drawCircle(Offset(cx - 1, 424), 8.5, _fill..color = Colors.white);
        c.drawCircle(Offset(px + 4, 452), 4, _fill..color = Colors.white);
      }
    }
  }

  void _mouth(Canvas c) {
    switch (expression) {
      case ZestoExpression.celebrate:
        final m = Path()
          ..moveTo(474, 498)
          ..quadraticBezierTo(512, 504, 550, 498)
          ..quadraticBezierTo(548, 554, 512, 558)
          ..quadraticBezierTo(476, 554, 474, 498)
          ..close();
        c.drawPath(m, _fill..color = _mouthOpen);
        c.drawOval(
          Rect.fromCenter(
            center: const Offset(512, 540),
            width: 40,
            height: 24,
          ),
          _fill..color = _tongue,
        );
        break;
      case ZestoExpression.tip:
        _strokePath(
          c,
          Path()
            ..moveTo(482, 504)
            ..quadraticBezierTo(512, 528, 542, 504),
          11,
          _smile,
        );
        break;
      case ZestoExpression.idle:
      case ZestoExpression.wave:
        _strokePath(
          c,
          Path()
            ..moveTo(478, 500)
            ..quadraticBezierTo(512, 532, 546, 500),
          11,
          _smile,
        );
        break;
    }
  }

  void _extras(Canvas c) {
    if (expression == ZestoExpression.tip) {
      // glowing bulb above the raised hand
      c.drawCircle(
        const Offset(756, 398),
        30,
        _fill
          ..shader =
              const RadialGradient(
                center: Alignment(0, -0.2),
                colors: [Color(0xFFFFF7D6), Color(0xFFFFD45A)],
              ).createShader(
                Rect.fromCircle(center: const Offset(756, 398), radius: 30),
              ),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(744, 424, 24, 14),
          const Radius.circular(5),
        ),
        _fill
          ..shader = null
          ..color = const Color(0xFFC9A24A),
      );
      final ray = Paint()
        ..color = const Color(0xFFFFD23F)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      c.drawLine(const Offset(716, 372), const Offset(698, 362), ray);
      c.drawLine(const Offset(796, 372), const Offset(814, 362), ray);
      c.drawLine(const Offset(756, 356), const Offset(756, 336), ray);
    } else if (expression == ZestoExpression.celebrate) {
      final twinkle = animate
          ? (0.5 + 0.5 * math.sin(t * 2 * math.pi * 2))
          : 1.0;
      _star(c, const Offset(276, 350), 22, const Color(0xFFFFD23F), twinkle);
      _star(
        c,
        const Offset(748, 330),
        18,
        const Color(0xFFFFD23F),
        1 - twinkle,
      );
      final dot = _fill..shader = null;
      c.drawCircle(
        const Offset(360, 250),
        9,
        dot..color = const Color(0xFF8BD45A),
      );
      c.drawCircle(const Offset(690, 246), 9, dot..color = _cheek);
      c.drawCircle(
        const Offset(300, 470),
        7,
        dot..color = const Color(0xFFFFD23F),
      );
      c.drawCircle(
        const Offset(724, 486),
        7,
        dot..color = const Color(0xFF8BD45A),
      );
    }
  }

  void _star(Canvas c, Offset o, double r, Color color, double op) {
    final p = Path();
    final inner = r * 0.38;
    for (var i = 0; i < 8; i++) {
      final ang = -math.pi / 2 + i * math.pi / 4;
      final rad = i.isEven ? r : inner;
      final pt = o + Offset(math.cos(ang) * rad, math.sin(ang) * rad);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    c.drawPath(
      p,
      _fill
        ..shader = null
        ..color = color.withValues(alpha: op.clamp(0.2, 1.0)),
    );
  }

  @override
  bool shouldRepaint(covariant _ZestoPainter old) =>
      old.t != t || old.expression != expression || old.animate != animate;
}
