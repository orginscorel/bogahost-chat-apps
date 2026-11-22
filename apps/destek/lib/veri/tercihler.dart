import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _temaAnahtari = 'destek.tema';
const _sesAnahtari = 'destek.ses';

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
