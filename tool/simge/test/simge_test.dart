// Tüm platform simgelerini açılış işaretinin son karesinden üretir:
//   cd tool/simge && flutter test
// iOS: tam kare opak zemin (köşeleri iOS yuvarlar). macOS: Big Sur ızgarasında yuvarlatılmış kare + gölge.
// Android: uyarlanabilir simge (mor zemin + şeffaf ön plan) ve eski cihazlar için yuvarlatılmış kare.
// Windows: çok boyutlu .ico (PNG gömülü).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const kok = '../../apps';

/// Alfa kanalsız (RGB, renk türü 2) PNG: App Store Connect iOS simgelerinde alfa kanalı kabul etmez.
Future<Uint8List> _opakPng(int boyut, void Function(Canvas c, double k) ciz) async {
  final kayit = ui.PictureRecorder();
  final c = Canvas(kayit);
  ciz(c, boyut / 1024);
  final img = await kayit.endRecording().toImage(boyut, boyut);
  final ham = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  final satir = boyut * 3 + 1;
  final veri = Uint8List(satir * boyut);
  for (var y = 0; y < boyut; y++) {
    veri[y * satir] = 0; // filtre: yok
    for (var x = 0; x < boyut; x++) {
      final k = (y * boyut + x) * 4;
      final a = ham[k + 3] / 255;
      final h = y * satir + 1 + x * 3;
      // Şeffaf kalan piksel olursa beyaz üstüne bindir
      veri[h] = (ham[k] * a + 255 * (1 - a)).round();
      veri[h + 1] = (ham[k + 1] * a + 255 * (1 - a)).round();
      veri[h + 2] = (ham[k + 2] * a + 255 * (1 - a)).round();
    }
  }
  final b = BytesBuilder()..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void parca(String tur, List<int> g) {
    final t = tur.codeUnits;
    final uz = ByteData(4)..setUint32(0, g.length);
    b.add(uz.buffer.asUint8List());
    b.add(t);
    b.add(g);
    final crc = ByteData(4)..setUint32(0, _crc32([...t, ...g]));
    b.add(crc.buffer.asUint8List());
  }
  final ihdr = ByteData(13)
    ..setUint32(0, boyut)
    ..setUint32(4, boyut)
    ..setUint8(8, 8)
    ..setUint8(9, 2)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  parca('IHDR', ihdr.buffer.asUint8List());
  parca('IDAT', ZLibEncoder(level: 9).convert(veri));
  parca('IEND', const []);
  return b.toBytes();
}

final _crcTablo = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> v) {
  var c = 0xFFFFFFFF;
  for (final b in v) {
    c = _crcTablo[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

Future<Uint8List> _png(int boyut, void Function(Canvas c, double k) ciz) async {
  final kayit = ui.PictureRecorder();
  final c = Canvas(kayit);
  ciz(c, boyut / 1024);
  final img = await kayit.endRecording().toImage(boyut, boyut);
  final b = await img.toByteData(format: ui.ImageByteFormat.png);
  return b!.buffer.asUint8List();
}

/// Rozet: yeşil daire içinde beyaz sohbet balonu + üç nokta (amblemin sağ altı).
void _rozet(Canvas c, Offset m, double y, {Color halka = const Color(0xFF3624A6)}) {
  c.drawCircle(m, y * 1.18, Paint()..color = halka);
  c.drawCircle(m, y, Paint()..color = Marka.yesil);
  final b = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(m.dx, m.dy - y * .06), width: y * 1.14, height: y * .86), Radius.circular(y * .3));
  final beyaz = Paint()..color = Colors.white;
  c.drawRRect(b, beyaz);
  c.drawPath(Path()..moveTo(m.dx - y * .22, b.bottom - y * .04)..lineTo(m.dx - y * .42, b.bottom + y * .3)..lineTo(m.dx + y * .1, b.bottom - y * .04)..close(), beyaz);
  for (final x in [-.3, 0.0, .3]) {
    c.drawCircle(Offset(m.dx + x * y, m.dy - y * .06), y * .09, Paint()..color = Marka.yesil);
  }
}

/// Gerçek Bogahost amblemi (üç sunucu sütunu) + rozet; 1024 tuvalde.
void _amblemRozet(Canvas c, {double olcek = 1}) {
  final hedef = Rect.fromCenter(center: const Offset(482, 500), width: 520 * olcek, height: 520 * olcek);
  BogahostLogo.amblemCiz(c, hedef, renk: Colors.white);
  _rozet(c, Offset(512 + 250 * olcek, 512 + 220 * olcek), 112 * olcek);
}

/// Tam kare zemin + amblem (iOS, Android eski, Windows).
void _kare(Canvas c, double k, AcilisIsaret i, {double radius = 0}) {
  c.scale(k);
  const r = Rect.fromLTWH(0, 0, 1024, 1024);
  final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
  c.drawRRect(rr, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7B6DF0), Marka.mor, Color(0xFF3624A6)], stops: [0, .5, 1]).createShader(r));
  c.drawRRect(rr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.white.withValues(alpha: .18), Colors.white.withValues(alpha: 0)]).createShader(r));
  _amblemRozet(c);
}

