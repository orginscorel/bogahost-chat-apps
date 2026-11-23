import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/json.dart';
import '../veri/panel.dart';
import 'ayar/ortak.dart';
import 'ayar/yasaklar.dart';
import 'ekran_izle.dart';
import 'kabuk.dart';
import 'ziyaretci_detay.dart';

/// Sohbet ekranının sağ bloğu: web panelindeki "Ziyaretçi bilgileri" paneliyle aynı kapsam —
/// kimlik, iletişim, WHMCS, ağ (IP · port · parmak izi), cihaz, konum + yerel saat, kaynak/UTM,
/// atama, yasaklama / yasak kaldırma, gezinti geçmişi, olay günlüğü, geçmiş görüşmeler.
class SohbetZiyaretciPaneli extends StatefulWidget {
  const SohbetZiyaretciPaneli({super.key, required this.sohbetId, this.kapat});
  final int sohbetId;
  final VoidCallback? kapat;
  @override
  State<SohbetZiyaretciPaneli> createState() => _SohbetZiyaretciPaneliState();
}

class _SohbetZiyaretciPaneliState extends State<SohbetZiyaretciPaneli> {
  late Future<Map<String, dynamic>> _f = Panel.sohbetZiyaretci(widget.sohbetId);
  void _yenile() => setState(() => _f = Panel.sohbetZiyaretci(widget.sohbetId));

