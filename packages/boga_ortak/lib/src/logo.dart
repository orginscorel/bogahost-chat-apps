import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'logo_veri.dart';
import 'tema.dart';

/// Gerçek Bogahost logosu (sitedeki logo-new.svg): üç sunucu sütunlu amblem + "bogahost" yazısı.
/// Yollar SVG'den birebir alınır; [ciz] ile herhangi bir dikdörtgene sığdırılarak çizilir,
/// [cizAnimasyonlu] ile "kendini çizen" açılış animasyonu yapılır.
class BogahostLogo {
  BogahostLogo._();

  static const kutu = Size(logoGenislik, logoYukseklik);

  static final List<Path> amblem = amblemYollari.map(parseSvgPathData).toList(growable: false);
  static final List<Path> yazi = yaziYollari.map(parseSvgPathData).toList(growable: false);

  /// Amblemin SVG içindeki kapsayıcı dikdörtgeni.
  static final Rect amblemKutusu = amblem.fold<Rect?>(null, (r, p) => r == null ? p.getBounds() : r.expandToInclude(p.getBounds()))!;
  static final Rect yaziKutusu = yazi.fold<Rect?>(null, (r, p) => r == null ? p.getBounds() : r.expandToInclude(p.getBounds()))!;

  /// Logoyu [hedef] içine orantılı sığdırıp çizer.
  static void ciz(Canvas c, Rect hedef, {Color renk = Colors.white, bool yaziGoster = true}) {
    c.save();
    _sigdir(c, hedef, yaziGoster ? Rect.fromLTWH(0, 0, kutu.width, kutu.height) : amblemKutusu);
    final b = Paint()..color = renk;
    for (final p in amblem) {
      c.drawPath(p, b);
    }
    if (yaziGoster) {
      for (final p in yazi) {
        c.drawPath(p, b);
      }
    }
    c.restore();
  }

  /// Yalnız amblemi [hedef] içine sığdırıp çizer (simge, başlangıç ekranı).
  static void amblemCiz(Canvas c, Rect hedef, {Color renk = Colors.white}) => ciz(c, hedef, renk: renk, yaziGoster: false);

  /// Kendini çizen logo. [amblemT] ve [yaziT] 0..1: önce kontur çizilir (kalemle), sonra dolgu belirir.
  /// Harfler soldan sağa sırayla gelir.
  static void cizAnimasyonlu(Canvas c, Rect hedef, {required double amblemT, required double yaziT, Color renk = Colors.white, Color? vurgu}) {
    c.save();
    _sigdir(c, hedef, Rect.fromLTWH(0, 0, kutu.width, kutu.height));
    final kalem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9
      ..strokeCap = StrokeCap.round
      ..color = renk;
    // Amblem: 6 yol — sütunlar sırayla (0,2,4 dış hat; 1,3,5 gösterge)
    for (var i = 0; i < amblem.length; i++) {
      final gecikme = (i ~/ 2) * .18;
      final t = ((amblemT - gecikme) / (1 - .36)).clamp(0.0, 1.0);
      _yolCiz(c, amblem[i], t, kalem, renk, i.isOdd ? (vurgu ?? renk) : renk);
    }
    // Yazı: harf başına kayan pencere
    final n = yazi.length;
    for (var i = 0; i < n; i++) {
      final bas = i / (n + 2);
      final t = ((yaziT - bas) / (3 / (n + 2))).clamp(0.0, 1.0);
      _yolCiz(c, yazi[i], t, kalem, renk, renk);
    }
    c.restore();
  }

  static void _yolCiz(Canvas c, Path p, double t, Paint kalem, Color renk, Color dolguRenk) {
    if (t <= 0) return;
    if (t >= 1) {
      c.drawPath(p, Paint()..color = dolguRenk);
      return;
    }
    // 0..0.7 kontur çizimi, 0.45..1 dolgu belirmesi
    final kt = (t / .7).clamp(0.0, 1.0);
    for (final m in p.computeMetrics()) {
      c.drawPath(m.extractPath(0, m.length * kt), kalem);
    }
    final dt = ((t - .45) / .55).clamp(0.0, 1.0);
    if (dt > 0) c.drawPath(p, Paint()..color = dolguRenk.withValues(alpha: dolguRenk.a * Curves.easeOut.transform(dt)));
  }

  static void _sigdir(Canvas c, Rect hedef, Rect kaynak) {
    final k = (hedef.width / kaynak.width < hedef.height / kaynak.height) ? hedef.width / kaynak.width : hedef.height / kaynak.height;
    final w = kaynak.width * k, h = kaynak.height * k;
    c.translate(hedef.left + (hedef.width - w) / 2, hedef.top + (hedef.height - h) / 2);
    c.scale(k);
    c.translate(-kaynak.left, -kaynak.top);
  }
}

/// Statik logo widget'ı (ayarlar, hakkında, giriş).
class BogahostLogoGorunumu extends StatelessWidget {
  const BogahostLogoGorunumu({super.key, this.genislik = 180, this.renk, this.yalnizAmblem = false});
  final double genislik;
  final Color? renk;
  final bool yalnizAmblem;
  @override
  Widget build(BuildContext context) {
    final oran = yalnizAmblem ? BogahostLogo.amblemKutusu.height / BogahostLogo.amblemKutusu.width : BogahostLogo.kutu.height / BogahostLogo.kutu.width;
    return CustomPaint(
      size: Size(genislik, genislik * oran),
      painter: _LogoBoyayici(renk ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Marka.mor), yalnizAmblem),
    );
  }
}

class _LogoBoyayici extends CustomPainter {
  _LogoBoyayici(this.renk, this.yalnizAmblem);
  final Color renk;
  final bool yalnizAmblem;
  @override
  void paint(Canvas c, Size s) => BogahostLogo.ciz(c, Offset.zero & s, renk: renk, yaziGoster: !yalnizAmblem);
  @override
  bool shouldRepaint(_LogoBoyayici o) => o.renk != renk || o.yalnizAmblem != yalnizAmblem;
}

/// Logo görüntüsünü PNG olarak üretir (simge ve başlangıç görselleri için).
Future<ui.Image> logoGorsel(int genislik, int yukseklik, void Function(Canvas) ciz) async {
  final kayit = ui.PictureRecorder();
  ciz(Canvas(kayit));
  return kayit.endRecording().toImage(genislik, yukseklik);
}
