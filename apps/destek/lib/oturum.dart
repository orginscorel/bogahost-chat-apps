import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import 'ekranlar/kabuk.dart';
import 'veri/json.dart';
import 'veri/modeller.dart';

/// Uygulamanın tekil durumu: API istemcisi, oturumdaki temsilci, yetkiler.
class Uyg {
  Uyg._();

  static const sunucu = 'https://chat.bogahost.com';
  static const apiKok = '/api/app/v1';
  static const pushYolu = '$apiKok/device';
  static const pushKonu = 'com.bogahost.destek';

  static final BogaApi api = _kur();

  static BogaApi _kur() {
    final a = BogaApi(uygulama: 'destek', csrfCerezi: 'destek_csrf');
    a.jetonYolu = '$apiKok/login';
    return a;
  }

  /// Oturumdaki temsilci (GET me → user).
  static final ben = ValueNotifier<Temsilci?>(null);

  /// Sunucu sürümü (me → server.version).
  static String sunucuSurumu = '';

  static bool yetki(String izin) => ben.value?.yetkiler.contains(izin) ?? false;
  static bool get yonetici => ben.value?.yonetici ?? false;
  static String get ad => ben.value?.ad ?? '';
  static int get benId => ben.value?.id ?? 0;

  /// Sunucudan kullanıcıyı yükler. Jeton yoksa ya da geçersizse false.
  static Future<bool> yukle() async {
    if (api.sunucu == BogaApi.varsayilanSunucu) await api.sunucuAyarla(sunucu);
    if (!await api.oturumVar()) return false;
    try {
      final v = harita(await api.get('$apiKok/me'));
      ben.value = Temsilci.coz(harita(v['user']));
      sunucuSurumu = metin(harita(v['server'])['version']);
      return true;
    } on ApiHata catch (e) {
      if (e.durum == 401 || e.durum == 403) {
        await api.jetonKaydet(null);
        return false;
      }
      rethrow;
    }
  }

  static Widget girisEkrani() => GirisEkrani(
    api: api,
    baslik: 'Bogahost Destek',
    aciklama: 'Canlı destek personel hesabınızla (WHMCS yönetici girişi) oturum açın.',
    girisYolu: '$apiKok/login',
    isaret: AcilisIsaret.destek,
    adresIpucu: 'kullanici.adi',
    girisYapildi: (c) async {
      final nav = Navigator.of(c);
      await yukle();
      nav.pushAndRemoveUntil(HizliRota(builder: (_) => const Kabuk()), (_) => false);
    },
  );

  /// Çıkış: push kaydını ve sunucudaki jetonu siler.
  static Future<void> cikis() async {
    await Push.sil(api, yol: pushYolu);
    try {
      await api.post('$apiKok/logout');
    } catch (_) {}
    await api.jetonKaydet(null);
    ben.value = null;
    await Push.rozet(0);
    kokGezgin.currentState?.pushAndRemoveUntil(HizliRota(builder: (_) => girisEkrani()), (_) => false);
  }

  /// Sunucu 401 döndürdü: jeton geçersiz.
  static void oturumDustu() {
    if (ben.value == null) return;
    ben.value = null;
    api.jetonKaydet(null);
    kokGezgin.currentState?.pushAndRemoveUntil(HizliRota(builder: (_) => girisEkrani()), (_) => false);
    bildir('Oturum kapandı', mesaj: 'Yeniden giriş yapın.', tur: MesajTur.uyari);
  }

  /// Göreli dosya yollarını (ör. /storage/…) tam adrese çevirir.
  static String tamAdres(String? yol) {
    if (yol == null || yol.isEmpty) return '';
    if (yol.startsWith('http')) return yol;
    return '${api.sunucu}${yol.startsWith('/') ? '' : '/'}$yol';
  }
}