  @override
  void didUpdateWidget(SohbetZiyaretciPaneli o) {
    super.didUpdateWidget(o);
    if (o.sohbetId != widget.sohbetId) _yenile();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 6, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Ziyaretçi bilgileri', style: gosterim(16, renk: r.metin)),
                ),
                IconButton(tooltip: 'Yenile', onPressed: _yenile, icon: const Icon(Simgeler.refresh, size: 20)),
                if (widget.kapat != null) IconButton(tooltip: 'Kapat', onPressed: widget.kapat, icon: const Icon(Simgeler.close, size: 20)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _f,
              builder: (context, s) {
                if (s.hasError) return Durum.hata(hataMetni(s.error!), tekrar: _yenile);
                if (!s.hasData) return const Durum.yukleniyor();
                return _icerik(context, s.data!, r);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _icerik(BuildContext context, Map<String, dynamic> v, Renkler r) {
    final z = harita(v['visitor']);
    final n = harita(v['network']);
    final si = v['session_info'] is Map ? harita(v['session_info']) : null;
    final crm = harita(v['crm']);
    final can = harita(v['can']);
    final yasaklar = haritalar(v['bans']);
    final banSayisi = tamsayi(v['ban_active']);
    final temsilciler = haritalar(v['agents']);
    final sayfalar = haritalar(v['pageviews']);
    final olaylar = haritalar(v['events']);
    final gecmis = haritalar(v['history']);
    final katilimcilar = haritalar(v['participants']);
    final ad = metin(z['name'], 'Ziyaretçi');
    final ulke = metinYa(z['country']) ?? metinYa(si?['country']);
    final sehir = metinYa(z['city']) ?? metinYa(si?['city']);
    final cevrimici = mantik(si?['is_online']);
    final sohbette = mantik(si?['is_chatting']);
    final oturumId = tamsayiYa(v['session_id']);
    final ziyaretciId = tamsayiYa(v['visitor_id']);
    final whmcs = z['whmcs_id'];
    final simdikiUrl = metinYa(v['current_url']) ?? metinYa(n['current_url']);
    final utm = n['utm'] is Map
        ? (n['utm'] as Map).entries.where((e) => e.value != null && '${e.value}'.isNotEmpty).map((e) => '${e.key}=${e.value}').join(' ')
        : '';
    final yasakYetkisi = mantik(can['ban']) && Uyg.yetki('bans.manage');

    Widget bolum(String ad, {Widget? sag}) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ad.toUpperCase(),
              style: TextStyle(color: r.silik, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .7),
            ),
          ),
          ?sag,
        ],
      ),
    );

    Widget hap(String s, {IconData? ikon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: r.zemin,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: r.kenar),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[Icon(ikon, size: 13, color: r.soluk), const SizedBox(width: 4)],
          Text(
            s,
            style: TextStyle(color: r.metin, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // ---- Kimlik başlığı
        Center(
          child: Column(
            children: [
              Stack(
                children: [
                  Avatar(ad, boyut: 64, tohum: metin(z['email'], ad)),
                  Positioned(right: 1, bottom: 1, child: Nokta(cevrimici ? Marka.zumrut : const Color(0xFF94A3B8), boyut: 14, halka: r.kart)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${ulke != null ? '${bayrak(ulke)} ' : ''}$ad',
                textAlign: TextAlign.center,
                style: gosterim(17, renk: r.metin),
              ),
              if (metinYa(z['email']) != null)
                SelectableText(
                  metin(z['email']),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: r.soluk, fontSize: 13),
                ),
              if (metinYa(z['phone']) != null)
                SelectableText(
                  metin(z['phone']),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: r.soluk, fontSize: 13),
                ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  Rozet(
                    cevrimici ? (sohbette ? 'Sohbette' : 'Çevrimiçi') : 'Çevrimdışı',
                    renk: cevrimici ? (sohbette ? Marka.mor : Marka.zumrut) : const Color(0xFF94A3B8),
                  ),
                  hap('${tamsayi(z['visits'])} ziyaret', ikon: Simgeler.history),
                  hap('${tamsayi(z['chats'])} sohbet', ikon: Simgeler.forum),
                  if (whmcs != null) Rozet('WHMCS #$whmcs', renk: Marka.lavanta, ikon: Simgeler.idBadge),
                  if (metinYa(crm['lead_status']) != null) Rozet(_adayAdi(metin(crm['lead_status'])), renk: Marka.mavi, ikon: Simgeler.target),
                  if (banSayisi > 0) Rozet('Yasaklı · $banSayisi kayıt', renk: Marka.gul, ikon: Simgeler.prohibit),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ---- Yasaklama
        if (yasakYetkisi)
          banSayisi == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Marka.gul, foregroundColor: Colors.white),
                      onPressed: () async {
                        final ok = await sohbetYasaklaDiyalog(
                          context,
                          widget.sohbetId,
                          ip: metinYa(n['ip']),
                          parmakIzi: metinYa(n['fingerprint']),
                          eposta: metinYa(z['email']),
                        );
                        if (ok) _yenile();
                      },
                      icon: const Icon(Simgeler.shield, size: 17),
                      label: const Text('Ziyaretçiyi yasakla'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'IP · ağ bloğu · cihaz parmak izi · kimlik · e-posta — VPN/proxy atlatamaz',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: r.silik, fontSize: 11),
                      ),
                    ),
                  ],
                )
              : Kutu(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Simgeler.prohibit, color: Marka.gul, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu ziyaretçi yasaklı ($banSayisi kayıt)',
                              style: const TextStyle(color: Marka.gul, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final b in yasaklar)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${YasaklarEkraniYardim.turAdi(metin(b['type']))}: ${metin(b['value'])}'
                                  '${metinYa(b['reason']) != null ? ' · ${metin(b['reason'])}' : ''}'
                                  '${metinYa(b['expires']) != null ? ' · bitiş ${metin(b['expires'])}' : ' · kalıcı'}',
                                  style: TextStyle(color: r.metin, fontSize: 12),
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                onPressed: () async {
                                  if (await kaydet(() => Panel.yasakSil(tamsayi(b['id'])), tamam: 'Yasak kaldırıldı')) _yenile();
                                },
                                child: const Text('Kaldır'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Marka.zumrut, foregroundColor: Colors.white),
                        onPressed: () async {
                          final onay = await onayla(
                            context,
                            'Tüm yasaklar kaldırılsın mı?',
                            mesaj: 'IP, ağ bloğu, cihaz, kimlik ve e-posta yasaklarının hepsi kaldırılır.',
                            evet: 'Kaldır',
                          );
                          if (!onay) return;
                          final x = await islem(() => Depo.sohbetYasakKaldir(widget.sohbetId), tamam: 'Yasaklar kaldırıldı');
                          if (x != null) _yenile();
                        },
                        icon: const Icon(Simgeler.check, size: 17),
                        label: const Text('Tüm yasakları kaldır'),
                      ),
                    ],
                  ),
                ),
        // ---- Hızlı eylemler
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (oturumId != null)
              OutlinedButton.icon(
                onPressed: () => ZiyaretciDetayEkrani.ac(context, oturumId, ad: ad),
                icon: const Icon(Simgeler.idBadge, size: 16),
                label: const Text('CRM detayı'),
              ),
            if (oturumId != null && cevrimici && (mantik(can['screen_consent']) || mantik(can['screen_direct'])))
              OutlinedButton.icon(
                onPressed: () => EkranIzleEkrani.sec(context, oturumId: oturumId, ad: ad, sohbetId: widget.sohbetId, url: simdikiUrl),
                icon: const Icon(Simgeler.monitor, size: 16),
                label: const Text('Ekranı izle'),
              ),
            if (whmcs != null)
              OutlinedButton.icon(
                onPressed: () => disAc('https://bogahost.com/smeownerbogap/clientssummary.php?userid=$whmcs'),
                icon: const Icon(Simgeler.openInNew, size: 16),
                label: const Text('WHMCS müşterisi'),
              ),
          ],
        ),
        // ---- Atama
        if (ziyaretciId != null && temsilciler.isNotEmpty) ...[
          bolum('Atama'),
          DropdownButtonFormField<int?>(
            initialValue: tamsayiYa(crm['assigned_to']),
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('— Atanmadı —')),
              for (final a in temsilciler)
                DropdownMenuItem<int?>(
                  value: tamsayi(a['id']),
                  child: Text(metin(a['name']), overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (x) async {
              final ok = await kaydet(
                () => Panel.musteriAdayi(ziyaretciId, {
                  'lead_status': metinYa(crm['lead_status']) ?? '',
                  'lead_score': crm['lead_score'],
                  'assigned_to': x,
                  'follow_up_at': metinYa(crm['follow_up_at']) ?? '',
                }),
                tamam: x == null ? 'Atama kaldırıldı' : 'Atandı',
              );
              if (ok) _yenile();
            },
          ),
        ],
        // ---- Şu an
        if (simdikiUrl != null || metinYa(si?['sneak_peek']) != null) ...[
          bolum('Şu an'),
          if (simdikiUrl != null)
            InkWell(
              onTap: () => disAc(simdikiUrl),
              child: Text(
                metinYa(si?['current_title']) != null ? '${metin(si?['current_title'])}\n$simdikiUrl' : simdikiUrl,
                style: const TextStyle(color: Marka.mavi, fontSize: 12.5, height: 1.35),
              ),
            ),
          if (metinYa(si?['sneak_peek']) != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Simgeler.edit, size: 14, color: Marka.mor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Yazıyor: ${metin(si?['sneak_peek'])}',
                      style: const TextStyle(color: Marka.mor, fontStyle: FontStyle.italic, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
        // ---- İletişim & kimlik
        bolum('İletişim & kimlik'),
        bilgi(context, 'Ad Soyad', ad),
        bilgi(context, 'E-posta', metinYa(z['email']), kopyalanir: true),
        bilgi(context, 'Telefon', metinYa(z['phone']), kopyalanir: true),
        bilgi(context, 'WHMCS ID', whmcs?.toString(), kopyalanir: true),
        bilgi(context, 'İlk ziyaret', metinYa(z['first_seen'])),
        bilgi(context, 'Ziyaretçi no', ziyaretciId?.toString()),
        bilgi(context, 'Kalıcı kimlik', metinYa(n['visitor_uid']), kopyalanir: true),
        bilgi(context, 'Sohbet dili', metinYa(v['visitor_lang'])),
        // ---- Ağ & cihaz
        bolum('Ağ & cihaz'),
        bilgi(context, 'IP', metinYa(n['ip']), kopyalanir: true),
        bilgi(context, 'Port', metinYa(n['port'])),
        bilgi(context, 'İşletim sistemi', metinYa(n['os'])),
        bilgi(context, 'Tarayıcı', metinYa(n['browser'])),
        bilgi(context, 'Cihaz', metinYa(n['device'])),
        bilgi(context, 'Ekran', metinYa(n['screen'])),
        bilgi(context, 'Dil', metinYa(n['language'])),
        bilgi(
          context,
          'Saat dilimi',
          [metinYa(n['timezone']), if (metinYa(si?['local_time']) != null) 'yerel saat ${metin(si?['local_time'])}'].whereType<String>().join(' · '),
        ),
        bilgi(context, 'Parmak izi', metinYa(n['fingerprint']), kopyalanir: true),
        bilgi(context, 'Tarayıcı kimliği', metinYa(n['user_agent']), kopyalanir: true),
        // ---- Konum
        if (ulke != null || sehir != null) ...[
          bolum('Konum'),
          bilgi(context, 'Ülke / şehir', '${ulke != null ? '${bayrak(ulke)} ' : ''}${[sehir, ulke].whereType<String>().join(', ')}'),
        ],
        // ---- Oturum
        if (si != null) ...[
          bolum('Oturum'),
          bilgi(context, 'Başlangıç', metinYa(si['started'])),
          bilgi(context, 'Son hareket', metinYa(si['last_activity'])),
          bilgi(context, 'Sayfa sayısı', si['pageviews'] == null ? null : '${tamsayi(si['pageviews'])}'),
          bilgi(context, 'Oturum no', '${tamsayi(si['id'])}'),
        ],
        // ---- Kaynak
        if (metinYa(n['referrer']) != null || utm.isNotEmpty) ...[
          bolum('Kaynak'),
          bilgi(context, 'Yönlendiren', metinYa(n['referrer']), kopyalanir: true),
          bilgi(context, 'UTM', utm.isEmpty ? null : utm, kopyalanir: true),
        ],
        // ---- Sohbet
        bolum('Bu sohbet'),
        bilgi(context, 'Sohbet', '#${widget.sohbetId} · ${_durumAdi(metin(v['status']))}'),
        bilgi(context, 'Departman', metinYa(v['department'])),
        bilgi(context, 'Temsilci', metinYa(v['agent'])),
        bilgi(
          context,
          'Katılımcılar',
          katilimcilar.isEmpty ? null : katilimcilar.map((k) => metin(k['name'] ?? k['display_name'] ?? k['user'])).where((x) => x.isNotEmpty).join(', '),
        ),
        if (v['rating'] != null)
          bilgi(context, 'Değerlendirme', '${'★' * tamsayi(v['rating'])}${metinYa(v['rating_comment']) != null ? ' · ${metin(v['rating_comment'])}' : ''}'),
        // ---- Gezinti
        bolum('Sayfa gezinti geçmişi (${sayfalar.length})'),
        if (sayfalar.isEmpty)
          Text('Kayıt yok.', style: TextStyle(color: r.silik, fontSize: 12.5))
        else
          for (final p in sayfalar)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                onTap: () => disAc(metin(p['url'])),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metin(p['title'], kisaUrl(metin(p['url']))),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: r.metin, fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            kisaUrl(metin(p['url']), en: 60),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: r.silik, fontSize: 11),
                          ),
                        ),
                        Text(metin(p['at']), style: TextStyle(color: r.silik, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        // ---- Olay günlüğü
        if (olaylar.isNotEmpty) ...[
          bolum('Olay günlüğü (${olaylar.length})'),
          Kutu(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              children: [
                for (final e in olaylar)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 74,
                          child: Text(metin(e['at']), style: TextStyle(color: r.silik, fontSize: 11)),
                        ),
                        Rozet(metin(e['name']), renk: Marka.mavi),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e['data'] == null ? '' : '${e['data']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: r.soluk, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        // ---- Geçmiş görüşmeler
        if (gecmis.isNotEmpty) ...[
          bolum('Geçmiş görüşmeler (${gecmis.length})'),
          for (final h in gecmis)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Kutu(
                padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
                onTap: () => sohbetIstegi.value = tamsayi(h['id']),
                child: Row(
                  children: [
                    Rozet(_durumAdi(metin(h['status'])), renk: durumRengi(metin(h['status']))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${tamsayi(h['id'])} · ${metin(h['date'])}',
                            style: TextStyle(color: r.metin, fontSize: 12.5, fontWeight: FontWeight.w500),
                          ),
                          if (metinYa(h['preview']) != null)
                            Text(
                              metin(h['preview']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: r.silik, fontSize: 11.5),
                            ),
                        ],
                      ),
                    ),
                    if (h['rating'] != null)
                      Text(
                        '★ ${h['rating']}',
                        style: const TextStyle(color: Marka.kehribar, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    Icon(Simgeler.chevronRight, color: r.silik, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  static String _adayAdi(String s) => switch (s) {
    'new' => 'Yeni',
    'lead' => 'Potansiyel',
    'qualified' => 'Nitelikli',
    'customer' => 'Müşteri',
    'lost' => 'Kayıp',
    final x => x,
  };

  static String _durumAdi(String s) => switch (s) {
    'open' => 'Açık',
    'pending' => 'Bekliyor',
    'closed' => 'Kapalı',
    'offline' => 'Çevrimdışı',
    'missed' => 'Kaçan',
    final x => x,
  };
}

/// Web paneliyle aynı yasak diyaloğu: kapsam onay kutuları (IP, IP bloğu /24 /16, cihaz parmak izi,
/// ziyaretçi kimliği, e-posta, tam yasak), ziyaretçiye gösterilen sebep (zorunlu), süre.
Future<bool> sohbetYasaklaDiyalog(BuildContext context, int sohbetId, {String? ip, String? parmakIzi, String? eposta}) async {
  final kapsam = <String>{'ip', 'fingerprint'};
  var altAg = '24', sure = 'perm';
  final neden = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (c, set) {
        final r = c.r;
        Widget kutu(String k, String baslik, String? alt, {Widget? ek}) => CheckboxListTile(
          value: kapsam.contains(k),
          onChanged: (v) => set(() => v == true ? kapsam.add(k) : kapsam.remove(k)),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: Marka.gul,
          title: Text(baslik, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          subtitle: alt == null && ek == null
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (alt != null) Text(alt, style: TextStyle(color: r.silik, fontSize: 11.5)),
                    ?ek,
                  ],
                ),
        );
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Simgeler.shield, color: Marka.gul, size: 22),
              SizedBox(width: 8),
              Text('Ziyaretçiyi yasakla'),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cihaz parmak izi IP\'den bağımsızdır: VPN/proxy ile IP değişse bile kişi engelli kalır.',
                    style: TextStyle(color: r.silik, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  kutu('ip', 'IP adresi', ip ?? '—'),
                  kutu(
                    'ip_range',
                    'IP bloğu (ağ)',
                    'tüm ağ aralığı (VPN havuzu)',
                    ek: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: const ButtonStyle(visualDensity: VisualDensity.compact),
                        segments: const [
                          ButtonSegment(value: '24', label: Text('/24 · 256 IP')),
                          ButtonSegment(value: '16', label: Text('/16 · 65k IP')),
                        ],
                        selected: {altAg},
                        onSelectionChanged: (s) => set(() => altAg = s.first),
                      ),
                    ),
                  ),
                  kutu('fingerprint', 'Cihaz parmak izi', parmakIzi ?? '(yakalanmadı)'),
                  kutu('visitor', 'Ziyaretçi kimliği', 'tarayıcı çerezi / kalıcı uid'),
                  kutu('email', 'E-posta', eposta ?? '(yok)'),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Marka.gul),
                    onPressed: () => set(() => kapsam.addAll(['ip', 'ip_range', 'fingerprint', 'visitor', 'email'])),
                    icon: const Icon(Simgeler.gppBad, size: 16),
                    label: const Text('Tam yasak (hepsini seç)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: neden,
                    maxLines: 2,
                    onChanged: (_) => set(() {}),
                    decoration: const InputDecoration(labelText: 'Yasak sebebi (ziyaretçiye gösterilir) *', hintText: 'Örn: hakaret / spam / kötüye kullanım'),
                  ),
                  const SizedBox(height: 10),
                  secim<String>('Süre', sure, yasakSureleri, (x) => set(() => sure = x ?? 'perm')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Marka.gul, foregroundColor: Colors.white),
              onPressed: neden.text.trim().isEmpty || kapsam.isEmpty ? null : () => Navigator.pop(c, true),
              child: const Text('Yasakla'),
            ),
          ],
        );
      },
    ),
  );
  if (ok != true) return false;
  final x = await islem(
    () => Depo.sohbetYasakla(sohbetId, {'scopes': kapsam.toList(), 'reason': neden.text.trim(), 'duration': sure, 'subnet': altAg}),
    tamam: 'Ziyaretçi yasaklandı',
  );
  return x != null;
}
