import 'dart:io';

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
  }
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
        home: AcilisChat(hazirla: () async => await Uyg.yukle() ? const Kabuk() : Uyg.girisEkrani()),
      ),
    );
  }
}

/// Mac/Windows'ta fare ile sürükleyerek de kaydırılsın (yatay sekme şeritleri, listeler).
class _Kaydirma extends MaterialScrollBehavior {
  const _Kaydirma();
  @override
  Set<PointerDeviceKind> get dragDevices => {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad, PointerDeviceKind.stylus};
}
