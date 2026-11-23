import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

// Bogahost kurumsal amblemi (bogahost.com/templates/bogahost/img/logo-new.svg, işaret kısmı): boynuzlu taç + üç
// sunucu sütunu. Uygulama simgelerinde (iOS/macOS/Android/Windows) posta uygulamalarıyla aynı aile görünümü için
// kullanılır; uygulama içi logo ise BogaBasi/BogahostLogo'dur. Özgün koordinatlar 47 × 55.75 birimlik alandadır.

const _sutunYollari = [
  'M5.11,22.74V46.22c0,2.07,2,3.76,4.46,3.76h2.62c2.46,0,4.46-1.69,4.46-3.76V22.74c0-2.07-2-3.76-4.46-3.76H9.57C7.11,19,5.11,20.67,5.11,22.74ZM12.19,21a2,2,0,0,1,2.09,1.76V46.22A2,2,0,0,1,12.19,48H9.57a1.94,1.94,0,0,1-2.09-1.76V22.74A1.94,1.94,0,0,1,9.57,21Z',
  'M17.72,23.44V51.29a4.46,4.46,0,0,0,4.46,4.46H24.8a4.46,4.46,0,0,0,4.46-4.46V23.44A4.46,4.46,0,0,0,24.8,19H22.18A4.46,4.46,0,0,0,17.72,23.44Zm7.08-2.09a2.1,2.1,0,0,1,2.09,2.09V51.29a2.1,2.1,0,0,1-2.09,2.09H22.18a2.1,2.1,0,0,1-2.09-2.09V23.44a2.1,2.1,0,0,1,2.09-2.09Z',
  'M30.33,22.74V46.22c0,2.07,2,3.76,4.46,3.76h2.62c2.46,0,4.47-1.69,4.47-3.76V22.74c0-2.07-2-3.76-4.47-3.76H34.79C32.33,19,30.33,20.67,30.33,22.74ZM37.41,21a1.94,1.94,0,0,1,2.09,1.76V46.22A1.94,1.94,0,0,1,37.41,48H34.79a2,2,0,0,1-2.09-1.76V22.74A2,2,0,0,1,34.79,21Z',
];
const _cubukYollari = [
  'M9.69,33.38V43.7a1.19,1.19,0,0,0,2.37,0V33.38a1.19,1.19,0,1,0-2.37,0Z',
  'M22.31,39.66V50a1.19,1.19,0,0,0,2.37,0V39.66a1.19,1.19,0,1,0-2.37,0Z',
  'M34.92,33.38V43.7a1.19,1.19,0,0,0,2.37,0V33.38a1.19,1.19,0,1,0-2.37,0Z',
];
const _tacYolu =
    'M29.51,16.66H42.9A4.08,4.08,0,0,0,47,12.58V.9a.9.9,0,0,0-.9-.9.91.91,0,0,0-.74.38l-4,5.68a.87.87,0,0,0-.16.52v4.3H26.49l-2.61,3.75-.38.53,3-4.28H5.79V6.58a.87.87,0,0,0-.17-.52L1.65.38A.88.88,0,0,0,.92,0h0A.9.9,0,0,0,0,.9V12.59a4.07,4.07,0,0,0,4.08,4.07H17.49Z';

/// Kurumsal amblem çizimi (taç + sütunlar + göstergeler), tek renk.
abstract final class BogaAmblem {
  static const kutu = Size(47, 55.75);
  static final sutunlar = [for (final d in _sutunYollari) parseSvgPathData(d)];
  static final cubuklar = [for (final d in _cubukYollari) parseSvgPathData(d)];
  static final tac = parseSvgPathData(_tacYolu);

  /// [alan]ın yüksekliğine sığdırır, yatayda ortalar.
  static void ciz(Canvas c, Rect alan, {Color renk = Colors.white}) {
    final olcek = alan.height / kutu.height;
    final p = Paint()..color = renk;
    c.save();
    c.translate(alan.center.dx - kutu.width * olcek / 2, alan.top);
    c.scale(olcek);
    for (final s in sutunlar) {
      c.drawPath(s, p);
    }
    for (final b in cubuklar) {
      c.drawPath(b, p);
    }
    c.drawPath(tac, p);
    c.restore();
  }
}
