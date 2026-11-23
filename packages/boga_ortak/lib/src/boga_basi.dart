import 'package:flutter/material.dart';

import 'tema.dart';

/// Bogahost amblemi: "bogahost" yazısındaki boynuzlu boğa başı ("o" harfi). Geometri gerçek logodan
/// (templates/bogahost/img/bogahost-logo-yeni.png) ölçülerek vektöre alınmıştır; [kutu] 344 × 268 birimlik alandır.
///
/// Biçim: kaş çubuğu (üstte yatay), iki ucunda yukarı uzanan boynuzlar, altında baklava biçimli yüz. Yüzün sağ
/// kenarı kaşı deler ve kaşın sağ parçası çapraz bir çentikle ayrılır; sol kenar kaşa değmeden biter.
class BogaBasi {
  BogaBasi._();

  static const kutu = Size(344, 268);
  static const kalinlik = 34.0;

  // Yüz çizgisi: sol üst uç → sol köşe → alt uç → sağ köşe → kaşı delen üst uç.
  static final _yuz = Path()
    ..moveTo(141, 107)
    ..lineTo(84, 164)
    ..lineTo(168, 250)
    ..lineTo(256, 164)
    ..lineTo(179, 76);

  static final _solBoynuz = Path()
    ..moveTo(0, 64)
    ..quadraticBezierTo(-3, 14, 22, -2)
    ..quadraticBezierTo(25, 34, 46, 64)
    ..close();
  static final _sagBoynuz = Path()
    ..moveTo(344, 64)
    ..quadraticBezierTo(347, 14, 322, -2)
    ..quadraticBezierTo(319, 34, 298, 64)
    ..close();

  static double _ar(double t, double a, double b, [Curve e = Curves.linear]) => t <= a ? 0 : (t >= b ? 1 : e.transform((t - a) / (b - a)));

  /// Amblemi [hedef] içine orantılı sığdırıp çizer. [t] 0..1 koreografi: kaş soldan sağa çizilir, yüz kalemle
  /// çizilir, boynuzlar yükselir, çentik açılır. 1 = tam amblem.
  static void ciz(Canvas c, Rect hedef, {Color renk = Colors.white, double t = 1}) {
    final k = (hedef.width / kutu.width < hedef.height / kutu.height) ? hedef.width / kutu.width : hedef.height / kutu.height;
    final w = kutu.width * k, h = kutu.height * k;
    c.save();
    c.translate(hedef.left + (hedef.width - w) / 2, hedef.top + (hedef.height - h) / 2);
    c.scale(k);
    // Çentik şeffaf kalsın diye amblem ayrı katmana çizilir.
    c.saveLayer(const Rect.fromLTWH(-24, -24, 392, 316), Paint());
    final dolgu = Paint()..color = renk;
    final kalem = Paint()
      ..color = renk
      ..style = PaintingStyle.stroke
      ..strokeWidth = kalinlik
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final kas = _ar(t, 0, .45, Curves.easeInOut);
    if (kas > 0) c.drawLine(const Offset(18, 72), Offset(18 + 308 * kas, 72), kalem);
    final yuz = _ar(t, .18, .78, Curves.easeInOutCubic);
    if (yuz >= 1) {
      c.drawPath(_yuz, kalem);
    } else if (yuz > 0) {
      for (final m in _yuz.computeMetrics()) {
        c.drawPath(m.extractPath(0, m.length * yuz), kalem);
      }
    }
    final boynuz = _ar(t, .6, 1, Curves.easeOutBack);
    if (boynuz > 0) {
      for (final (p, taban) in [(_solBoynuz, const Offset(22, 64)), (_sagBoynuz, const Offset(322, 64))]) {
        c.save();
        c.translate(taban.dx, taban.dy);
        c.scale(1, boynuz);
        c.translate(-taban.dx, -taban.dy);
        c.drawPath(p, dolgu);
        c.restore();
      }
    }
    final centik = _ar(t, .72, .9, Curves.easeOut);
    if (centik > 0) {
      c.drawLine(
        const Offset(186, 48),
        const Offset(248, 120),
        Paint()
          ..color = Colors.black.withValues(alpha: centik)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.butt
          ..blendMode = BlendMode.dstOut,
      );
    }
    c.restore();
    c.restore();
  }
}

/// Boğa başı widget'ı.
class BogaBasiGorunumu extends StatelessWidget {
  const BogaBasiGorunumu({super.key, this.genislik = 48, this.renk});
  final double genislik;
  final Color? renk;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(genislik, genislik * BogaBasi.kutu.height / BogaBasi.kutu.width),
    painter: _BogaBasiBoyayici(renk ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Marka.mor)),
  );
}

class _BogaBasiBoyayici extends CustomPainter {
  _BogaBasiBoyayici(this.renk);
  final Color renk;
  @override
  void paint(Canvas c, Size s) => BogaBasi.ciz(c, Offset.zero & s, renk: renk);
  @override
  bool shouldRepaint(_BogaBasiBoyayici o) => o.renk != renk;
}
