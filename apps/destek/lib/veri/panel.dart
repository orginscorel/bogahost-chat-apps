// Panel uçları (api/app/v1/panel/…): web yönetim sayfalarının JSON karşılıkları.
// Yanıtlar çoğunlukla ham harita döner; ekranlar ihtiyaç duyduğu alanı json.dart yardımcılarıyla okur.
import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:dio/dio.dart';

import '../oturum.dart';
import 'json.dart';

String _p(String yol) => '${Uyg.apiKok}/panel/$yol';

/// `{ok:false, error, message}` → ApiHata (mesaj öncelikli).
Map<String, dynamic> _k(dynamic v) {
  final m = harita(v);
  if (m['ok'] == false) {
    final msg = m['message'] is String && '${m['message']}'.isNotEmpty ? '${m['message']}' : (m['error'] is String ? '${m['error']}' : 'İşlem yapılamadı.');
    throw ApiHata(200, msg);
  }
  return m;
}

Future<Map<String, dynamic>> _get(String yol, {Map<String, dynamic>? q}) async => _k(await Uyg.api.get(_p(yol), q: q));

/// Sık yoklamalar için kısa zaman aşımlı (varsayılan 6 sn) ve iptal edilebilir GET; iptalde [IstekIptal] fırlatır.
Future<Map<String, dynamic>> _getHizli(String yol, {Map<String, dynamic>? q, CancelToken? iptal, Duration zamanAsimi = const Duration(seconds: 6)}) async =>
    _k(await Uyg.api.get(_p(yol), q: q, zamanAsimi: zamanAsimi, iptal: iptal));
Future<Map<String, dynamic>> _post(String yol, [Object? g]) async => _k(await Uyg.api.post(_p(yol), g));
Future<Map<String, dynamic>> _put(String yol, [Object? g]) async => _k(await Uyg.api.put(_p(yol), g));
Future<Map<String, dynamic>> _del(String yol) async => _k(await Uyg.api.delete(_p(yol)));

/// Eylem yanıtındaki mesaj (bildirim için).
String mesajAl(Map<String, dynamic> m, [String d = 'Kaydedildi.']) => metin(m['message'], d);

class Panel {
  Panel._();

  // ---- Pano / sürüm
  static Future<Map<String, dynamic>> pano() => _get('dashboard');
  static Future<Map<String, dynamic>> surum() => _get('version');

  // ---- Profil / 2FA
  static Future<Map<String, dynamic>> profil() => _get('profile');
  static Future<Map<String, dynamic>> profilKaydet(Map<String, dynamic> g) => _post('profile', g);
  static Future<Map<String, dynamic>> avatarYukle(File f) async {
    final form = FormData.fromMap({'avatar': await MultipartFile.fromFile(f.path, filename: f.uri.pathSegments.last)});
    final c = await Uyg.api.dio.post<dynamic>(_p('profile/avatar'), data: form);
    return _k(c.data);
  }

  static Future<Map<String, dynamic>> avatarSil() => _del('profile/avatar');
  static Future<Map<String, dynamic>> ikiAdim() => _get('2fa');
  static Future<Map<String, dynamic>> ikiAdimAc(String gizli, String kod) => _post('2fa/enable', {'secret': gizli, 'code': kod});
  static Future<Map<String, dynamic>> ikiAdimKapat(String kod) => _post('2fa/disable', {'code': kod});
  static Future<Map<String, dynamic>> pushTest() => _post('push/test');

  // ---- Bildirim / müsaitlik / mesai / widget / whatsapp
  static Future<Map<String, dynamic>> bildirimAyar() => _get('alerts');
  static Future<Map<String, dynamic>> bildirimAyarKaydet(Map<String, dynamic> g) => _post('alerts', g);
  static Future<Map<String, dynamic>> musaitlik() => _get('availability');
  static Future<Map<String, dynamic>> calismaSaatleri(Map<String, dynamic> g) => _post('availability/hours', g);
  static Future<Map<String, dynamic>> mesai() => _get('schedule');
  static Future<Map<String, dynamic>> mesaiKaydet(Map<String, dynamic> g) => _post('schedule', g);
  static Future<Map<String, dynamic>> widgetAyar() => _get('widget');
  static Future<Map<String, dynamic>> widgetKaydet(Map<String, dynamic> g) => _post('widget', g);
  static Future<Map<String, dynamic>> whatsapp() => _get('whatsapp');
  static Future<Map<String, dynamic>> whatsappKaydet(Map<String, dynamic> g) => _post('whatsapp', g);
  static Future<Map<String, dynamic>> whatsappTest(String hedef) => _post('whatsapp/test', {'test_target': hedef});

