// Vitrin kipi: App Store / mağaza ekran görüntüleri için anonim, uydurma örnek veri.
// Yalnız `--dart-define=VITRIN=true` ile derlenen paketlerde etkindir; üretim derlemelerinde `vitrinAcik` sabiti false
// olduğundan bu sınıf hiç kurulmaz ve ağ davranışı değişmez. Ağa hiç çıkılmaz, gerçek müşteri verisi kullanılmaz.
import 'dart:io';
import 'dart:typed_data';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const vitrinAcik = bool.fromEnvironment('VITRIN');

/// Açılışta gösterilecek ekran. Sırayla: VITRIN_EKRAN ortam değişkeni (Mac), uygulama belgeler dizinindeki
/// `vitrin-ekran.txt` (simülatör: `simctl get_app_container … data`), NSUserDefaults `flutter.vitrin_ekran`
/// (simctl launch … -flutter.vitrin_ekran X), en son --dart-define=VITRIN_EKRAN.
/// Değerler: sohbetler | gorusme | butoi | ziyaretciler | raporlar | ozet | ayarlar | ayar-bildirim | ayar-widget | ayar-yasaklar
Future<String> vitrinEkranOku() async {
  if (!vitrinAcik) return '';
  final e = Platform.environment['VITRIN_EKRAN'] ?? '';
  if (e.isNotEmpty) return e;
  try {
    final d = await getApplicationDocumentsDirectory();
    final f = File('${d.path}/vitrin-ekran.txt');
    if (await f.exists()) {
      final v = (await f.readAsString()).trim();
      if (v.isNotEmpty) return v;
    }
  } catch (_) {}
  try {
    final v = (await SharedPreferences.getInstance()).getString('vitrin_ekran') ?? '';
    if (v.isNotEmpty) return v;
  } catch (_) {}
  return const String.fromEnvironment('VITRIN_EKRAN', defaultValue: 'sohbetler');
}

/// Masaüstünde pencere ekrana sığmasa da tam kareyi almak için uygulama kendi görüntüsünü yazar: kök RepaintBoundary.
final vitrinAnahtar = GlobalKey();

/// Masaüstünde 1440×900 mantıksal içeriğin kendi sınırı (OlcekSarmal içinde, pencere küçükse ölçeklenir): bundan
/// pixelRatio 2 ile alınan kare pencereden bağımsız tam 2880×1800 olur.
final vitrinIcAnahtar = GlobalKey();

/// Ekran yerleşince (yaklaşık [bekle] sonra) uygulamayı 2× piksel oranında PNG'ye yazar ve masaüstünde çıkar.
/// Dosya: uygulama destek dizini/vitrin-<ekran>.png (Mac'te ~/Library/Containers/<paket>/Data/Library/Application Support/…).
Future<void> vitrinYakala(String ekran, {Duration bekle = const Duration(seconds: 6)}) async {
  if (!vitrinAcik || !(Platform.isMacOS || Platform.isWindows || Platform.isLinux)) return;
  await Future<void>.delayed(bekle);
  try {
    final ro = (vitrinIcAnahtar.currentContext ?? vitrinAnahtar.currentContext)?.findRenderObject();
    if (ro is! RenderRepaintBoundary) return;
    // İç sınır 1440×900 mantıksal → 2×; dış sınıra düşülürse genişlik 2880 olacak oran.
    final oran = ro.size.width > 0 ? 2880 / ro.size.width : 2.0;
    final img = await ro.toImage(pixelRatio: oran);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) return;
    final d = await getApplicationSupportDirectory();
    final f = File('${d.path}/vitrin-$ekran.png');
    await f.writeAsBytes(bd.buffer.asUint8List(), flush: true);
    debugPrint('vitrin: ${f.path}');
  } catch (e) {
    debugPrint('vitrin yakalama hatası: $e');
  }
  await Future<void>.delayed(const Duration(milliseconds: 500));
  exit(0);
}

