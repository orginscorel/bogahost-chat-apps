import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/parcalar.dart';
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

/// Ziyaretçi detayı: oturum/cihaz bilgisi, CRM (durum, puan, atama, takip), notlar, etiketler, sayfalar,
/// olaylar, sohbetler, yasaklar; davet / sohbet başlat / ekran izle (onaylı ya da onaysız).
class ZiyaretciDetayEkrani extends StatefulWidget {
  const ZiyaretciDetayEkrani({super.key, required this.oturumId, this.ad});
  final int oturumId;
  final String? ad;

  /// Geniş ekranda sağdan kayan panel, telefonda tam sayfa.
  static Future<void> ac(BuildContext context, int oturumId, {String? ad}) =>
      yanPanelAc(context, ZiyaretciDetayEkrani(oturumId: oturumId, ad: ad), genislik: 620);

  @override
  State<ZiyaretciDetayEkrani> createState() => _ZiyaretciDetayEkraniState();
}

class _ZiyaretciDetayEkraniState extends State<ZiyaretciDetayEkrani> {
  int _anahtar = 0;
  void _yenile() => setState(() => _anahtar++);

  Future<void> _crm(Map<String, dynamic> v) async {
    final z = harita(v['visitor']);
    final durumlar = harita(v['lead_statuses']);
    final temsilciler = haritalar(v['agents']);
    String? durum = metinYa(z['lead_status']);
    int? atanan = tamsayiYa(z['assigned_to']);
    DateTime? takip = tarihOku(z['follow_up_at']);
    final puan = TextEditingController(text: z['lead_score'] == null ? '' : '${tamsayi(z['lead_score'])}');
    await formDiyalog(
      context,
      'Müşteri adayı',
      alanlar: [
        StatefulBuilder(
          builder: (c, set) => Column(
            children: [
              secim<String?>('Durum', durum, [(null, 'Belirsiz'), for (final e in durumlar.entries) (e.key, metin(e.value))], (x) => set(() => durum = x)),
              secim<int?>('Atanan personel', atanan, [
                (null, 'Atanmadı'),
                for (final a in temsilciler) (tamsayi(a['id']), metin(a['display_name'] ?? a['name'])),
              ], (x) => set(() => atanan = x)),
              alan('Puan (0–100)', puan, tur: TextInputType.number),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      takip == null
                          ? 'Takip tarihi yok'
                          : 'Takip: ${takip!.day.toString().padLeft(2, '0')}.${takip!.month.toString().padLeft(2, '0')}.${takip!.year}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: c,
                        firstDate: DateTime.now().subtract(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDate: takip ?? DateTime.now(),
                      );
                      if (d != null) set(() => takip = d);
                    },
                    child: const Text('Seç'),
                  ),
                  if (takip != null) IconButton(icon: const Icon(Simgeler.close, size: 16), onPressed: () => set(() => takip = null)),
                ],
              ),
            ],
          ),
        ),
      ],
      kaydetF: () => Panel.musteriAdayi(tamsayi(z['id']), {
        'lead_status': durum ?? '',
        'lead_score': puan.text.trim().isEmpty ? null : int.tryParse(puan.text.trim()),
        'assigned_to': atanan,
        'follow_up_at': takip == null ? '' : '${takip!.year}-${takip!.month.toString().padLeft(2, '0')}-${takip!.day.toString().padLeft(2, '0')}',
      }),
    );
    _yenile();
  }

  Future<void> _ekran(Map<String, dynamic> v, String kip) async {
    final s = harita(v['session']);
    final ad = metin(harita(v['visitor'])['name'], widget.ad ?? 'Ziyaretçi #${widget.oturumId}');
    if (kip == 'direct' &&
        !await onayla(context, 'Onaysız ekran izleme', mesaj: 'Ziyaretçiye izin sorulmaz; denetim kaydına yazılır. Devam edilsin mi?', evet: 'İzle')) {
      return;
    }
    if (!mounted) return;
    await EkranIzleEkrani.ac(context, oturumId: widget.oturumId, ad: ad, kip: kip, sohbetId: tamsayiYa(v['open_conversation_id']), url: metinYa(s['url']));
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      key: ValueKey(_anahtar),
      baslik: widget.ad ?? 'Ziyaretçi',
      yukle: () => Panel.ziyaretci(widget.oturumId),
      govde: (context, v, yenile) {
        final s = harita(v['session']);
        final z = v['visitor'] is Map ? harita(v['visitor']) : null;
        final ekran = harita(v['screen']);
        final acikSohbet = tamsayiYa(v['open_conversation_id']);
        final ad = metin(z?['name'], metin(s['title'], 'Ziyaretçi #${widget.oturumId}'));
        final durumlar = harita(v['lead_statuses']);
        final cevrimici = mantik(s['is_online']);
        final yasaklar = haritalar(v['bans']);
        return ListView(
          children: [
            Kutu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          Avatar(ad, boyut: 52, tohum: metin(z?['email'], ad)),
                          Positioned(right: 0, bottom: 0, child: Nokta(cevrimici ? Marka.zumrut : const Color(0xFF94A3B8), boyut: 13, halka: r.kart)),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s['country'] != null ? '${bayrak(metin(s['country']))} ' : ''}$ad', style: gosterim(17, renk: r.metin)),
                            if (metinYa(z?['email']) != null) Text(metin(z?['email']), style: TextStyle(color: r.soluk, fontSize: 13)),
                            if (metinYa(z?['phone']) != null) Text(metin(z?['phone']), style: TextStyle(color: r.soluk, fontSize: 13)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                Rozet(
                                  cevrimici ? (mantik(s['is_chatting']) ? 'Sohbette' : 'Çevrimiçi') : 'Çevrimdışı',
                                  renk: cevrimici ? (mantik(s['is_chatting']) ? Marka.mor : Marka.zumrut) : const Color(0xFF94A3B8),
                                ),
                                if (z != null && metinYa(z['lead_status']) != null)
                                  Rozet(metin(durumlar[metin(z['lead_status'])], metin(z['lead_status'])), renk: Marka.mavi, ikon: Simgeler.target),
                                if (z != null && z['lead_score'] != null) Rozet('Puan ${tamsayi(z['lead_score'])}', renk: Marka.kehribar, ikon: Simgeler.gauge),
                                if (z != null && z['whmcs_client_id'] != null)
                                  Rozet('WHMCS #${z['whmcs_client_id']}', renk: Marka.lavanta, ikon: Simgeler.idBadge),
                                if (yasaklar.isNotEmpty) const Rozet('Yasaklı', renk: Marka.gul, ikon: Simgeler.prohibit),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (acikSohbet != null)
                        FilledButton.icon(
                          onPressed: () {
                            sohbetIstegi.value = acikSohbet;
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Simgeler.forum, size: 17),
                          label: const Text('Sohbete git'),
                        )
                      else if (cevrimici && Uyg.yetki('chats.reply')) ...[
                        FilledButton.icon(
                          onPressed: () async {
                            final m = await metinSor(context, 'Sohbete davet et', ilk: 'Merhaba! Yardımcı olabilir miyim?', tamam: 'Davet gönder');
                            if (m == null) return;
                            final x = await islem(() => Depo.davetEt(widget.oturumId, mesaj: m.trim().isEmpty ? null : m.trim()), tamam: 'Davet gönderildi');
                            if (x != null && x['conversation_id'] != null && context.mounted) {
                              sohbetIstegi.value = tamsayi(x['conversation_id']);
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Simgeler.wavingHand, size: 17),
                          label: const Text('Davet et'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            final m = await metinSor(context, 'Sohbet başlat', ilk: 'Merhaba, ben ${Uyg.ad}. Size nasıl yardımcı olabilirim?', tamam: 'Başlat');
                            if (m == null) return;
                            final x = await islem(
                              () => Depo.sohbetBaslat(widget.oturumId, mesaj: m.trim().isEmpty ? null : m.trim()),
                              tamam: 'Sohbet başlatıldı',
                            );
                            if (x != null && x['conversation_id'] != null && context.mounted) {
                              sohbetIstegi.value = tamsayi(x['conversation_id']);
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Simgeler.forum, size: 17),
                          label: const Text('Sohbet başlat'),
                        ),
                      ],
                      if (cevrimici && mantik(ekran['consent']))
                        OutlinedButton.icon(
                          onPressed: () => _ekran(v, 'consent'),
                          icon: const Icon(Simgeler.monitor, size: 17),
                          label: const Text('Ekranı izle (onaylı)'),
                        ),
                      if (cevrimici && mantik(ekran['direct']))
                        OutlinedButton.icon(
                          onPressed: () => _ekran(v, 'direct'),
                          icon: const Icon(Simgeler.desktop, size: 17),
                          label: const Text('Onaysız izle'),
                        ),
                      if (Uyg.yetki('bans.manage'))
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Marka.gul),
                          onPressed: () async {
                            if (await yasakEkleDiyalog(context, tur: 'ip', deger: metin(s['ip']), not: 'Ziyaretçi #${z?['id'] ?? widget.oturumId}')) yenile();
                          },
                          icon: const Icon(Simgeler.prohibit, size: 17),
                          label: const Text('Yasakla'),
                        ),
                    ],
                  ),
                  if (metinYa(s['sneak_peek']) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const Icon(Simgeler.edit, size: 14, color: Marka.mor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Yazıyor: ${metin(s['sneak_peek'])}',
                              style: const TextStyle(color: Marka.mor, fontStyle: FontStyle.italic, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (z != null) ...[
              Baslik(
                'Müşteri adayı (CRM)',
                sag: TextButton.icon(onPressed: () => _crm(v), icon: const Icon(Simgeler.edit, size: 16), label: const Text('Düzenle')),
              ),
              Kutu(
                child: Column(
                  children: [
                    bilgi(context, 'Durum', durumlar[metin(z['lead_status'])]?.toString() ?? 'Belirsiz'),
                    bilgi(context, 'Puan', z['lead_score'] == null ? '—' : '${tamsayi(z['lead_score'])} / 100'),
                    bilgi(
                      context,
                      'Atanan',
                      metin(
                        z['assigned_name'],
                        haritalar(v['agents'])
                                .where((a) => tamsayi(a['id']) == tamsayiYa(z['assigned_to']))
                                .map((a) => metin(a['display_name'] ?? a['name']))
                                .firstOrNull ??
                            'Atanmadı',
                      ),
                    ),
                    bilgi(context, 'Takip', z['follow_up_at'] == null ? '—' : tamZaman(tarihOku(z['follow_up_at']))),
                    bilgi(context, 'Ziyaret / sohbet', '${tamsayi(z['visits'])} / ${tamsayi(z['chats'])}'),
                    bilgi(context, 'İlk / son görülme', '${metin(z['first_seen'])} · ${metin(z['last_seen'])}'),
                  ],
                ),
              ),
              Baslik(
                'Etiketler',
                sag: TextButton.icon(
                  onPressed: () async {
                    final t = await metinSor(context, 'Etiket ekle', tamam: 'Ekle');
                    if (t == null || t.trim().isEmpty) return;
                    if (await kaydet(() => Panel.etiketEkle(tamsayi(z['id']), t.trim()))) yenile();
                  },
                  icon: const Icon(Simgeler.add, size: 16),
                  label: const Text('Ekle'),
                ),
              ),
              Kutu(
                child: haritalar(v['tags']).isEmpty
                    ? Text('Etiket yok.', style: TextStyle(color: r.silik, fontSize: 12.5))
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in haritalar(v['tags']))
                            InputChip(
                              label: Text(metin(t['name'])),
                              avatar: const Icon(Simgeler.tag, size: 14),
                              onDeleted: () async {
                                if (await kaydet(() => Panel.etiketSil(tamsayi(z['id']), tamsayi(t['id'])))) yenile();
                              },
                            ),
                        ],
                      ),
              ),
              Baslik(
                'Notlar',
                sag: TextButton.icon(
                  onPressed: () async {
                    final n = await metinSor(context, 'Not ekle', tamam: 'Kaydet');
                    if (n == null || n.trim().isEmpty) return;
                    if (await kaydet(() => Panel.notEkle(tamsayi(z['id']), n.trim()))) yenile();
                  },
                  icon: const Icon(Simgeler.notePencil, size: 16),
                  label: const Text('Not ekle'),
                ),
              ),
              if (haritalar(v['notes']).isEmpty)
                Kutu(
                  child: Text('Not yok.', style: TextStyle(color: r.silik, fontSize: 12.5)),
                ),
              for (final n in haritalar(v['notes']))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Kutu(
                    padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(metin(n['body']), style: TextStyle(color: r.metin, fontSize: 13.5, height: 1.4)),
                              const SizedBox(height: 4),
                              Text('${metin(n['user'], 'Sistem')} · ${metin(n['at'])}', style: TextStyle(color: r.silik, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Simgeler.deleteOutline, size: 18),
                          onPressed: () async {
                            if (await onayla(context, 'Not silinsin mi?', evet: 'Sil', tehlikeli: true)) {
                              if (await kaydet(() => Panel.notSil(tamsayi(n['id'])))) yenile();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            const Baslik('Oturum ve cihaz'),
            Kutu(
              child: Column(
                children: [
                  bilgi(context, 'IP', metinYa(s['ip']), kopyalanir: true),
                  bilgi(context, 'Konum', [metinYa(s['city']), metinYa(s['country'])].whereType<String>().join(', ')),
                  bilgi(context, 'Cihaz', [metinYa(s['device']), metinYa(s['os']), metinYa(s['browser'])].whereType<String>().join(' · ')),
                  bilgi(context, 'Ekran / dil', [metinYa(s['screen']), metinYa(s['language']), metinYa(s['timezone'])].whereType<String>().join(' · ')),
                  bilgi(context, 'Şu anki sayfa', metinYa(s['url']), onTap: s['url'] == null ? null : () => disAc(metin(s['url']))),
                  bilgi(context, 'Kaynak', metinYa(s['referrer'])),
                  if (s['utm'] is Map && (s['utm'] as Map).isNotEmpty)
                    bilgi(
                      context,
                      'UTM',
                      (s['utm'] as Map).entries.where((e) => e.value != null && '${e.value}'.isNotEmpty).map((e) => '${e.key}=${e.value}').join(' '),
                    ),
                  bilgi(context, 'Oturum', '${metin(s['started'])} · ${tamsayi(s['pageviews'])} sayfa · son ${metin(s['last_activity'])}'),
                  bilgi(context, 'Tarayıcı kimliği', metinYa(s['user_agent'])),
                ],
              ),
            ),
            if (yasaklar.isNotEmpty) ...[
              const Baslik('Etkin yasaklar'),
              for (final b in yasaklar)
                Kutu(
                  child: Row(
                    children: [
                      const Icon(Simgeler.prohibit, color: Marka.gul, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${metin(b['type'])}: ${metin(b['value'])}${metinYa(b['reason']) != null ? ' · ${metin(b['reason'])}' : ''}${metinYa(b['expires']) != null ? ' · bitiş ${metin(b['expires'])}' : ' · kalıcı'}',
                          style: TextStyle(color: r.metin, fontSize: 12.5),
                        ),
                      ),
                      if (Uyg.yetki('bans.manage'))
                        TextButton(
                          onPressed: () async {
                            if (await kaydet(() => Panel.yasakSil(tamsayi(b['id'])))) yenile();
                          },
                          child: const Text('Kaldır'),
                        ),
                    ],
                  ),
                ),
            ],
            if (haritalar(v['conversations']).isNotEmpty) ...[
              const Baslik('Sohbetler'),
              for (final c in haritalar(v['conversations']))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Kutu(
                    padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                    onTap: () {
                      sohbetIstegi.value = tamsayi(c['id']);
                      Navigator.of(context).pop();
                    },
                    child: Row(
                      children: [
                        Rozet(switch (metin(c['status'])) {
                          'open' => 'Açık',
                          'pending' => 'Bekliyor',
                          'closed' => 'Kapalı',
                          'offline' => 'Çevrimdışı',
                          final x => x,
                        }, renk: durumRengi(metin(c['status']))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '#${tamsayi(c['id'])} · ${metin(c['agent'], 'Atanmadı')} · ${metin(c['at'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: r.metin, fontSize: 13),
                          ),
                        ),
                        if (c['rating'] != null)
                          Text(
                            '★ ${c['rating']}',
                            style: const TextStyle(color: Marka.kehribar, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        Icon(Simgeler.chevronRight, color: r.silik, size: 18),
                      ],
                    ),
                  ),
                ),
            ],
            const Baslik('Gezinti'),
            Kutu(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: haritalar(v['pageviews']).isEmpty
                  ? Text('Sayfa kaydı yok.', style: TextStyle(color: r.silik, fontSize: 12.5))
                  : Column(
                      children: [
                        for (final p in haritalar(v['pageviews']))
                          InkWell(
                            onTap: () => disAc(metin(p['url'])),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 58,
                                    child: Text(metin(p['at']), style: TextStyle(color: r.silik, fontSize: 11.5)),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          metin(p['title'], kisaUrl(metin(p['url']))),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: r.metin, fontSize: 13),
                                        ),
                                        Text(
                                          kisaUrl(metin(p['url']), en: 70),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: r.silik, fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (p['duration'] != null) Text('${tamsayi(p['duration'])} sn', style: TextStyle(color: r.silik, fontSize: 11.5)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            if (haritalar(v['events']).isNotEmpty) ...[
              const Baslik('Olaylar'),
              Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: [
                    for (final e in haritalar(v['events']))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              child: Text(metin(e['at']), style: TextStyle(color: r.silik, fontSize: 11.5)),
                            ),
                            Rozet(metin(e['name']), renk: Marka.mavi),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e['data'] == null ? '' : '${e['data']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: r.soluk, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