  // ---- Personel / roller / bölümler / hazır yanıt / yasak / engel / tetikleyici
  static Future<Map<String, dynamic>> personel() => _get('agents');
  static Future<Map<String, dynamic>> personelEkle(Map<String, dynamic> g) => _post('agents', g);
  static Future<Map<String, dynamic>> personelGuncelle(int id, Map<String, dynamic> g) => _put('agents/$id', g);
  static Future<Map<String, dynamic>> personelSil(int id) => _del('agents/$id');
  static Future<Map<String, dynamic>> yetkiler(int id) => _get('agents/$id/permissions');
  static Future<Map<String, dynamic>> yetkiKaydet(int id, Map<String, dynamic> g) => _put('agents/$id/permissions', g);
  static Future<Map<String, dynamic>> roller() => _get('roles');
  static Future<Map<String, dynamic>> rolEkle(Map<String, dynamic> g) => _post('roles', g);
  static Future<Map<String, dynamic>> rolGuncelle(int id, Map<String, dynamic> g) => _put('roles/$id', g);
  static Future<Map<String, dynamic>> rolSil(int id) => _del('roles/$id');
  static Future<Map<String, dynamic>> bolumler() => _get('departments');
  static Future<Map<String, dynamic>> bolumEkle(Map<String, dynamic> g) => _post('departments', g);
  static Future<Map<String, dynamic>> bolumGuncelle(int id, Map<String, dynamic> g) => _put('departments/$id', g);
  static Future<Map<String, dynamic>> bolumSil(int id) => _del('departments/$id');
  static Future<Map<String, dynamic>> hazirYanitlar() => _get('canned');
  static Future<Map<String, dynamic>> hazirYanitEkle(Map<String, dynamic> g) => _post('canned', g);
  static Future<Map<String, dynamic>> hazirYanitGuncelle(int id, Map<String, dynamic> g) => _put('canned/$id', g);
  static Future<Map<String, dynamic>> hazirYanitSil(int id) => _del('canned/$id');
  static Future<Map<String, dynamic>> yasaklar() => _get('bans');
  static Future<Map<String, dynamic>> yasakEkle(Map<String, dynamic> g) => _post('bans', g);
  static Future<Map<String, dynamic>> yasakSil(int id) => _del('bans/$id');
  static Future<Map<String, dynamic>> erisimEngelleri() => _get('access-blocks');
  static Future<Map<String, dynamic>> erisimEngelle(int kullanici, String neden) => _post('access-blocks', {'user_id': kullanici, 'reason': neden});
  static Future<Map<String, dynamic>> erisimAc(int id) => _del('access-blocks/$id');
  static Future<Map<String, dynamic>> tetikleyiciler() => _get('triggers');
  static Future<Map<String, dynamic>> tetikleyiciAcKapa(int id) => _post('triggers/$id/toggle');
  static Future<Map<String, dynamic>> tetikleyiciSil(int id) => _del('triggers/$id');

  // ---- Acil durum / cihazlar / denetim / geçmiş / raporlar
  static Future<Map<String, dynamic>> acil() => _get('emergency');
  static Future<Map<String, dynamic>> acilEylem(String ne, [Map<String, dynamic>? g]) => _post('emergency/$ne', g ?? const {});
  static Future<Map<String, dynamic>> cihazlar() => _get('devices');
  static Future<Map<String, dynamic>> cihazSil(String ne, Object id) => _del('devices/$ne/$id');
  static Future<Map<String, dynamic>> oturumTemizle() => _post('devices/cleanup');
  static Future<Map<String, dynamic>> denetim({Map<String, dynamic>? q}) => _get('audit', q: q);
  static Future<Map<String, dynamic>> gecmis(Map<String, dynamic> q) => _get('history', q: q);
  static Future<Map<String, dynamic>> raporlar({String donem = 'daily'}) => _get('stats', q: {'period': donem});
  static Future<Map<String, dynamic>> raporDetay({String? from, String? to}) => _get('reports/detail', q: {'from': ?from, 'to': ?to});

  // ---- Ziyaretçi detayı / CRM / ekran
  static Future<Map<String, dynamic>> ziyaretci(int oturum) => _get('visitors/$oturum');

  /// Sohbet ekranı sağ blok: ziyaretçi + ağ + CRM + yasak + gezinti + olaylar (web paneli kapsamı).
  static Future<Map<String, dynamic>> sohbetZiyaretci(int sohbet) => _get('chats/$sohbet/visitor');
  static Future<Map<String, dynamic>> ekranAl(int oturum, {Object? hv}) => _get('visitors/$oturum/screen', q: {'hv': ?hv});
  static Future<Map<String, dynamic>> ekranIste(int oturum, {String kip = 'consent'}) => _post('visitors/$oturum/screen/request', {'mode': kip});
  static Future<Map<String, dynamic>> ekranIsaret(int oturum, {double? x, double? y, String? etiket}) =>
      _post('visitors/$oturum/screen/guide', {'x': x, 'y': y, 'label': ?etiket});
  static Future<Map<String, dynamic>> ekranDurdur(int oturum) => _post('visitors/$oturum/screen/stop');
  static Future<Map<String, dynamic>> musteriAdayi(int ziyaretci, Map<String, dynamic> g) => _post('crm/$ziyaretci/lead', g);
  static Future<Map<String, dynamic>> notEkle(int ziyaretci, String govde) => _post('crm/$ziyaretci/note', {'body': govde});
  static Future<Map<String, dynamic>> notSil(int not) => _del('crm/note/$not');
  static Future<Map<String, dynamic>> etiketEkle(int ziyaretci, String ad) => _post('crm/$ziyaretci/tag', {'name': ad});
  static Future<Map<String, dynamic>> etiketSil(int ziyaretci, int etiket) => _del('crm/$ziyaretci/tag/$etiket');

