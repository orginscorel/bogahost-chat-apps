// Sunucu uçları tek yerde. Tüm yollar /api/app/v1 altındadır (routes/app.php).
import 'dart:io';

import 'dart:typed_data';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:dio/dio.dart';

import '../oturum.dart';
import 'json.dart';
import 'modeller.dart';

String _y(String yol) => '${Uyg.apiKok}/$yol';

/// Panel uçları hata durumunda da 200 ile `{ok:false, error:'…'}` dönebilir; bunu istisnaya çevirir.
dynamic _k(dynamic v) {
  if (v is Map && v['ok'] == false) {
    final e = v['error'];
    throw ApiHata(200, e is String && e.isNotEmpty ? e : (v['message'] is String ? '${v['message']}' : 'İşlem yapılamadı.'));
  }
  return v;
}

Future<dynamic> _post(String yol, [Object? g]) async => _k(await Uyg.api.post(_y(yol), g));
Future<dynamic> _get(String yol, {Map<String, dynamic>? q}) async => _k(await Uyg.api.get(_y(yol), q: q));

class Depo {
  Depo._();

  // ---- Genel
  static Future<Ozet> ozet() async => Ozet.coz(harita(await _get('stats')));
  static Future<List<Uye>> ekip() async => haritalar(harita(await _get('team'))['agents']).map(Uye.coz).toList();
  static Future<String> musaitlik(String v) async => metin(harita(await _post('availability', {'availability': v}))['availability'], v);

  // ---- Bildirimler
  static Future<({List<Bildirim> ogeler, int okunmamis, bool engelli})> bildirimler() async {
    final m = harita(await _get('notifications/feed'));
    return (ogeler: haritalar(m['items']).map(Bildirim.coz).toList(), okunmamis: tamsayi(m['unread']), engelli: mantik(m['blocked']));
  }

  static Future<void> bildirimOkundu(int id) => _post('notifications/$id/mark');
  static Future<void> bildirimlerOkundu() => _post('notifications/readall');

  // ---- Sohbetler
  static Future<({List<Sohbet> sohbetler, Map<String, int> sayilar, bool dahaVar})> sohbetler({String durum = 'open', int sayfa = 1}) async {
    final m = harita(await _get('chats', q: {'status': durum, 'page': sayfa}));
    final s = harita(m['counts']).map((k, v) => MapEntry(k, tamsayi(v)));
    return (sohbetler: haritalar(m['conversations']).map(Sohbet.coz).toList(), sayilar: s, dahaVar: mantik(m['has_more']));
  }

  /// Mesaj yoklaması: kısa alma zaman aşımı (takılan tek istek ekranı dondurmasın), ekran kapanınca iptal edilebilir.
  static Future<Yoklama> yokla(int id, {int sonra = 0, CancelToken? iptal}) async =>
      Yoklama.coz(harita(await Uyg.api.get(_y('chats/$id/poll'), q: {'after': sonra}, zamanAsimi: const Duration(seconds: 8), iptal: iptal).then(_k)));

  /// Sohbet detayı (web admin/chats/{id}): visitor, network, crm, ban_active, favorite, archived, history, participants, messages…
  static Future<Map<String, dynamic>> sohbetDetay(int id) async => harita(harita(await _get('chats/$id'))['conversation']);

  /// Ziyaretçi dilini zorla + son mesajları çevir (web: changeLang).
  static Future<void> dilAyarla(int id, String dil) => _post('chats/$id/lang', {'lang': dil});

  /// Ziyaretçinin sesli/görüntülü/ekran talebi şeridini kapat.
  static Future<void> iletisimTalebiTemizle(int id) => _post('chats/$id/contact-request/clear');

  /// Transkript PDF baytları (web: PDF indir).
  static Future<Uint8List> transkriptPdf(int id) => Uyg.api.indir(_y('chats/$id/transcript.pdf'));

  /// WHMCS hizmet listesi (yetki chats.cancel_request): {match, client, currency, services[], visitor}.
  static Future<Map<String, dynamic>> hizmetler(int id) async => harita(await _get('chats/$id/hizmetler/liste'));

  /// Gerçek WHMCS iptal talebi: service_id, cancellationreason (3–2000), type Immediate|End of Billing Period, confirm, identity_confirmed, service_label.
  static Future<Map<String, dynamic>> iptalTalebi(int id, Map<String, dynamic> g) async => harita(await _post('chats/$id/hizmetler/iptal-talebi', g));
  static Future<Mesaj> yanitla(int id, String govde, {bool icNot = false}) async =>
      Mesaj.coz(harita(harita(await _post('chats/$id/reply', {'body': govde, 'internal': icNot ? 1 : 0}))['message']));
  static Future<void> yaziyor(int id) => _post('chats/$id/typing');
  static Future<void> katil(int id) => _post('chats/$id/join');
  static Future<void> ayril(int id) => _post('chats/$id/leave');
  static Future<void> kapat(int id) => _post('chats/$id/close');
  static Future<void> yenidenAc(int id) => _post('chats/$id/reopen');
  static Future<void> devral(int id) => _post('chats/$id/takeover');
  static Future<void> izle(int id) => _post('chats/$id/supervise');
  static Future<void> fisilda(int id, String govde) => _post('chats/$id/whisper', {'body': govde});
  static Future<void> favori(int id) => _post('chats/$id/favorite');
  static Future<void> arsivle(int id) => _post('chats/$id/archive');
  static Future<void> kacanCozuldu(int id) => _post('chats/$id/missed-resolve');

