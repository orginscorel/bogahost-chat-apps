// Sunucu JSON'undan tipli modeller. Alanlar panelin JSON uçlarıyla (ConversationController::list/poll/msgs vb.) birebirdir.
import 'json.dart';

class Temsilci {
  Temsilci({
    required this.id,
    required this.ad,
    required this.eposta,
    required this.rol,
    required this.rolAdi,
    required this.yetkiler,
    required this.yonetici,
    required this.musaitlik,
    this.avatar,
    this.bolum,
    this.totp = false,
  });
  final int id;
  final String ad, eposta, rol, rolAdi, musaitlik;
  final String? avatar, bolum;
  final List<String> yetkiler;
  final bool yonetici, totp;

  factory Temsilci.coz(Map<String, dynamic> m) => Temsilci(
    id: tamsayi(m['id']),
    ad: metin(m['display_name'], metin(m['name'])),
    eposta: metin(m['email']),
    rol: metin(m['role']),
    rolAdi: metin(m['role_name'], metin(m['role'])),
    yetkiler: metinler(m['permissions']),
    yonetici: mantik(m['is_admin']),
    musaitlik: metin(m['availability'], 'online'),
    avatar: metinYa(m['avatar']),
    bolum: metinYa(m['department']),
    totp: mantik(m['totp_enabled']),
  );
}

/// Sohbet listesi satırı (GET chats).
class Sohbet {
  Sohbet.coz(Map<String, dynamic> m)
    : id = tamsayi(m['id']),
      ziyaretci = metin(m['visitor'], 'Ziyaretçi'),
      eposta = metinYa(m['email']),
      bolum = metinYa(m['department']),
      temsilci = metinYa(m['agent']),
      durum = metin(m['status']),
      ulke = metinYa(m['country']),
      cevrimici = mantik(m['visitor_online']),
      puan = tamsayiYa(m['rating']),
      son = metin(m['last']),
      onizleme = metinYa(m['preview']),
      yaziyor = metinYa(m['sneak_peek']),
      okunmamis = tamsayi(m['unread']),
      sonGonderen = metin(m['last_from']),
      favori = mantik(m['favorite']),
      arsiv = mantik(m['archived']),
      kacan = mantik(m['missed']);
  final int id, okunmamis;
  final String ziyaretci, durum, son, sonGonderen;
  final String? eposta, bolum, temsilci, ulke, onizleme, yaziyor;
  final bool cevrimici, favori, arsiv, kacan;
  final int? puan;

  /// Görünür alanların imzası: liste yoklamasında değişiklik yoksa setState atlanır.
  String get imza =>
      '$id|$ziyaretci|$durum|$son|$sonGonderen|$eposta|$bolum|$temsilci|$ulke|$onizleme|$yaziyor|$cevrimici|$favori|$arsiv|$kacan|$puan|$okunmamis';

  String get durumAdi => switch (durum) {
    'open' => 'Açık',
    'pending' => 'Bekliyor',
    'offline' => 'Çevrimdışı',
    'closed' => 'Kapalı',
    _ => durum,
  };
}

class Ek {
  Ek.coz(Map<String, dynamic> m)
    : url = metin(m['url']),
      indir = metin(m['dl']),
      ad = metin(m['name'], 'dosya'),
      boyut = tamsayi(m['size']),
      gorsel = mantik(m['image']),
      ses = mantik(m['audio']),
      video = mantik(m['video']);
  final String url, indir, ad;
  final int boyut;
  final bool gorsel, ses, video;
}

/// Görüşme mesajı (poll → messages[]).
class Mesaj {
  Mesaj.coz(Map<String, dynamic> m)
    : id = tamsayi(m['id']),
      gonderen = metin(m['sender']),
      ad = metin(m['name']),
      tur = metin(m['type'], 'text'),
      icNot = mantik(m['internal']),
      fisilti = mantik(m['whisper']),
      govde = metinYa(m['body']),
      saat = metin(m['at']),
      okundu = mantik(m['read']),
      duzenlendi = mantik(m['edited']),
      silindi = mantik(m['deleted']),
      benim = mantik(m['own']),
      ek = m['file'] is Map ? Ek.coz(harita(m['file'])) : null;
  final int id;
  final String gonderen, ad, tur, saat;
  final String? govde;
  final bool icNot, fisilti, okundu, duzenlendi, silindi, benim;
  final Ek? ek;

