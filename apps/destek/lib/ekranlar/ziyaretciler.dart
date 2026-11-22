import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'kabuk.dart';
import 'ziyaretci_detay.dart';

/// Sitedeki canlı ziyaretçiler: sayfa, konum, cihaz; davet / sohbet başlat.
class ZiyaretcilerEkrani extends StatefulWidget {
  const ZiyaretcilerEkrani({super.key});
  @override
  State<ZiyaretcilerEkrani> createState() => _ZiyaretcilerEkraniState();
}

class _ZiyaretcilerEkraniState extends State<ZiyaretcilerEkrani> {
  List<Ziyaretci>? _liste;
  String? _hata;
  Timer? _sayac;

  @override
  void initState() {
    super.initState();
    _yukle();
    _sayac = Timer.periodic(const Duration(seconds: 5), (_) => _yukle(sessiz: true));
  }

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  Future<void> _yukle({bool sessiz = false}) async {
    try {
      final l = await Depo.canliZiyaretciler();
      if (!mounted) return;
      setState(() {
        _liste = l;
        _hata = null;
      });
    } catch (e) {
      if (mounted && !sessiz) setState(() => _hata = hataMetni(e));
    }
  }

  Future<void> _davet(Ziyaretci z) async {
    final m = await metinSor(context, 'Ziyaretçiyi davet et', ilk: 'Merhaba! Yardımcı olabilir miyim?', tamam: 'Davet gönder');
    if (m == null) return;
    final v = await islem(() => Depo.davetEt(z.id, mesaj: m.trim().isEmpty ? null : m.trim()), tamam: 'Davet gönderildi');
    if (v != null && v['conversation_id'] != null) sohbetIstegi.value = (v['conversation_id'] as num).toInt();
    _yukle();
  }

  Future<void> _baslat(Ziyaretci z) async {
    final m = await metinSor(context, 'Sohbet başlat', ilk: 'Merhaba, ben ${Uyg.ad}. Size nasıl yardımcı olabilirim?', tamam: 'Başlat');
    if (m == null) return;
    final v = await islem(() => Depo.sohbetBaslat(z.id, mesaj: m.trim().isEmpty ? null : m.trim()), tamam: 'Sohbet başlatıldı');
    if (v != null && v['conversation_id'] != null) sohbetIstegi.value = (v['conversation_id'] as num).toInt();
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    if (!Uyg.yetki('visitors.view')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ziyaretçiler')),
        body: const Yetkisiz('Ziyaretçileri görmek'),
      );
    }
    final l = _liste;
    return Scaffold(
      appBar: AppBar(
        title: Text(l == null ? 'Canlı ziyaretçiler' : 'Canlı ziyaretçiler · ${l.length}'),
        actions: [IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh))],
      ),
      body: _hata != null
          ? Durum.hata(_hata!, tekrar: _yukle)
          : l == null
          ? const Durum.yukleniyor()
          : l.isEmpty
          ? Durum.bos('Şu an sitede ziyaretçi yok.', ikon: Simgeler.visibilityOff)
          : RefreshIndicator(
              onRefresh: _yukle,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                itemCount: l.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _kart(l[i], r),
              ),
            ),
    );
  }

  Widget _kart(Ziyaretci z, Renkler r) {
    final sohbette = z.sohbette;
    return Kutu(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      onTap: () => ZiyaretciDetayEkrani.ac(context, z.id, ad: z.gosterimAdi),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Avatar(z.gosterimAdi, boyut: 42, tohum: z.eposta ?? '${z.id}'),
              Positioned(right: 0, bottom: 0, child: Nokta(sohbette ? Marka.mor : Marka.zumrut, boyut: 12, halka: r.kart)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (z.ulke != null) Text('${bayrak(z.ulke)} ', style: const TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        z.gosterimAdi,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 14.5),
                      ),
                    ),
                    if (z.sure != null) Text(z.sure!, style: TextStyle(color: r.silik, fontSize: 11.5)),
                  ],
                ),
                const SizedBox(height: 3),
                InkWell(
                  onTap: z.url == null ? null : () => disAc(z.url!),
                  child: Text(
                    z.baslik ?? kisaUrl(z.url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: r.vurgu, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                if (z.baslik != null)
                  Text(
                    kisaUrl(z.url, en: 60),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: r.silik, fontSize: 11.5),
                  ),
                if (z.yaziyor != null && z.yaziyor!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Yazıyor: ${z.yaziyor}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Marka.mor, fontSize: 12.5, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (z.sehir != null || z.ulke != null) Rozet([z.sehir, z.ulke].whereType<String>().join(', '), renk: Marka.mavi, ikon: Simgeler.place),
                    if (z.cihaz != null || z.sistem != null)
                      Rozet(
                        [z.cihaz, z.sistem].whereType<String>().join(' · '),
                        renk: const Color(0xFF64748B),
                        ikon: z.cihaz == 'mobile' ? Simgeler.smartphone : Simgeler.computer,
                      ),
                    if (z.tarayici != null) Rozet(z.tarayici!, renk: const Color(0xFF64748B), ikon: Simgeler.language),
                    Rozet('${z.sayfaSayisi} sayfa', renk: Marka.lavanta),
                    if (z.kaynak != null) Rozet(z.kaynak!, renk: Marka.kehribar),
                    if (sohbette) const Rozet('Sohbette', renk: Marka.mor, ikon: Simgeler.forum),
                  ],
                ),
              ],
            ),
          ),
          if (!sohbette && Uyg.yetki('chats.reply'))
            PopupMenuButton<String>(
              tooltip: 'İşlem',
              onSelected: (v) => v == 'davet'
                  ? _davet(z)
                  : v == 'detay'
                  ? ZiyaretciDetayEkrani.ac(context, z.id, ad: z.gosterimAdi)
                  : _baslat(z),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'detay',
                  child: ListTile(dense: true, leading: Icon(Simgeler.userCircle), title: Text('Ziyaretçi detayı')),
                ),
                PopupMenuItem(
                  value: 'davet',
                  child: ListTile(dense: true, leading: Icon(Simgeler.wavingHand), title: Text('Sohbete davet et')),
                ),
                PopupMenuItem(
                  value: 'baslat',
                  child: ListTile(dense: true, leading: Icon(Simgeler.forum), title: Text('Sohbet başlat')),
                ),
              ],
            )
          else
            IconButton(
              tooltip: 'Sohbete git',
              icon: const Icon(Simgeler.chevronRight),
              onPressed: sohbette ? () => bolumIstegi.value = Bolum.sohbetler : () => ZiyaretciDetayEkrani.ac(context, z.id, ad: z.gosterimAdi),
            ),
        ],
      ),
    );
  }
}