/// Ağ yerine sabit yanıtlar döndüren istemci. Yollar `/api/app/v1/…` biçiminde gelir.
class VitrinApi extends BogaApi {
  VitrinApi() : super(uygulama: 'destek', csrfCerezi: 'destek_csrf') {
    sunucu = 'https://chat.bogahost.com';
    jeton = 'vitrin';
  }

  @override
  Future<void> baslat() async {}
  @override
  Future<bool> oturumVar() async => true;
  @override
  Future<void> jetonKaydet(String? j) async => jeton = j;
  @override
  Future<void> sunucuAyarla(String url) async => sunucu = url;
  @override
  Future<void> cerezleriTemizle() async {}
  @override
  Future<Uint8List> indir(String yol, {Map<String, dynamic>? q, void Function(int, int)? ilerleme}) async => Uint8List(0);
  @override
  Future<dynamic> get(String yol, {Map<String, dynamic>? q, Duration? zamanAsimi, CancelToken? iptal}) async => _yanit(yol, q ?? const {});
  @override
  Future<dynamic> post(String yol, [Object? govde]) async => _yanit(yol, const {});
  @override
  Future<dynamic> put(String yol, [Object? govde]) async => _yanit(yol, const {});
  @override
  Future<dynamic> patch(String yol, [Object? govde]) async => _yanit(yol, const {});
  @override
  Future<dynamic> delete(String yol, {Object? govde, Map<String, dynamic>? q}) async => _yanit(yol, q ?? const {});

  Future<dynamic> _yanit(String yol, Map<String, dynamic> q) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final y = yol.replaceFirst(RegExp(r'^/api/app/v1/'), '');
    if (y == 'me') return {'user': _ben, 'server': {'version': '1.9.2'}};
    if (y == 'stats') return _ozet;
    if (y == 'team') return {'agents': _ekip};
    if (y == 'notifications/feed') return {'items': const [], 'unread': 0, 'blocked': false};
    if (y == 'chats') {
      final d = '${q['status'] ?? 'open'}';
      final l = _sohbetler.where((s) => d == 'all' || s['status'] == d).toList();
      return {'conversations': l, 'counts': _sayilar, 'has_more': false};
    }
    final poll = RegExp(r'^chats/(\d+)/poll$').firstMatch(y);
    if (poll != null) {
      final sonra = int.tryParse('${q['after'] ?? 0}') ?? 0;
      return {..._yoklama, 'messages': _mesajlar.where((m) => (m['id'] as int) > sonra).toList()};
    }
    if (RegExp(r'^chats/\d+$').hasMatch(y)) return {'conversation': _detay};
    if (y == 'visitors/live') return {'visitors': _ziyaretciler};
    if (y == 'canned') return {'items': const []};
    if (y == 'panel/ai') return {'config': {'name': 'Butoi'}};
    if (y == 'panel/ai/train') return {'messages': _egitim};
    if (y == 'panel/stats') return _raporlar;
    if (y == 'panel/reports/detail') return _raporDetay;
    if (y == 'internal/contacts') return {'contacts': _ekip, 'unread': const {}};
    if (y == 'internal/poll') return {'messages': const [], 'unread': const {}};
    return {'ok': true};
  }
}

// ---- Sabit veriler (tamamı uydurma) --------------------------------------------------------------------------------

const _yetkiler = [
  'agents.manage', 'bans.manage', 'canned.manage', 'chats.call', 'chats.cancel_request', 'chats.reply', 'chats.supervise', 'chats.transcript',
  'chats.view', 'departments.manage', 'internal.use', 'reports.view', 'roles.manage', 'screen.consent', 'screen.direct', 'settings.manage',
  'visitors.view', 'widget.manage',
];

const _ben = {
  'id': 1, 'name': 'Elif Kaya', 'display_name': 'Elif Kaya', 'email': 'elif@ornek-firma.com', 'role': 'admin', 'role_name': 'Yönetici',
  'permissions': _yetkiler, 'is_admin': true, 'availability': 'online', 'avatar': null, 'department': 'Teknik Destek', 'totp_enabled': true,
};