  const Mesaj._({
    required this.id,
    required this.gonderen,
    required this.ad,
    required this.tur,
    required this.saat,
    required this.govde,
    required this.icNot,
    required this.fisilti,
    required this.okundu,
    required this.duzenlendi,
    required this.silindi,
    required this.benim,
    required this.ek,
  });

  /// Yalnız okundu bilgisi değişince yeni nesne (JSON'u yeniden çözmeden).
  Mesaj copyWith({bool? okundu}) => Mesaj._(
    id: id,
    gonderen: gonderen,
    ad: ad,
    tur: tur,
    saat: saat,
    govde: govde,
    icNot: icNot,
    fisilti: fisilti,
    okundu: okundu ?? this.okundu,
    duzenlendi: duzenlendi,
    silindi: silindi,
    benim: benim,
    ek: ek,
  );

  bool get ziyaretci => gonderen == 'visitor';
  bool get sistem => gonderen == 'system' || tur == 'event';
  bool get temsilci => gonderen == 'agent';
}

/// Görüşme yoklama yanıtı (poll).
class Yoklama {
  Yoklama.coz(Map<String, dynamic> m)
    : durum = metin(m['status']),
      yaziyor = metinYa(m['sneak_peek']),
      cevrimici = mantik(m['visitor_online']),
      url = metinYa(m['current_url']),
      oturumId = tamsayiYa(m['session_id']),
      iletisimTalebi = m['contact_request'],
      dil = metinYa(m['visitor_lang']),
      puan = tamsayiYa(m['rating']),
      puanYorum = metinYa(m['rating_comment']),
      okunanSon = tamsayi(m['read_upto']),
      sayfalar = haritalar(m['pageviews']).map((p) => (url: metin(p['url']), baslik: metinYa(p['title']), zaman: metin(p['at']))).toList(),
      mesajlar = haritalar(m['messages']).map(Mesaj.coz).toList();
  final String durum;
  final String? yaziyor, url, dil, puanYorum;
  final bool cevrimici;
  final int? oturumId, puan;
  final Object? iletisimTalebi;
  final int okunanSon;
  final List<({String url, String? baslik, String zaman})> sayfalar;
  final List<Mesaj> mesajlar;
}

/// Canlı ziyaretçi (GET visitors/live).
class Ziyaretci {
  Ziyaretci.coz(Map<String, dynamic> m)
    : id = tamsayi(m['id']),
      ad = metinYa(m['name']),
      eposta = metinYa(m['email']),
      url = metinYa(m['url']),
      baslik = metinYa(m['title']),
      sayfaSayisi = tamsayi(m['pageviews']),
      ulke = metinYa(m['country']),
      sehir = metinYa(m['city']),
      cihaz = metinYa(m['device']),
      tarayici = metinYa(m['browser']),
      sistem = metinYa(m['os']),
      ip = metinYa(m['ip']),
      kaynak = metinYa(m['referrer_label']) ?? metinYa(m['referrer_kind']),
      kaynakTur = metinYa(m['referrer_kind']),
      kaynakAlt = metinYa(m['referrer_line2']),
      kaynakDetay = metinYa(m['referrer_detail']) ?? metinYa(m['referrer']),
      yaziyor = metinYa(m['sneak_peek']),
      sohbette = mantik(m['is_chatting']),
      baslangic = metinYa(m['since']),
      sure = metinYa(m['last']) ?? metinYa(m['since']);
  final int id, sayfaSayisi;
  final String? ad, eposta, url, baslik, ulke, sehir, cihaz, tarayici, sistem, ip, kaynak, kaynakTur, kaynakAlt, kaynakDetay, yaziyor, sure, baslangic;
  final bool sohbette;
  bool get mobil => (cihaz ?? '').toLowerCase().contains('mobil') || (cihaz ?? '').toLowerCase() == 'phone' || (cihaz ?? '').toLowerCase() == 'tablet';
  String get gosterimAdi => ad ?? eposta ?? 'Ziyaretçi #$id';
}

