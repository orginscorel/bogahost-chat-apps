import 'dart:io';
import 'dart:math' as math;

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';

import 'ekranlar/acilis.dart';
import 'ekranlar/kabuk.dart';
import 'oturum.dart';
import 'veri/tercihler.dart';
import 'veri/vitrin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  kimlikAyarla(Kimlik.posta); // Bogahost indigo kimliği
  await initializeDateFormatting('tr_TR');
  Intl.defaultLocale = 'tr_TR';
  await temaYukle();
  if (!Platform.isAndroid && !Platform.isIOS) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(420, 640));
    await windowManager.setTitle('Bogahost Chat');
    if (vitrinAcik) {
      // Mağaza görseli: Mac penceresi 1440×900 nokta (Retina'da 2880×1800), ekranın ortasında.
      await windowManager.setSize(const Size(1440, 900));
      await windowManager.center();
    }
  }
  if (vitrinAcik) temaKipi.value = ThemeMode.light;
  await Uyg.api.baslat();
  Uyg.api.oturumDustu = Uyg.oturumDustu;
  runApp(const DestekUygulamasi());
}

class DestekUygulamasi extends StatelessWidget {
  const DestekUygulamasi({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaKipi,
      builder: (_, kip, _) => MaterialApp(
        title: 'Bogahost Chat',
        debugShowCheckedModeBanner: false,
        navigatorKey: kokGezgin,
        scaffoldMessengerKey: kokMesaj,
        theme: temaKur(Brightness.light),
        darkTheme: temaKur(Brightness.dark),
        themeMode: kip,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        scrollBehavior: const _Kaydirma(),
        builder: (_, child) => vitrinAcik
            ? RepaintBoundary(key: vitrinAnahtar, child: OlcekSarmal(child: child ?? const SizedBox.shrink()))
            : OlcekSarmal(child: child ?? const SizedBox.shrink()),
        home: AcilisChat(hazirla: () async => await Uyg.yukle() ? const Kabuk() : Uyg.girisEkrani()),
      ),
    );
  }
}

/// Arayüz ölçeği: pencere, ölçek kadar küçük bir mantıksal alana çizilip büyütülür; böylece yazı, ikon, düğme ve
/// boşluklar büyük monitörde birlikte büyür (tercih 0 ise genişliğe göre otomatik).
class OlcekSarmal extends StatelessWidget {
  const OlcekSarmal({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: arayuzOlcegi,
    builder: (_, tercih, _) => LayoutBuilder(
      builder: (ctx, k) {
        final w = k.maxWidth, h = k.maxHeight;
        if (!w.isFinite || !h.isFinite) return child;
        if (vitrinAcik && !Platform.isAndroid && !Platform.isIOS) {
          // Vitrin (mağaza karesi): pencere ekrana sığmasa da içerik 1440×900 mantıksal boyutta yerleşir, pencereye
          // sığacak kadar küçültülerek çizilir; yakalama bu ölçeğin tersiyle yapılır → tam 2880×1800 piksel.
          const tw = 1440.0, th = 900.0;
          final f = math.min(w / tw, h / th);
          if (f < 1) {
            final mq = MediaQuery.of(ctx);
            return Transform.scale(
              scale: f,
              alignment: Alignment.topLeft,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: tw,
                maxWidth: tw,
                minHeight: th,
                maxHeight: th,
                child: SizedBox(
                  width: tw,
                  height: th,
                  child: MediaQuery(
                    data: mq.copyWith(size: const Size(tw, th), devicePixelRatio: mq.devicePixelRatio / f, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero, viewInsets: EdgeInsets.zero),
                    child: RepaintBoundary(child: child),
                  ),
                ),
              ),
            );
          }
        }
        final f = tercih > 0 ? tercih : otomatikOlcek(w);
        if ((f - 1).abs() < .01) return RepaintBoundary(child: child);
        final mq = MediaQuery.of(ctx);
        return MediaQuery(
          data: mq.copyWith(
            size: Size(w / f, h / f),
            devicePixelRatio: mq.devicePixelRatio * f,
            padding: mq.padding / f,
            viewPadding: mq.viewPadding / f,
            viewInsets: mq.viewInsets / f,
          ),
          // OverflowBox: çocuk, pencerenin sıkı kısıtı yerine küçültülmüş mantıksal boyutta (w/f × h/f) yerleşir;
          // Transform sonra onu f kat büyütür. Bu olmadan içerik pencere boyutunda yerleşip taşıyordu.
          child: Transform.scale(
            scale: f,
            alignment: Alignment.topLeft,
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: w / f,
              maxWidth: w / f,
              minHeight: h / f,
              maxHeight: h / f,
              child: SizedBox(
                width: w / f,
                height: h / f,
                child: RepaintBoundary(child: child),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Mac/Windows'ta fare ile sürükleyerek de kaydırılsın (yatay sekme şeritleri, listeler).
class _Kaydirma extends MaterialScrollBehavior {
  const _Kaydirma();
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus};
}
