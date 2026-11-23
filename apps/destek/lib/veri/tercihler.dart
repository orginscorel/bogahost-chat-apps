import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _temaAnahtari = 'destek.tema';
const _sesAnahtari = 'destek.ses';
const _menuAnahtari = 'destek.menuSabit';
const _olcekAnahtari = 'destek.olcek';

/// Geniş ekranda yan menü sabit (açık) mı, yoksa yalnız üzerine gelince mi genişlesin.
final menuSabit = ValueNotifier<bool>(false);

/// Arayüz ölçeği: 0 = otomatik (pencere genişliğine göre), 1 = %100, 1.2 = %120 … Büyük monitörlerde her şey
/// (yazı, ikon, düğme, boşluk) birlikte büyür.
final arayuzOlcegi = ValueNotifier<double>(0);

/// Otomatik ölçek: geniş pencerelerde kademeli büyütme.
double otomatikOlcek(double genislik) => genislik >= 2300
    ? 1.35
    : genislik >= 1900
    ? 1.25
    : genislik >= 1500
    ? 1.12
    : 1.0;

String olcekAdi(double v) => v <= 0 ? 'Otomatik' : '%${(v * 100).round()}';

ThemeMode temaCoz(String? s) => switch (s) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  'system' => ThemeMode.system,
  _ => ThemeMode.system,
};

String temaAdi(ThemeMode m) => switch (m) {
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
  ThemeMode.system => 'system',
};

/// Yeni mesaj / sohbet geldiğinde sistem sesi çalınsın mı (uygulama açıkken).
final sesAcik = ValueNotifier<bool>(true);

Future<void> temaYukle() async {
  try {
    final p = await SharedPreferences.getInstance();
    temaKipi.value = temaCoz(p.getString(_temaAnahtari));
    sesAcik.value = p.getBool(_sesAnahtari) ?? true;
    menuSabit.value = p.getBool(_menuAnahtari) ?? false;
    arayuzOlcegi.value = p.getDouble(_olcekAnahtari) ?? 0;
  } catch (_) {}
}

Future<void> temaKaydet(ThemeMode m) async {
  temaKipi.value = m;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setString(_temaAnahtari, temaAdi(m));
  } catch (_) {}
}

Future<void> sesKaydet(bool v) async {
  sesAcik.value = v;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_sesAnahtari, v);
  } catch (_) {}
}

Future<void> olcekKaydet(double v) async {
  arayuzOlcegi.value = v;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_olcekAnahtari, v);
  } catch (_) {}
}

Future<void> menuSabitKaydet(bool v) async {
  menuSabit.value = v;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_menuAnahtari, v);
  } catch (_) {}
}