const _ozet = {
  'online': 6, 'today_visitors': 148, 'active_chats': 4, 'pending': 2, 'today': 23, 'offline_msgs': 1, 'total': 3482, 'avg_rating': 4.8,
  'rated': 1290, 'internal_unread': 0, 'version': '1.9.2', 'emergency': {'active': false, 'type': null}, 'attack': false, 'after_hours': false,
  'me_availability': 'online',
};

const _ekip = [
  {'id': 1, 'name': 'Elif Kaya', 'avatar': null, 'role': 'Yönetici', 'status': 'online', 'availability': 'online', 'online': true, 'last_seen': null},
  {'id': 2, 'name': 'Murat Aydın', 'avatar': null, 'role': 'Temsilci', 'status': 'online', 'availability': 'online', 'online': true, 'last_seen': null},
  {'id': 3, 'name': 'Selin Koç', 'avatar': null, 'role': 'Temsilci', 'status': 'online', 'availability': 'away', 'online': true, 'last_seen': null},
  {'id': 4, 'name': 'Burak Çelik', 'avatar': null, 'role': 'Süpervizör', 'status': 'offline', 'availability': 'dnd', 'online': false, 'last_seen': null},
  {'id': 5, 'name': 'Derya Aksoy', 'avatar': null, 'role': 'Temsilci', 'status': 'offline', 'availability': 'offline', 'online': false, 'last_seen': null},
];

const _sayilar = {'open': 4, 'pending': 2, 'missed': 0, 'offline': 1, 'closed': 3471};

const _sohbetler = [
  {
    'id': 1, 'visitor': 'Ayşe Demir', 'email': 'ayse.demir@ornek.com', 'department': 'Teknik Destek', 'agent': 'Elif Kaya', 'status': 'open',
    'country': 'TR', 'visitor_online': true, 'rating': null, 'last': '2 dk önce', 'preview': 'Harika, teşekkür ederim! DNS kaydı güncellendi.',
    'sneak_peek': null, 'unread': 1, 'last_from': 'visitor', 'favorite': true, 'archived': false, 'missed': false, 'muted': false,
  },
  {
    'id': 2, 'visitor': 'Mehmet Yıldız', 'email': 'mehmet@ornek-sirket.com', 'department': 'Muhasebe', 'agent': 'Murat Aydın', 'status': 'open',
    'country': 'TR', 'visitor_online': true, 'rating': null, 'last': '7 dk önce', 'preview': 'Faturamı ödedim ama hizmet hâlâ askıda görünüyor.',
    'sneak_peek': 'Dekontu da ekliyorum', 'unread': 0, 'last_from': 'visitor', 'favorite': false, 'archived': false, 'missed': false, 'muted': false,
  },
  {
    'id': 3, 'visitor': 'Zeynep Arslan', 'email': null, 'department': 'Satış', 'agent': 'Selin Koç', 'status': 'open',
    'country': 'DE', 'visitor_online': true, 'rating': null, 'last': '12 dk önce', 'preview': 'Dosya', 'sneak_peek': null, 'unread': 0,
    'last_from': 'agent', 'favorite': false, 'archived': false, 'missed': false, 'muted': false,
  },
  {
    'id': 4, 'visitor': 'Can Öztürk', 'email': 'can.ozturk@ornek.net', 'department': 'Teknik Destek', 'agent': 'Elif Kaya', 'status': 'open',
    'country': 'TR', 'visitor_online': false, 'rating': 5, 'last': '25 dk önce', 'preview': 'Teşekkürler, sorun çözüldü 🙏', 'sneak_peek': null,
    'unread': 0, 'last_from': 'visitor', 'favorite': false, 'archived': false, 'missed': false, 'muted': true,
  },
  {
    'id': 5, 'visitor': 'Elif Şahin', 'email': null, 'department': 'Teknik Destek', 'agent': null, 'status': 'pending',
    'country': 'NL', 'visitor_online': true, 'rating': null, 'last': '1 dk önce', 'preview': 'SSL sertifikam ne zaman aktif olur?',
    'sneak_peek': null, 'unread': 1, 'last_from': 'visitor', 'favorite': false, 'archived': false, 'missed': false, 'muted': false,
  },
  {
    'id': 6, 'visitor': 'Ziyaretçi', 'email': null, 'department': 'Satış', 'agent': null, 'status': 'pending',
    'country': 'TR', 'visitor_online': true, 'rating': null, 'last': 'az önce', 'preview': 'Kurumsal e-posta paketlerinizde kota ne kadar?',
    'sneak_peek': null, 'unread': 1, 'last_from': 'visitor', 'favorite': false, 'archived': false, 'missed': false, 'muted': false,
  },
];