/// Bildirim akışı ögesi (GET notifications/feed → items[]).
class Bildirim {
  Bildirim.coz(Map<String, dynamic> m)
    : id = metin(m['id']),
      baslik = metin(m['title']),
      govde = metin(m['body']),
      url = metin(m['url']),
      okundu = mantik(m['read']),
      yasSn = tamsayi(m['age_s']);
  final String id, baslik, govde, url;
  final bool okundu;
  final int yasSn;

  /// url: /admin/chats?open=123 → 123
  int? get sohbetId {
    final m = RegExp(r'open=(\d+)').firstMatch(url);
    return m == null ? null : int.tryParse(m[1]!);
  }

  int? get veritabaniId => int.tryParse(id);
}

/// Dahili sohbet mesajı (internal/poll → messages[]).
class IcMesaj {
  IcMesaj.coz(Map<String, dynamic> m)
    : id = tamsayi(m['id']),
      kimden = tamsayi(m['from']),
      ad = metin(m['name'], 'Personel'),
      benim = mantik(m['own']),
      govde = metinYa(m['body']),
      gorsel = metinYa(m['image']),
      dosya = m['file'] is Map ? harita(m['file']) : null,
      saat = metin(m['at']),
      sabit = mantik(m['pinned']);
  final int id, kimden;
  final String ad, saat;
  final String? govde, gorsel;
  final Map<String, dynamic>? dosya;
  final bool benim, sabit;
}

/// Ekip üyesi (GET team / internal/contacts).
class Uye {
  Uye.coz(Map<String, dynamic> m)
    : id = tamsayi(m['id']),
      ad = metin(m['name'], 'Personel'),
      avatar = metinYa(m['avatar']),
      rol = metinYa(m['role']),
      durum = metin(m['status']),
      musaitlik = metin(m['availability'], 'online'),
      cevrimici = mantik(m['online']),
      sonGorulme = tarihOku(m['last_seen']);
  final int id;
  final String ad, durum, musaitlik;
  final String? avatar, rol;
  final bool cevrimici;
  final DateTime? sonGorulme;
}

class HazirYanit {
  HazirYanit.coz(Map<String, dynamic> m) : kisayol = metin(m['shortcut']), baslik = metin(m['title']), govde = metin(m['body']);
  final String kisayol, baslik, govde;
}

/// Pano özeti (GET stats).
class Ozet {
  Ozet.coz(Map<String, dynamic> m)
    : cevrimici = tamsayi(m['online']),
      bugunZiyaretci = tamsayi(m['today_visitors']),
      aktif = tamsayi(m['active_chats']),
      bekleyen = tamsayi(m['pending']),
      bugun = tamsayi(m['today']),
      cevrimdisiMesaj = tamsayi(m['offline_msgs']),
      toplam = tamsayi(m['total']),
      ortPuan = ondalik(m['avg_rating']),
      puanlanan = tamsayi(m['rated']),
      icOkunmamis = tamsayi(m['internal_unread']),
      surum = metin(m['version']),
      acil = mantik(harita(m['emergency'])['active']),
      acilTur = metinYa(harita(m['emergency'])['type']),
      saldiri = mantik(m['attack']),
      mesaiDisi = mantik(m['after_hours']),
      musaitlik = metinYa(m['me_availability']);
  final int cevrimici, bugunZiyaretci, aktif, bekleyen, bugun, cevrimdisiMesaj, toplam, puanlanan, icOkunmamis;
  final double ortPuan;
  final String surum;
  final String? acilTur, musaitlik;
  final bool acil, saldiri, mesaiDisi;
}