  /// Sohbetten yasakla: scopes ip/ip_range/fingerprint/visitor/email/full, reason, duration 1h/1d/1w/1m/perm, subnet 24/16.
  static Future<Map<String, dynamic>> sohbetYasakla(int id, Map<String, dynamic> g) async => harita(await _post('chats/$id/ban', g));
  static Future<Map<String, dynamic>> sohbetYasakKaldir(int id) async => harita(await _post('chats/$id/unban'));
  static Future<void> transkriptEposta(int id, {String? eposta}) => _post('chats/$id/transcript/email', {'email': ?eposta});
  static Future<String?> transkriptBaglanti(int id) async {
    final m = harita(await _get('chats/$id/transcript/link'));
    return metinYa(m['url'] ?? m['link']);
  }

  static Future<String?> portalBaglanti(int id) async {
    final m = harita(await _get('chats/$id/portal-link'));
    return metinYa(m['url'] ?? m['link']);
  }

  static Future<void> mesajDuzenle(int sohbet, int mesaj, String govde) => Uyg.api.put(_y('chats/$sohbet/messages/$mesaj'), {'body': govde});
  static Future<void> mesajSil(int sohbet, int mesaj) => Uyg.api.delete(_y('chats/$sohbet/messages/$mesaj'));
  static Future<List<Map<String, dynamic>>> talepBolumleri() async => haritalar(harita(await _get('ticket-departments'))['departments']);
  static Future<Map<String, dynamic>> talepFormu(int id, {String kip = 'general', int bolum = 0, String konu = ''}) async =>
      harita(await _post('chats/$id/request-ticket', {'mode': kip, 'department_id': bolum, 'subject': konu}));

  /// Dosya / görsel gönderir (multipart).
  static Future<Mesaj> dosyaGonder(int id, File dosya, {void Function(int, int)? ilerleme}) async {
    final ad = dosya.uri.pathSegments.last;
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(dosya.path, filename: ad)});
    final c = await Uyg.api.dio.post<dynamic>(_y('chats/$id/upload'), data: form, onSendProgress: ilerleme);
    final d = c.statusCode ?? 0;
    final v = c.data;
    if (d >= 200 && d < 300 && v is Map && v['ok'] == true) return Mesaj.coz(harita(v['message']));
    throw ApiHata(d, v is Map && v['error'] is String ? '${v['error']}' : 'Dosya gönderilemedi (HTTP $d).');
  }

  // ---- Ziyaretçiler
  static Future<List<Ziyaretci>> canliZiyaretciler() async => haritalar(harita(await _get('visitors/live'))['visitors']).map(Ziyaretci.coz).toList();
  static Future<Map<String, dynamic>> davetEt(int oturum, {String? mesaj}) async => harita(await _post('visitors/$oturum/invite', {'message': ?mesaj}));
  static Future<Map<String, dynamic>> sohbetBaslat(int oturum, {String? mesaj}) async =>
      harita(await _post('visitors/$oturum/start-chat', {'message': ?mesaj}));

  // ---- Hazır yanıt / arama
  static Future<List<HazirYanit>> hazirYanitlar(String q) async => haritalar(harita(await _get('canned', q: {'q': q}))['items']).map(HazirYanit.coz).toList();
  static Future<List<Map<String, dynamic>>> ara(String q) async => haritalar(harita(await _get('search', q: {'q': q}))['groups']);

  // ---- Dahili sohbet
  static Future<({List<Uye> kisiler, Map<String, int> okunmamis})> icKisiler() async {
    final m = harita(await _get('internal/contacts'));
    return (kisiler: haritalar(m['agents']).map(Uye.coz).toList(), okunmamis: harita(m['unread']).map((k, v) => MapEntry(k, tamsayi(v))));
  }

  static Future<({List<IcMesaj> mesajlar, Map<String, int> okunmamis})> icYokla({int kisi = 0, int sonra = 0}) async {
    final m = harita(await _get('internal/poll', q: {'peer': kisi, 'after': sonra}));
    return (mesajlar: haritalar(m['messages']).map(IcMesaj.coz).toList(), okunmamis: harita(m['unread']).map((k, v) => MapEntry(k, tamsayi(v))));
  }

  static Future<void> icGonder(String govde, {int kisi = 0}) => _post('internal/send', {'body': govde, 'peer': kisi});
  static Future<void> icSabitle(int id) => _post('internal/pin', {'id': id});
  static Future<void> icDosya(File dosya, {int kisi = 0}) async {
    final form = FormData.fromMap({'file': await MultipartFile.fromFile(dosya.path, filename: dosya.uri.pathSegments.last), 'peer': kisi});
    final c = await Uyg.api.dio.post<dynamic>(_y('internal/upload'), data: form);
    if ((c.statusCode ?? 0) >= 400) throw ApiHata(c.statusCode, 'Dosya gönderilemedi.');
  }

  // ---- Dosya indirme (ekler)
  static Future<File> ekIndir(String url, String ad) async {
    final b = await Uyg.api.indir(Uyg.tamAdres(url));
    final d = Directory('${Directory.systemTemp.path}/bogahost-destek');
    if (!d.existsSync()) d.createSync(recursive: true);
    final f = File('${d.path}/${ad.replaceAll(RegExp(r'[^\w.\-]+'), '_')}');
    await f.writeAsBytes(b);
    return f;
  }
}