const _sayfalar = [
  {'url': 'https://bogahost.com/', 'title': 'Ana sayfa', 'at': '14:02'},
  {'url': 'https://bogahost.com/alan-adi', 'title': 'Alan Adı Kaydı', 'at': '14:04'},
  {'url': 'https://bogahost.com/musteri/alan-adlari', 'title': 'Alan Adlarım', 'at': '14:09'},
  {'url': 'https://bogahost.com/bilgi/dns-yonetimi', 'title': 'DNS Yönetimi', 'at': '14:15'},
];

const _mesajlar = [
  {'id': 101, 'sender': 'system', 'sender_id': null, 'name': 'Sistem', 'avatar': null, 'type': 'event', 'internal': false, 'whisper': false,
    'body': 'Sohbet Teknik Destek bölümünde başlatıldı', 'at': '14:09', 'read': true, 'edited': false, 'deleted': false, 'own': false},
  {'id': 102, 'sender': 'visitor', 'sender_id': null, 'name': 'Ayşe Demir', 'avatar': null, 'type': 'text', 'internal': false, 'whisper': false,
    'body': 'Merhaba, alan adımı sizin sunucuya taşıdım ama DNS kayıtlarını nereden güncelleyeceğimi bulamadım.', 'at': '14:09', 'read': true,
    'edited': false, 'deleted': false, 'own': false},
  {'id': 103, 'sender': 'agent', 'sender_id': null, 'name': 'Butoi', 'avatar': null, 'type': 'text', 'internal': false, 'whisper': false,
    'body': 'Merhaba Ayşe Hanım 👋 DNS kayıtlarınızı Müşteri Paneli › Alan Adlarım › DNS Yönetimi bölümünden düzenleyebilirsiniz. İsterseniz adımları birlikte ilerleyelim.',
    'at': '14:09', 'read': true, 'edited': false, 'deleted': false, 'own': false},
  {'id': 104, 'sender': 'visitor', 'sender_id': null, 'name': 'Ayşe Demir', 'avatar': null, 'type': 'file', 'internal': false, 'whisper': false,
    'body': 'A kaydını yeni sunucu IP\'sine çevirmem gerekiyor, mevcut ayarları ekliyorum.', 'at': '14:11', 'read': true, 'edited': false,
    'deleted': false, 'own': false, 'file': {'url': '', 'dl': '', 'name': 'dns-ayarlari.pdf', 'size': 184320, 'image': false, 'audio': false, 'video': false}},
  {'id': 105, 'sender': 'agent', 'sender_id': 1, 'name': 'Elif Kaya', 'avatar': null, 'type': 'text', 'internal': false, 'whisper': false,
    'body': 'Dosyanızı inceledim. A kaydını 185.0.0.10 olarak güncellemeniz yeterli; değişikliğin yayılması 15-30 dakika sürer.', 'at': '14:13',
    'read': true, 'edited': false, 'deleted': false, 'own': true},
  {'id': 106, 'sender': 'agent', 'sender_id': 1, 'name': 'Elif Kaya', 'avatar': null, 'type': 'text', 'internal': true, 'whisper': false,
    'body': 'Not: müşteri dün de SSL için yazmış, DNS yayılınca sertifika otomatik kurulacak.', 'at': '14:13', 'read': true, 'edited': false,
    'deleted': false, 'own': true},
  {'id': 107, 'sender': 'visitor', 'sender_id': null, 'name': 'Ayşe Demir', 'avatar': null, 'type': 'file', 'internal': false, 'whisper': false,
    'body': null, 'at': '14:18', 'read': true, 'edited': false, 'deleted': false, 'own': false,
    'file': {'url': '', 'dl': '', 'name': 'Sesli mesaj (0:14).m4a', 'size': 96400, 'image': false, 'audio': true, 'video': false}},
  {'id': 108, 'sender': 'agent', 'sender_id': 1, 'name': 'Elif Kaya', 'avatar': null, 'type': 'text', 'internal': false, 'whisper': false,
    'body': 'Sesli mesajınızı dinledim; kaydı tarafımızdan da kontrol ettim, doğru görünüyor ✅ Siteniz birkaç dakika içinde yeni sunucudan yayınlanacak.',
    'at': '14:19', 'read': true, 'edited': false, 'deleted': false, 'own': true},
  {'id': 109, 'sender': 'visitor', 'sender_id': null, 'name': 'Ayşe Demir', 'avatar': null, 'type': 'text', 'internal': false, 'whisper': false,
    'body': 'Harika, teşekkür ederim! DNS kaydı güncellendi.', 'at': '14:21', 'read': false, 'edited': false, 'deleted': false, 'own': false},
];

