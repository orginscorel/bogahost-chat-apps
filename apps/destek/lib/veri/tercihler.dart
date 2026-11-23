import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _temaAnahtari = 'destek.tema';
const _sesAnahtari = 'destek.ses';
const _menuAnahtari = 'destek.menuSabit';

/// Geniş ekranda yan menü sabit (açık) mı, yoksa yalnız üzerine gelince mi genişlesin.
final menuSabit = ValueNotifier<bool>(false);

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

Future<void> menuSabitKaydet(bool v) async {
  menuSabit.value = v;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_menuAnahtari, v);
  } catch (_) {}
}
