import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/parcalar.dart';
import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'ekran_izle.dart';
import 'kabuk.dart';
import 'ziyaretci_detay.dart';

/// Canlı Ziyaretçiler — web panelindeki tablo (Ziyaretçi · Konum · Cihaz · Sayfa · Geliş kaynağı · Son hareket ·
/// İşlem) + üstte sayaçlar, arama ve süzgeç çipleri. Telefonda kart görünümü. 5 sn'de bir yenilenir.
class ZiyaretcilerEkrani extends StatefulWidget {
  const ZiyaretcilerEkrani({super.key});
  @override
  State<ZiyaretcilerEkrani> createState() => _ZiyaretcilerEkraniState();
}

class _ZiyaretcilerEkraniState extends State<ZiyaretcilerEkrani> {
  List<Ziyaretci>? _liste;
  String? _hata;
  Timer? _sayac;
  DateTime? _son;
  final _q = TextEditingController();
  String _suzgec = 'hepsi';

  @override
  void initState() {
    super.initState();
    _yukle();
    _sayac = Timer.periodic(const Duration(seconds: 5), (_) => _yukle(sessiz: true));
  }

  @override
  void dispose() {
    _sayac?.cancel();
    _q.dispose();
    super.dispose();
  }

  Future<void> _yukle({bool sessiz = false}) async {
    try {
      final l = await Depo.canliZiyaretciler();
      if (!mounted) return;
      setState(() {
        _liste = l;
        _hata = null;
        _son = DateTime.now();
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

  void _detay(Ziyaretci z) => ZiyaretciDetayEkrani.ac(context, z.id, ad: z.gosterimAdi);
  void _ekran(Ziyaretci z) => EkranIzleEkrani.ac(context, oturumId: z.id, ad: z.gosterimAdi, kip: 'consent', url: z.url);

  List<Ziyaretci> _suz(List<Ziyaretci> l) {
    final q = _q.text.trim().toLowerCase();
    return [
      for (final z in l)
        if (switch (_suzgec) {
              'sohbette' => z.sohbette,
              'geziniyor' => !z.sohbette,
              'yaziyor' => (z.yaziyor ?? '').isNotEmpty,
              'mobil' => z.mobil,
              _ => true,
            } &&
            (q.isEmpty ||
                [
                  z.ad,
                  z.eposta,
                  z.ip,
                  z.url,
                  z.baslik,
                  z.sehir,
                  z.ulke,
                  z.kaynak,
                  z.kaynakAlt,
                  z.tarayici,
                  z.sistem,
                ].any((x) => (x ?? '').toLowerCase().contains(q))))
          z,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    if (!Uyg.yetki('visitors.view')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Canlı Ziyaretçiler'), actions: kabukEylemleri(context)),
        body: const Yetkisiz('Ziyaretçileri görmek'),
      );
    }
    final l = _liste;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Ziyaretçiler'),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh)),
          ...kabukEylemleri(context),
        ],
      ),
      body: _hata != null
          ? Durum.hata(_hata!, tekrar: _yukle)
          : l == null
          ? const Durum.yukleniyor()
          : RefreshIndicator(
              onRefresh: _yukle,
              child: LayoutBuilder(
                builder: (_, k) {
                  final tablo = k.maxWidth >= 980;
                  final suzulen = _suz(l);
                  final sohbette = l.where((z) => z.sohbette).length;
                  final yaziyor = l.where((z) => (z.yaziyor ?? '').isNotEmpty).length;
                  final mobil = l.where((z) => z.mobil).length;
                  final ulkeler = l.map((z) => z.ulke).whereType<String>().toSet().length;
                  final yatay = tablo ? 20.0 : 14.0;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(yatay, 4, yatay, 32),
                    children: [
                      SayfaBasi(
                        '${l.length} ziyaretçi sitede',
                        rozet: const CanliIsareti(),
                        alt: _son == null
                            ? null
                            : 'Son güncelleme ${_son!.hour.toString().padLeft(2, '0')}:${_son!.minute.toString().padLeft(2, '0')}:${_son!.second.toString().padLeft(2, '0')} · 5 sn\'de bir yenilenir',
                        sag: [
                          SizedBox(
                            width: 300,
                            child: TextField(
                              controller: _q,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Ad, e-posta, IP, sayfa, şehir…',
                                prefixIcon: const Icon(Simgeler.search, size: 18),
                                suffixIcon: _q.text.isEmpty
                                    ? null
                                    : IconButton(icon: const Icon(Simgeler.close, size: 16), onPressed: () => setState(_q.clear)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      EsitIzgara(
                        enAz: 146,
                        yukseklik: 64,
                        children: [
                          KpiKart(
                            kucuk: true,
                            etiket: 'Toplam online',
                            deger: '${l.length}',
                            ikon: Simgeler.visibility,
                            renk: Marka.zumrut,
                            onTap: () => setState(() => _suzgec = 'hepsi'),
                          ),
                          KpiKart(
                            kucuk: true,
                            etiket: 'Sohbette',
                            deger: '$sohbette',
                            ikon: Simgeler.forum,
                            renk: r.vurgu,
                            onTap: () => setState(() => _suzgec = 'sohbette'),
                          ),
                          KpiKart(
                            kucuk: true,
                            etiket: 'Geziniyor',
                            deger: '${l.length - sohbette}',
                            ikon: Simgeler.cursorClick,
                            renk: Marka.mavi,
                            onTap: () => setState(() => _suzgec = 'geziniyor'),
                          ),
                          KpiKart(
                            kucuk: true,
                            etiket: 'Yazıyor',
                            deger: '$yaziyor',
                            ikon: Simgeler.chatDots,
                            renk: Marka.kehribar,
                            onTap: () => setState(() => _suzgec = 'yaziyor'),
                          ),
                          KpiKart(
                            kucuk: true,
                            etiket: 'Mobil',
                            deger: '$mobil',
                            ikon: Simgeler.smartphone,
                            renk: Marka.lavanta,
                            onTap: () => setState(() => _suzgec = 'mobil'),
                          ),
                          KpiKart(kucuk: true, etiket: 'Ülke', deger: '$ulkeler', ikon: Simgeler.public, renk: Marka.gok),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final (k, ad, n) in [
                            ('hepsi', 'Tümü', l.length),
                            ('sohbette', 'Sohbette', sohbette),
                            ('geziniyor', 'Geziniyor', l.length - sohbette),
                            ('yaziyor', 'Yazıyor', yaziyor),
                            ('mobil', 'Mobil', mobil),
                          ])
                            ChoiceChip(
                              label: Text('$ad · $n'),
                              selected: _suzgec == k,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setState(() => _suzgec = k),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (l.isEmpty)
                        Durum.bos('Şu an sitede ziyaretçi yok.', ikon: Simgeler.visibilityOff)
                      else if (suzulen.isEmpty)
                        Durum.bos('Süzgece uyan ziyaretçi yok.', ikon: Simgeler.funnel)
                      else if (tablo)
                        Kutu(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Column(
                              children: [
                                const TabloBasi([
                                  ('ZİYARETÇİ', 5),
                                  ('KONUM', 3),
                                  ('CİHAZ', 3),
                                  ('BULUNDUĞU SAYFA', 5),
                                  ('GELİŞ KAYNAĞI', 3),
                                  ('SON HAREKET', 2),
                                  ('İŞLEM', 4),
                                ]),
                                for (final (i, z) in suzulen.indexed) ...[
                                  if (i > 0) Divider(height: 1, color: r.kenar.withValues(alpha: .6)),
                                  _TabloSatiri(z: z, onDetay: () => _detay(z), onDavet: () => _davet(z), onBaslat: () => _baslat(z), onEkran: () => _ekran(z)),
                                ],
                              ],
                            ),
                          ),
                        )
                      else
                        for (final z in suzulen) Padding(padding: const EdgeInsets.only(bottom: 8), child: _kart(z, r)),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _kart(Ziyaretci z, Renkler r) {
    final sohbette = z.sohbette;
    return HoverKutu(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      onTap: () => _detay(z),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Avatar(z.gosterimAdi, boyut: 42, tohum: z.eposta ?? '${z.id}'),
              Positioned(right: -1, bottom: -1, child: Nokta(sohbette ? r.vurgu : Marka.zumrut, boyut: 12, halka: r.kart)),
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
                if (z.eposta != null || z.ip != null)
                  Text(
                    z.eposta ?? z.ip!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: r.silik, fontSize: 11.5),
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
                if ((z.yaziyor ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      '✍ ${z.yaziyor}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Marka.kehribar, fontSize: 12.5, fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (z.sehir != null || z.ulke != null) Rozet([z.sehir, z.ulke].whereType<String>().join(', '), renk: Marka.mavi, ikon: Simgeler.place),
                    if (z.cihaz != null || z.sistem != null)
                      Rozet([z.sistem, z.tarayici].whereType<String>().join(' · '), renk: Marka.grafit, ikon: cihazSimgesi(z.cihaz)),
                    Rozet('${z.sayfaSayisi} sayfa', renk: Marka.lavanta),
                    if (z.kaynak != null) Rozet(z.kaynak!, renk: kaynakRengi(z.kaynakTur, r)),
                    if (sohbette) Rozet('Sohbette', renk: r.vurgu, ikon: Simgeler.forum),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'İşlem',
            onSelected: (v) => switch (v) {
              'davet' => _davet(z),
              'baslat' => _baslat(z),
              'ekran' => _ekran(z),
              'sohbet' => bolumIstegi.value = Bolum.sohbetler,
              _ => _detay(z),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'detay',
                child: ListTile(dense: true, leading: Icon(Simgeler.userCircle), title: Text('Ziyaretçi detayı / CRM')),
              ),
              if (sohbette)
                const PopupMenuItem(
                  value: 'sohbet',
                  child: ListTile(dense: true, leading: Icon(Simgeler.forum), title: Text('Sohbete git')),
                ),
              if (!sohbette && Uyg.yetki('chats.reply')) ...[
                const PopupMenuItem(
                  value: 'davet',
                  child: ListTile(dense: true, leading: Icon(Simgeler.wavingHand), title: Text('Sohbete davet et')),
                ),
                const PopupMenuItem(
                  value: 'baslat',
                  child: ListTile(dense: true, leading: Icon(Simgeler.chatText), title: Text('Sohbet başlat')),
                ),
              ],
              if (Uyg.yetki('screen.consent'))
                const PopupMenuItem(
                  value: 'ekran',
                  child: ListTile(dense: true, leading: Icon(Simgeler.monitor), title: Text('Ekranı izle')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Geliş kaynağı rengi (web ile aynı): arama yeşil, yapay zekâ mor, sosyal gök, e-posta/kampanya kehribar,
/// doğrudan/site içi gri, yönlendirme/uygulama vurgu.
Color kaynakRengi(String? tur, Renkler r) => switch (tur) {
  'search' => Marka.zumrut,
  'ai' => Marka.mor,
  'social' => Marka.gok,
  'email' || 'campaign' => Marka.kehribar,
  'direct' || 'internal' => Marka.grafit,
  'referral' || 'app' => r.vurgu,
  _ => Marka.grafitAcik,
};

IconData cihazSimgesi(String? cihaz) {
  final c = (cihaz ?? '').toLowerCase();
  if (c.contains('tablet')) return Simgeler.tabletMac;
  if (c.contains('mobil') || c.contains('phone')) return Simgeler.smartphone;
  return Simgeler.computer;
}

/// Geniş ekran tablo satırı (hover vurgulu).
class _TabloSatiri extends StatefulWidget {
  const _TabloSatiri({required this.z, required this.onDetay, required this.onDavet, required this.onBaslat, required this.onEkran});
  final Ziyaretci z;
  final VoidCallback onDetay, onDavet, onBaslat, onEkran;
  @override
  State<_TabloSatiri> createState() => _TabloSatiriState();
}

class _TabloSatiriState extends State<_TabloSatiri> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final z = widget.z;
    final soluk = TextStyle(color: r.silik, fontSize: 11.5);
    final normal = TextStyle(color: r.metin, fontSize: 13);
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: InkWell(
        onTap: widget.onDetay,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _h ? r.vurguYumusak.withValues(alpha: .45) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Avatar(z.gosterimAdi, boyut: 36, tohum: z.eposta ?? '${z.id}'),
                        Positioned(right: -1, bottom: -1, child: Nokta(z.sohbette ? r.vurgu : Marka.zumrut, boyut: 11, halka: r.kart)),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            z.gosterimAdi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: r.metin, fontWeight: FontWeight.w600, fontSize: 13.5),
                          ),
                          Text(z.eposta ?? z.ip ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: soluk),
                          if ((z.yaziyor ?? '').isNotEmpty)
                            Text(
                              '✍ ${z.yaziyor}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Marka.kehribar, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Text(bayrak(z.ulke), style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(z.sehir ?? z.ulke ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: normal),
                          if (z.sehir != null && z.ulke != null) Text(z.ulke!, style: soluk),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Icon(cihazSimgesi(z.cihaz), size: 18, color: r.soluk),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(z.sistem ?? z.cihaz ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis, style: normal),
                          if (z.tarayici != null) Text(z.tarayici!, maxLines: 1, overflow: TextOverflow.ellipsis, style: soluk),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: z.url == null ? null : () => disAc(z.url!),
                        child: Text(
                          z.baslik ?? kisaUrl(z.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: r.vurgu, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${z.baslik != null ? '${kisaUrl(z.url, en: 54)} · ' : ''}${z.sayfaSayisi} sayfa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: soluk,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Tooltip(
                  message: z.kaynakDetay ?? z.kaynak ?? '',
                  child: Row(
                    children: [
                      Nokta(kaynakRengi(z.kaynakTur, r), boyut: 9),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(z.kaynak ?? 'Doğrudan', maxLines: 1, overflow: TextOverflow.ellipsis, style: normal),
                            if (z.kaynakAlt != null) Text(z.kaynakAlt!, maxLines: 1, overflow: TextOverflow.ellipsis, style: soluk),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(z.sure ?? '—', style: normal),
                    if (z.baslangic != null) Text(z.baslangic!, maxLines: 1, overflow: TextOverflow.ellipsis, style: soluk),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    if (z.sohbette)
                      _Hap('Sohbette', renk: r.vurgu, ikon: Simgeler.forum, onTap: () => bolumIstegi.value = Bolum.sohbetler)
                    else if (Uyg.yetki('chats.reply'))
                      _Hap('Sohbet başlat', renk: Marka.zumrut, ikon: Simgeler.chatText, onTap: widget.onBaslat)
                    else
                      _Hap('Geziniyor', renk: Marka.grafitAcik),
                    const SizedBox(width: 4),
                    if (!z.sohbette && Uyg.yetki('chats.reply'))
                      IconButton(
                        tooltip: 'Davet et',
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onDavet,
                        icon: Icon(Simgeler.wavingHand, size: 18, color: r.soluk),
                      ),
                    if (Uyg.yetki('screen.consent'))
                      IconButton(
                        tooltip: 'Ekranı izle',
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onEkran,
                        icon: Icon(Simgeler.monitor, size: 18, color: r.soluk),
                      ),
                    IconButton(
                      tooltip: 'Detay / CRM',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onDetay,
                      icon: Icon(Simgeler.userCircle, size: 18, color: r.soluk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hap extends StatelessWidget {
  const _Hap(this.metin, {required this.renk, this.ikon, this.onTap});
  final String metin;
  final Color renk;
  final IconData? ikon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: renk.withValues(alpha: .13), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[Icon(ikon, size: 13, color: renk), const SizedBox(width: 5)],
          Text(
            metin,
            style: TextStyle(color: renk, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}