const _yoklama = {
  'status': 'open', 'sneak_peek': null, 'visitor_online': true, 'current_url': 'https://bogahost.com/bilgi/dns-yonetimi', 'session_id': 1,
  'contact_request': null, 'visitor_lang': 'tr', 'rating': null, 'rating_comment': null, 'read_upto': 108, 'pageviews': _sayfalar,
};

const _detay = {
  'id': 1, 'status': 'open', 'missed': false, 'favorite': true, 'archived': false, 'session_id': 1, 'visitor_id': 1, 'visitor_lang': 'tr',
  'translate_on': false,
  'crm': {'lead_status': 'müşteri', 'lead_score': 72, 'assigned_to': 1, 'assigned_name': 'Elif Kaya', 'follow_up_at': null, 'tags': ['dns', 'taşıma'], 'notes': ''},
  'ban_active': 0, 'bans': [], 'can': {'ban': true},
  'visitor': {'name': 'Ayşe Demir', 'email': 'ayse.demir@ornek.com', 'phone': null, 'visits': 3, 'chats': 2, 'country': 'TR', 'city': 'İzmir',
    'first_seen': '12 Eki 2026', 'whmcs_id': 1042},
  'network': {'ip': '10.20.30.40', 'port': null, 'device': 'Masaüstü', 'browser': 'Chrome 142', 'os': 'macOS 26', 'user_agent': 'Mozilla/5.0',
    'language': 'tr-TR', 'timezone': 'Europe/Istanbul', 'screen': '1440×900', 'referrer': 'https://www.google.com/', 'utm': {},
    'current_url': 'https://bogahost.com/bilgi/dns-yonetimi', 'fingerprint': null, 'visitor_uid': null, 'ban': null, 'screen_consent': false, 'screen_direct': false},
  'session_info': {'id': 1, 'is_online': true, 'is_chatting': true, 'country': 'TR', 'city': 'İzmir', 'current_title': 'DNS Yönetimi',
    'started': '14:02', 'last_activity': 'az önce', 'pageviews': 4, 'local_time': '14:21', 'sneak_peek': null},
  'pageviews': _sayfalar, 'events': [], 'history': [], 'agents': [], 'department': 'Teknik Destek', 'agent': 'Elif Kaya',
  'participants': [{'id': 1, 'name': 'Elif Kaya', 'avatar': null}], 'joined': true, 'read_upto': 108, 'rating': null, 'rating_comment': null,
  'meta': {'name': 'Ayşe Demir', 'email': 'ayse.demir@ornek.com', 'department_id': 2, 'subject': 'DNS kaydı', 'ai_turns': 1},
  'messages': _mesajlar,
};

