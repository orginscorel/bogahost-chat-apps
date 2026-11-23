import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'boga_basi.dart';
import 'tema.dart';

/// Gerçek Bogahost logosu: "bogahost" yazısı, "o" harfi boynuzlu boğa başı (templates/bogahost/img/bogahost-logo-yeni.png).
/// Yazı PNG'den (beyaz, şeffaf zemin; renklendirilir), boğa başı vektörden ([BogaBasi]) çizilir; böylece açılışta
/// amblem kendini çizebilir. [kutu] yazının piksel alanı (1621 × 362), [amblemKutusu] boğa başının bu alandaki yeri.
class BogahostLogo {
  BogahostLogo._();

  static const kutu = Size(1621, 362);
  static const amblemKutusu = Rect.fromLTWH(168, 16, 344, 268);
  static const yaziVarlik = 'packages/boga_ortak/assets/logo/bogahost-yazi.png';

  static ui.Image? _yazi;
  static Future<void>? _yukleme;

  /// Yazı görselini belleğe alır (açılış ve tuval çizimleri için). Tekrar çağrılması zararsız.
  static Future<void> yukle() => _yukleme ??= () async {
    final d = await rootBundle.load(yaziVarlik);
    final codec = await ui.instantiateImageCodec(d.buffer.asUint8List());
    _yazi = (await codec.getNextFrame()).image;
  }();

  static bool get yaziHazir => _yazi != null;

  /// Logoyu [hedef] içine orantılı sığdırıp çizer.
  static void ciz(Canvas c, Rect hedef, {Color renk = Colors.white, bool yaziGoster = true}) =>
      cizAnimasyonlu(c, hedef, amblemT: 1, yaziT: yaziGoster ? 1 : 0, renk: renk, yalnizAmblem: !yaziGoster);

  /// Yalnız amblemi (boğa başı) [hedef] içine sığdırıp çizer (simge, başlangıç ekranı).
  static void amblemCiz(Canvas c, Rect hedef, {Color renk = Colors.white, double t = 1}) => BogaBasi.ciz(c, hedef, renk: renk, t: t);

  /// Kendini çizen logo. [amblemT] boğa başının çizim ilerlemesi; [yaziT] harflerin soldan sağa belirmesi.
  /// Yazı görseli henüz yüklenmemişse yalnız amblem çizilir.
  static void cizAnimasyonlu(
    Canvas c,
    Rect hedef, {
    required double amblemT,
    required double yaziT,
    Color renk = Colors.white,
    Color? vurgu,
    bool yalnizAmblem = false,
  }) {
    if (yalnizAmblem) {
      BogaBasi.ciz(c, hedef, renk: renk, t: amblemT);
      return;
    }
    c.save();
    final k = (hedef.width / kutu.width < hedef.height / kutu.height) ? hedef.width / kutu.width : hedef.height / kutu.height;
    final w = kutu.width * k, h = kutu.height * k;
    c.translate(hedef.left + (hedef.width - w) / 2, hedef.top + (hedef.height - h) / 2);
    c.scale(k);
    final y = _yazi;
    if (y != null && yaziT > 0) {
      final boya = Paint()..colorFilter = ColorFilter.mode(renk, BlendMode.srcIn);
      // Soldan sağa beliren pencere; boğa başı bölgesi görselden alınmaz (vektör çizilir).
      final gorunen = kutu.width * yaziT;
      for (final parca in [Rect.fromLTRB(0, 0, amblemKutusu.left, kutu.height), Rect.fromLTRB(amblemKutusu.right, 0, kutu.width, kutu.height)]) {
        final r = Rect.fromLTRB(parca.left, parca.top, parca.right.clamp(parca.left, gorunen), parca.bottom);
        if (r.width <= 0) continue;
        c.drawImageRect(y, r, r, boya);
      }
    }
    BogaBasi.ciz(c, amblemKutusu, renk: renk, t: amblemT);
    c.restore();
  }
}

/// Statik logo widget'ı (ayarlar, hakkında, giriş). Yazı için PNG renklendirilir; yalnız amblem vektördür.
class BogahostLogoGorunumu extends StatelessWidget {
  const BogahostLogoGorunumu({super.key, this.genislik = 180, this.renk, this.yalnizAmblem = false});
  final double genislik;
  final Color? renk;
  final bool yalnizAmblem;
  @override
  Widget build(BuildContext context) {
    final r = renk ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Marka.mor);
    if (yalnizAmblem) return BogaBasiGorunumu(genislik: genislik, renk: r);
    return Image.asset(
      BogahostLogo.yaziVarlik,
      width: genislik,
      height: genislik * BogahostLogo.kutu.height / BogahostLogo.kutu.width,
      color: r,
      filterQuality: FilterQuality.medium,
    );
  }
}

/// Logo görüntüsünü PNG olarak üretir (simge ve başlangıç görselleri için).
Future<ui.Image> logoGorsel(int genislik, int yukseklik, void Function(Canvas) ciz) async {
  final kayit = ui.PictureRecorder();
  ciz(Canvas(kayit));
  return kayit.endRecording().toImage(genislik, yukseklik);
}