/// macOS: 1024 tuvalde 824'lük yuvarlatılmış kare, yumuşak gölge.
void _mac(Canvas c, double k, AcilisIsaret i) {
  c.scale(k);
  const r = Rect.fromLTWH(100, 100, 824, 824);
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(185));
  c.drawRRect(rr.shift(const Offset(0, 10)), Paint()
    ..color = Colors.black.withValues(alpha: .28)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
  c.save();
  c.clipRRect(rr);
  c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7B6DF0), Marka.mor, Color(0xFF3624A6)], stops: [0, .5, 1]).createShader(r));
  c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.center, colors: [Colors.white.withValues(alpha: .18), Colors.white.withValues(alpha: 0)]).createShader(r));
  c.translate(100, 100);
  c.scale(824 / 1024);
  _amblemRozet(c);
  c.restore();
}

/// Başlangıç (launch) görseli: şeffaf zemin, beyaz amblem + rozet (iOS LaunchImage, Android launch_image).
void _baslangic(Canvas c, double k) {
  c.scale(k);
  _amblemRozet(c, olcek: .9);
}

/// Android uyarlanabilir ön plan: içerik ortadaki güvenli alanda (~%60), şeffaf zemin.
void _onPlan(Canvas c, double k, AcilisIsaret i) {
  c.scale(k);
  c.translate(512, 512);
  c.scale(.56);
  c.translate(-512, -512);
  _amblemRozet(c);
}

Uint8List _ico(List<(int, Uint8List)> pngler) {
  final b = BytesBuilder();
  final h = ByteData(6)
    ..setUint16(0, 0, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, pngler.length, Endian.little);
  b.add(h.buffer.asUint8List());
  var ofs = 6 + 16 * pngler.length;
  for (final (s, p) in pngler) {
    final e = ByteData(16)
      ..setUint8(0, s >= 256 ? 0 : s)
      ..setUint8(1, s >= 256 ? 0 : s)
      ..setUint16(4, 1, Endian.little)
      ..setUint16(6, 32, Endian.little)
      ..setUint32(8, p.length, Endian.little)
      ..setUint32(12, ofs, Endian.little);
    b.add(e.buffer.asUint8List());
    ofs += p.length;
  }
  for (final (_, p) in pngler) {
    b.add(p);
  }
  return b.toBytes();
}

void main() {
  for (final (app, isaret) in [('destek', AcilisIsaret.destek)]) {
    test('$app simgeleri', () async {
      final d = '$kok/$app';
      // iOS
      final ios = '$d/ios/Runner/Assets.xcassets/AppIcon.appiconset';
      for (final f in Directory(ios).listSync().whereType<File>().where((f) => f.path.endsWith('.png'))) {
        final m = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$').firstMatch(f.path)!;
        final px = (double.parse(m[1]!) * int.parse(m[2]!)).round();
        f.writeAsBytesSync(await _opakPng(px, (c, k) => _kare(c, k, isaret)));
      }
      // iOS başlangıç görseli (LaunchScreen.storyboard → LaunchImage, 1x/2x/3x = 160/320/480 px)
      final li = '$d/ios/Runner/Assets.xcassets/LaunchImage.imageset';
      for (final (ad, px) in [('LaunchImage.png', 160), ('LaunchImage@2x.png', 320), ('LaunchImage@3x.png', 480)]) {
        File('$li/$ad').writeAsBytesSync(await _png(px, (c, k) => _baslangic(c, k)));
      }
      // Android başlangıç görseli (launch_background.xml → @mipmap/launch_image)
      const lyog = {'mdpi': 120, 'hdpi': 180, 'xhdpi': 240, 'xxhdpi': 360, 'xxxhdpi': 480};
      for (final e in lyog.entries) {
        File('$d/android/app/src/main/res/mipmap-${e.key}/launch_image.png').writeAsBytesSync(await _png(e.value, (c, k) => _baslangic(c, k)));
      }
      // macOS
      for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
        File('$d/macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$s.png').writeAsBytesSync(await _png(s, (c, k) => _mac(c, k, isaret)));
      }
      // Android
      const yog = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final e in yog.entries) {
        File('$d/android/app/src/main/res/mipmap-${e.key}/ic_launcher.png').writeAsBytesSync(await _png(e.value, (c, k) => _kare(c, k, isaret, radius: 230)));
        final on = e.value * 108 ~/ 48;
        Directory('$d/android/app/src/main/res/drawable-${e.key}').createSync(recursive: true);
        File('$d/android/app/src/main/res/drawable-${e.key}/ic_launcher_foreground.png').writeAsBytesSync(await _png(on, (c, k) => _onPlan(c, k, isaret)));
      }
      Directory('$d/android/app/src/main/res/mipmap-anydpi-v26').createSync(recursive: true);
      File('$d/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml').writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
    <monochrome android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
''');
      File('$d/android/app/src/main/res/values/ic_launcher_background.xml').writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">${isaret == AcilisIsaret.yonetim ? "#1D2233" : "#5443D2"}</color>
</resources>
''');
      // Windows
      final pngler = <(int, Uint8List)>[];
      for (final s in [16, 24, 32, 48, 64, 128, 256]) {
        pngler.add((s, await _png(s, (c, k) => _kare(c, k, isaret, radius: 200))));
      }
      File('$d/windows/runner/resources/app_icon.ico').writeAsBytesSync(_ico(pngler));
      // Mağaza / belgeler için büyük logo
      Directory('$d/assets').createSync(recursive: true);
      File('$d/assets/simge-1024.png').writeAsBytesSync(await _opakPng(1024, (c, k) => _kare(c, k, isaret)));
    });
  }
}