const _ziyaretciler = [
  {'id': 1, 'name': 'Ayşe Demir', 'email': 'ayse.demir@ornek.com', 'url': 'https://bogahost.com/bilgi/dns-yonetimi', 'title': 'DNS Yönetimi', 'pageviews': 4,
    'country': 'TR', 'city': 'İzmir', 'device': 'Masaüstü', 'browser': 'Chrome', 'os': 'macOS', 'ip': '10.20.30.40', 'referrer_label': 'Google', 'referrer_kind': 'search',
    'referrer_line2': 'dns yönetimi', 'referrer_detail': null, 'sneak_peek': null, 'is_chatting': true, 'since': '19 dk', 'last': 'az önce'},
  {'id': 2, 'name': null, 'email': null, 'url': 'https://bogahost.com/kurumsal-eposta', 'title': 'Kurumsal E-posta', 'pageviews': 6, 'country': 'TR',
    'city': 'İstanbul', 'device': 'Mobil', 'browser': 'Safari', 'os': 'iOS', 'ip': '10.20.31.7', 'referrer_label': 'Instagram', 'referrer_kind': 'social',
    'referrer_line2': null, 'referrer_detail': null, 'sneak_peek': 'e-posta paketi fiyat', 'is_chatting': false, 'since': '4 dk', 'last': '10 sn önce'},
  {'id': 3, 'name': 'Jonas Weber', 'email': null, 'url': 'https://bogahost.com/en/vps', 'title': 'VPS Servers', 'pageviews': 3, 'country': 'DE', 'city': 'Berlin',
    'device': 'Masaüstü', 'browser': 'Firefox', 'os': 'Windows', 'ip': '10.20.32.9', 'referrer_label': 'Doğrudan', 'referrer_kind': 'direct', 'referrer_line2': null,
    'referrer_detail': null, 'sneak_peek': null, 'is_chatting': false, 'since': '2 dk', 'last': '35 sn önce'},
  {'id': 4, 'name': null, 'email': null, 'url': 'https://bogahost.com/hosting', 'title': 'Web Hosting Paketleri', 'pageviews': 2, 'country': 'TR', 'city': 'Ankara',
    'device': 'Mobil', 'browser': 'Chrome', 'os': 'Android', 'ip': '10.20.33.2', 'referrer_label': 'Google Ads', 'referrer_kind': 'ads', 'referrer_line2': 'hosting kampanya',
    'referrer_detail': null, 'sneak_peek': null, 'is_chatting': false, 'since': '1 dk', 'last': 'az önce'},
  {'id': 5, 'name': 'Sanne de Vries', 'email': 'sanne@ornek.nl', 'url': 'https://bogahost.com/en/ssl', 'title': 'SSL Certificates', 'pageviews': 9, 'country': 'NL',
    'city': 'Utrecht', 'device': 'Tablet', 'browser': 'Safari', 'os': 'iPadOS', 'ip': '10.20.34.5', 'referrer_label': 'Google', 'referrer_kind': 'search',
    'referrer_line2': 'ssl certificate turkey', 'referrer_detail': null, 'sneak_peek': null, 'is_chatting': false, 'since': '11 dk', 'last': '1 dk önce'},
  {'id': 6, 'name': null, 'email': null, 'url': 'https://bogahost.com/iletisim', 'title': 'İletişim', 'pageviews': 1, 'country': 'TR', 'city': 'Bursa', 'device': 'Masaüstü',
    'browser': 'Edge', 'os': 'Windows', 'ip': '10.20.35.1', 'referrer_label': 'Doğrudan', 'referrer_kind': 'direct', 'referrer_line2': null, 'referrer_detail': null,
    'sneak_peek': null, 'is_chatting': false, 'since': '30 sn', 'last': 'az önce'},
];

