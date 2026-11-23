import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Butoi maskotu: boğa başlı küçük robot (boynuzlar, kulaklar, anten, yüz plakası). Dış varlık yok, tamamen çizim.
/// [dusunuyor] → gözler yukarı bakar, antenin ışığı yanıp söner ve baş hafifçe sallanır.
class ButoiMaskot extends StatefulWidget {
  const ButoiMaskot({super.key, this.boyut = 40, this.dusunuyor = false, this.mutlu = false});
  final double boyut;
  final bool dusunuyor;
  final bool mutlu;

  @override
  State<ButoiMaskot> createState() => _ButoiMaskotState();
}

class _ButoiMaskotState extends State<ButoiMaskot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.dusunuyor) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant ButoiMaskot eski) {
    super.didUpdateWidget(eski);
    if (widget.dusunuyor && !_c.isAnimating) _c.repeat();
    if (!widget.dusunuyor && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        final sallan = widget.dusunuyor ? math.sin(t * 2 * math.pi) : 0.0;
        return Transform.rotate(
          angle: sallan * 0.06,
          child: Transform.translate(
            offset: Offset(0, widget.dusunuyor ? -2 * sallan.abs() : 0),
            child: CustomPaint(
              size: Size.square(widget.boyut),
              painter: _MaskotBoyaci(dusunuyor: widget.dusunuyor, mutlu: widget.mutlu, faz: t),
            ),
          ),
        );
      },
    );
  }
}

class _MaskotBoyaci extends CustomPainter {
  const _MaskotBoyaci({required this.dusunuyor, required this.mutlu, required this.faz});
  final bool dusunuyor, mutlu;
  final double faz;

  static const _mor = Color(0xFF5443D2);
  static const _morKoyu = Color(0xFF3B2DA8);
  static const _morAcik = Color(0xFF7B6DF0);
  static const _boynuz = Color(0xFFF2D39B);
  static const _yuz = Color(0xFFF6F5FF);
  static const _goz = Color(0xFF1D2233);
  static const _yesil = Color(0xFF00CC69);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    canvas.scale(k);
    final dolgu = Paint()..style = PaintingStyle.fill;

    // boynuzlar
    dolgu.color = _boynuz;
    canvas.drawPath(
      Path()
        ..moveTo(24, 36)
        ..cubicTo(9, 32, 6, 16, 13, 8)
        ..cubicTo(15, 20, 22, 25, 31, 27)
        ..close(),
      dolgu,
    );
    canvas.drawPath(
      Path()
        ..moveTo(76, 36)
        ..cubicTo(91, 32, 94, 16, 87, 8)
        ..cubicTo(85, 20, 78, 25, 69, 27)
        ..close(),
      dolgu,
    );
    // kulaklar
    dolgu.color = _morKoyu;
    canvas.drawOval(Rect.fromCenter(center: const Offset(16, 52), width: 14, height: 20), dolgu);
    canvas.drawOval(Rect.fromCenter(center: const Offset(84, 52), width: 14, height: 20), dolgu);
    // anten
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(48.5, 9, 3, 14), const Radius.circular(1.5)), dolgu);
    final parlak = dusunuyor ? (0.55 + 0.45 * math.sin(faz * 2 * math.pi)).clamp(0.0, 1.0) : 1.0;
    dolgu.color = Color.lerp(_morKoyu, _yesil, parlak)!;
    canvas.drawCircle(const Offset(50, 8), 4.2, dolgu);
    // baş
    dolgu.color = _mor;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 22, 60, 60), const Radius.circular(27)), dolgu);
    // yüz plakası
    dolgu.color = _yuz;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(27, 30, 46, 44), const Radius.circular(19)), dolgu);
    // gözler
    final cizgi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = _goz;
    if (mutlu) {
      canvas.drawArc(Rect.fromCenter(center: const Offset(40, 48), width: 11, height: 9), math.pi, math.pi, false, cizgi);
      canvas.drawArc(Rect.fromCenter(center: const Offset(60, 48), width: 11, height: 9), math.pi, math.pi, false, cizgi);
    } else {
      final dx = dusunuyor ? 1.8 : 0.0, dy = dusunuyor ? -2.0 : 0.0;
      dolgu.color = _goz;
      canvas.drawCircle(Offset(40 + dx, 47 + dy), 5.6, dolgu);
      canvas.drawCircle(Offset(60 + dx, 47 + dy), 5.6, dolgu);
      dolgu.color = Colors.white;
      canvas.drawCircle(Offset(42 + dx, 45 + dy), 1.9, dolgu);
      canvas.drawCircle(Offset(62 + dx, 45 + dy), 1.9, dolgu);
    }
    // burun
    dolgu.color = _morAcik;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(36, 55, 28, 13), const Radius.circular(6.5)), dolgu);
    dolgu.color = _morKoyu;
    canvas.drawCircle(const Offset(45, 61.5), 2.1, dolgu);
    canvas.drawCircle(const Offset(55, 61.5), 2.1, dolgu);
    // gülümseme
    cizgi.color = _morKoyu;
    cizgi.strokeWidth = 2.2;
    canvas.drawPath(
      Path()
        ..moveTo(44, 71)
        ..quadraticBezierTo(50, mutlu ? 77 : 75, 56, 71),
      cizgi,
    );
    // düşünce noktaları
    if (dusunuyor) {
      dolgu.color = _morAcik.withValues(alpha: .9);
      for (var i = 0; i < 3; i++) {
        final a = ((faz * 3 - i) % 3 + 3) % 3;
        final r = a < 1 ? 2.0 + a * 1.4 : 2.0;
        canvas.drawCircle(Offset(84 + i * 6.0, 26 - i * 5.0), r, dolgu);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MaskotBoyaci e) => e.dusunuyor != dusunuyor || e.mutlu != mutlu || e.faz != faz;
}