  // ---- Arama (WebRTC sinyalleşme)
  static Future<List<Map<String, dynamic>>> iceSunuculari() async => haritalar(harita(await Uyg.api.get('${Uyg.apiKok}/ice'))['ice']);
  static Future<void> aramaBaslat(int sohbet, String sdp, {bool video = true}) =>
      Uyg.api.post('${Uyg.apiKok}/chats/$sohbet/call/start', {'sdp': sdp, 'video': video});
  static Future<Map<String, dynamic>> aramaYokla(int sohbet) async => harita(await Uyg.api.get('${Uyg.apiKok}/chats/$sohbet/call/poll'));
  static Future<void> aramaIce(int sohbet, Map<String, dynamic> aday) => Uyg.api.post('${Uyg.apiKok}/chats/$sohbet/call/ice', {'candidate': aday});
  static Future<void> aramaBitir(int sohbet) => Uyg.api.post('${Uyg.apiKok}/chats/$sohbet/call/end');

  // ---- Hızlı yoklamalar (kısa zaman aşımı + ekran kapanınca iptal)
  static Future<Map<String, dynamic>> ekranAlHizli(int oturum, {Object? hv, CancelToken? iptal}) =>
      _getHizli('visitors/$oturum/screen', q: {'hv': ?hv}, iptal: iptal);

  /// Temsilcinin kaydırma konumunu ziyaretçinin tarayıcısına iter; ikisi de null → temizler.
  static Future<Map<String, dynamic>> ekranKaydir(int oturum, int? sx, int? sy) => _post('visitors/$oturum/screen/scroll', {'sx': sx, 'sy': sy});
  static Future<Map<String, dynamic>> aramaYoklaHizli(int sohbet, {CancelToken? iptal}) async =>
      harita(await Uyg.api.get('${Uyg.apiKok}/chats/$sohbet/call/poll', zamanAsimi: const Duration(seconds: 5), iptal: iptal));

  // ---- Yapay zeka asistanı (ayarlar, bilgi tabanı, günlük, deneme)
  static Future<Map<String, dynamic>> ai() => _get('ai');
  static Future<Map<String, dynamic>> aiKaydet(Map<String, dynamic> g) => _post('ai', g);
  static Future<Map<String, dynamic>> aiDene(String q) => _post('ai/test', {'q': q});
  static Future<Map<String, dynamic>> aiBilgiler({String durum = 'active', String q = ''}) => _get('ai/knowledge', q: {'status': durum, 'q': q});
  static Future<Map<String, dynamic>> aiBilgiEkle(Map<String, dynamic> g) => _post('ai/knowledge', g);
  static Future<Map<String, dynamic>> aiBilgiGuncelle(int id, Map<String, dynamic> g) => _put('ai/knowledge/$id', g);
  static Future<Map<String, dynamic>> aiBilgiSil(int id) => _del('ai/knowledge/$id');
  static Future<Map<String, dynamic>> aiBilgiIncele(List<int> ids, String durum) => _post('ai/knowledge/review', {'ids': ids, 'status': durum});
  static Future<Map<String, dynamic>> aiGunluk() => _get('ai/logs');
  static Future<Map<String, dynamic>> aiGecmistenOgren({int gun = 365, int enCok = 1000}) => _post('ai/learn-history', {'days': gun, 'max': enCok});
  static Future<Map<String, dynamic>> aiSistemSenkron() => _post('ai/sync-system', {});
  static Future<Map<String, dynamic>> aiEgitim() => _get('ai/train');
  static Future<Map<String, dynamic>> aiEgitimMesaj(String metin) => _post('ai/train/message', {'text': metin});
  static Future<Map<String, dynamic>> aiEgitimOgret(String soru, String yanit, {int? logId}) =>
      _post('ai/train/teach', {'question': soru, 'answer': yanit, 'log_id': ?logId});
  static Future<Map<String, dynamic>> aiEgitimOnayla(int? logId) => _post('ai/train/approve', {'log_id': ?logId});
  static Future<Map<String, dynamic>> aiEgitimTemizle() => _del('ai/train');
  // Butoi — destek talebi otomatik karşılama
  static Future<Map<String, dynamic>> aiTicket() => _get('ai/ticket');
  static Future<Map<String, dynamic>> aiTicketKaydet(Map<String, dynamic> g) => _post('ai/ticket', g);
  static Future<Map<String, dynamic>> aiTicketKuru() => _post('ai/ticket/kuru', {});
  static Future<Map<String, dynamic>> aiTicketGecmis() => _get('ai/ticket/gecmis');
}