const _egitim = [
  {'id': 1, 'role': 'user', 'text': 'Yıllık hosting paketlerinde indirim yenilemelerde de geçerli mi?', 'meta': {}, 'log_id': null},
  {'id': 2, 'role': 'assistant', 'log_id': 501,
    'text': 'Evet. Sipariş sırasında uygulanan indirimli tutar hizmete kaydedilir ve yenilemelerde de aynı tutar üzerinden fatura kesilir. Kampanya firmamızca sona erdirilse bile mevcut müşteriler güncel oran üzerinden indirimli yenilemeye devam eder.',
    'meta': {'ok': true, 'score': 92, 'question': 'Yıllık hosting paketlerinde indirim yenilemelerde de geçerli mi?', 'answer': '', 'approved': true,
      'sources': [{'id': 3069, 'title': 'Kampanyalı fiyat yenilemelerde geçerli mi?'}]}},
  {'id': 3, 'role': 'user', 'text': 'Müşteri SSL sertifikasının aktif olmadığını söylüyor, ne yanıtlamalıyım?', 'meta': {}, 'log_id': null},
  {'id': 4, 'role': 'assistant', 'log_id': 502,
    'text': 'SSL sertifikası, alan adının DNS kayıtları sunucumuza yönlendikten sonra otomatik kurulur; yayılma 15-30 dakika sürebilir. Müşteriden DNS\'in güncel olduğunu doğrulamasını isteyin; 1 saati geçtiyse Teknik Destek talebi açarak kurulumu elle tetikleyebiliriz.',
    'meta': {'ok': true, 'score': 86, 'question': 'Müşteri SSL sertifikasının aktif olmadığını söylüyor, ne yanıtlamalıyım?', 'answer': '', 'approved': false,
      'sources': [{'id': 2890, 'title': 'SSL kurulumu ve yayılma süresi'}, {'id': 2411, 'title': 'DNS değişikliği sonrası kontrol'}]}},
];

List<Map<String, dynamic>> _seri() {
  const s = [14, 18, 21, 17, 25, 9, 6, 19, 23, 27, 22, 24, 11, 8, 20, 26, 29, 24, 28, 12, 7, 22, 25, 31, 27, 30, 13, 9, 26, 23];
  return [for (var i = 0; i < 30; i++) {'label': '${i + 1}', 'count': s[i], 'visitors': s[i] * 6 + 20}];
}

final _raporlar = {
  'summary': {'today': 23, 'week': 141, 'month': 612, 'total': 3482, 'avg_rating': 4.8, 'rated': 1290, 'visitors_month': 4860, 'visitors_today': 148},
  'series': _seri(),
  'statusRows': {'open': 4, 'pending': 2, 'closed': 3471},
  'byHour': [for (var h = 0; h < 24; h++) {'h': h, 'count': const [1, 0, 0, 0, 0, 1, 2, 4, 9, 14, 18, 21, 17, 15, 22, 24, 19, 16, 12, 8, 6, 4, 3, 2][h]}],
  'byDay': [for (final g in const [('Pzt', 112), ('Sal', 128), ('Çar', 121), ('Per', 117), ('Cum', 96), ('Cmt', 24), ('Paz', 14)]) {'label': g.$1, 'count': g.$2}],
  'agents': [
    {'name': 'Elif Kaya', 'avatar': null, 'chats': 212, 'avg': 4.9, 'resp': 41},
    {'name': 'Murat Aydın', 'avatar': null, 'chats': 187, 'avg': 4.8, 'resp': 55},
    {'name': 'Selin Koç', 'avatar': null, 'chats': 143, 'avg': 4.7, 'resp': 62},
    {'name': 'Burak Çelik', 'avatar': null, 'chats': 70, 'avg': 4.6, 'resp': 90},
  ],
  'sla': {'target_min': 2, 'within_pct': 94.5, 'answered': 598, 'avg_response': 48, 'max_response': 420, 'breached': 33, 'avg_resolution': 540, 'waiting_now': 2},
};

const _raporDetay = {
  'firstResponse': {'human': '48 sn'}, 'resolution': {'human': '9 dk'}, 'conversion': {'rate': 31, 'converted': 190, 'total': 612},
  'engagement': {'msg_per_conv': 8.4, 'pv_per_session': 5.2}, 'sentiment': {'positive': 68, 'neutral': 25, 'negative': 7},
  'abandoned': [{'url': 'https://bogahost.com/sepet', 'count': 41}, {'url': 'https://bogahost.com/odeme', 'count': 17}, {'url': 'https://bogahost.com/alan-adi', 'count': 9}],
};
