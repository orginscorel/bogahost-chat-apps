import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/parcalar.dart';
import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'ayar/bildirim.dart';
import 'kabuk.dart';

/// Bildirim merkezi: sayaçlar, tür süzgeçleri (sohbet / mesaj / ekip / sistem), zaman grupları,
/// tümünü okundu yap, bildirim ayarlarına kısayol. 8 sn'de bir yenilenir.
class BildirimlerEkrani extends StatefulWidget {
  const BildirimlerEkrani({super.key});
  @override
  State<BildirimlerEkrani> createState() => _BildirimlerEkraniState();
}

class _BildirimlerEkraniState extends State<BildirimlerEkrani> {
  List<Bildirim>? _liste;
  String? _hata;
  Timer? _sayac;
  String _suzgec = 'hepsi';

  @override
  void initState() {
    super.initState();
    _yukle();
    _sayac = Timer.periodic(const Duration(seconds: 8), (_) => _yukle(sessiz: true));
  }

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  Future<void> _yukle({bool sessiz = false}) async {
    try {
      final v = await Depo.bildirimler();
      if (!mounted) return;
      sonBildirimler.value = v.ogeler;
      rozetler.value = {...rozetler.value, Bolum.bildirimler: v.okunmamis};
      setState(() {
        _liste = v.ogeler;
        _hata = null;
      });
    } catch (e) {
      if (mounted && !sessiz) setState(() => _hata = hataMetni(e));
    }
  }

  Future<void> _ac(Bildirim b) async {
    await bildirimAc(b);
    _yukle(sessiz: true);
  }

  static String tur(Bildirim b) => b.id.startsWith('conv-')
      ? 'sohbet'
      : b.id.startsWith('msg-')
      ? 'mesaj'
      : b.url.contains('/internal')
      ? 'ekip'
      : 'sistem';

  (IconData, Color) _gorunum(Bildirim b, Renkler r) => switch (tur(b)) {
    'sohbet' => (Simgeler.forum, Marka.gul),
    'mesaj' => (Simgeler.mail, r.vurgu),
    'ekip' => (Simgeler.groups, Marka.mavi),
    _ => (Simgeler.notifications, Marka.grafitAcik),
  };

  String _sure(int sn) => sn < 60
      ? 'şimdi'
      : sn < 3600
      ? '${sn ~/ 60} dk önce'
      : sn < 86400
      ? '${sn ~/ 3600} sa önce'
      : '${sn ~/ 86400} gün önce';

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l = _liste;
    return Scaffold(
      appBar: ekranBasligi(
        context,
        'Bildirimler',
        eylemler: [
          IconButton(tooltip: 'Bildirim ayarları', onPressed: () => yanPanelAc(context, const BildirimAyarEkrani()), icon: const Icon(Simgeler.tune)),
          IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh)),
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
                  final genis = k.maxWidth >= 760;
                  final okunmamis = l.where((b) => !b.okundu).length;
                  final sayilar = {
                    for (final t in ['sohbet', 'mesaj', 'ekip', 'sistem']) t: l.where((b) => tur(b) == t).length,
                  };
                  final bugun = l.where((b) => b.yasSn < 86400).length;
                  final suzulen = [
                    for (final b in l)
                      if (_suzgec == 'hepsi' || (_suzgec == 'okunmamis' ? !b.okundu : tur(b) == _suzgec)) b,
                  ];
                  final gruplar = <String, List<Bildirim>>{};
                  for (final b in suzulen) {
                    (gruplar[b.yasSn < 86400
                                ? 'Bugün'
                                : b.yasSn < 172800
                                ? 'Dün'
                                : 'Daha eski'] ??=
                            [])
                        .add(b);
                  }
                  return ortala(
                    ListView(
                      padding: EdgeInsets.fromLTRB(genis ? 24 : 14, 4, genis ? 24 : 14, 32),
                      children: [
                        SayfaBasi(
                          'Bildirimler',
                          alt: okunmamis == 0 ? 'Hepsi okundu' : '$okunmamis okunmamış bildirim',
                          rozet: okunmamis == 0 ? null : Rozet('$okunmamis yeni', renk: Marka.gul),
                          sag: [
                            if (kabukGomulu(context)) ...[
                              IconButton(
                                tooltip: 'Bildirim ayarları',
                                onPressed: () => yanPanelAc(context, const BildirimAyarEkrani()),
                                icon: const Icon(Simgeler.tune),
                              ),
                              IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh)),
                            ],
                            if (okunmamis > 0)
                              FilledButton.tonalIcon(
                                onPressed: () async {
                                  await islem(() => Depo.bildirimlerOkundu(), tamam: 'Hepsi okundu olarak işaretlendi');
                                  _yukle();
                                },
                                icon: const Icon(Simgeler.doneAll, size: 18),
                                label: const Text('Tümünü okundu yap'),
                              ),
                          ],
                        ),
                        EsitIzgara(
                          enAz: 146,
                          yukseklik: 72,
                          children: [
                            KpiKart(
                              kucuk: true,
                              etiket: 'Okunmamış',
                              deger: '$okunmamis',
                              ikon: Simgeler.notificationsActive,
                              renk: Marka.gul,
                              onTap: () => setState(() => _suzgec = 'okunmamis'),
                            ),
                            KpiKart(
                              kucuk: true,
                              etiket: 'Yeni sohbet',
                              deger: '${sayilar['sohbet']}',
                              ikon: Simgeler.forum,
                              renk: r.vurgu,
                              onTap: () => setState(() => _suzgec = 'sohbet'),
                            ),
                            KpiKart(
                              kucuk: true,
                              etiket: 'Mesaj',
                              deger: '${sayilar['mesaj']}',
                              ikon: Simgeler.mail,
                              renk: Marka.mavi,
                              onTap: () => setState(() => _suzgec = 'mesaj'),
                            ),
                            KpiKart(
                              kucuk: true,
                              etiket: 'Ekip',
                              deger: '${sayilar['ekip']}',
                              ikon: Simgeler.groups,
                              renk: Marka.lavanta,
                              onTap: () => setState(() => _suzgec = 'ekip'),
                            ),
                            KpiKart(
                              kucuk: true,
                              etiket: 'Bugün',
                              deger: '$bugun',
                              ikon: Simgeler.today,
                              renk: Marka.zumrut,
                              onTap: () => setState(() => _suzgec = 'hepsi'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final (k, ad) in const [
                              ('hepsi', 'Tümü'),
                              ('okunmamis', 'Okunmamış'),
                              ('sohbet', 'Sohbetler'),
                              ('mesaj', 'Mesajlar'),
                              ('ekip', 'Ekip'),
                              ('sistem', 'Sistem'),
                            ])
                              ChoiceChip(label: Text(ad), selected: _suzgec == k, onSelected: (_) => setState(() => _suzgec = k)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (suzulen.isEmpty)
                          Durum.bos(l.isEmpty ? 'Bildirim yok.' : 'Bu süzgeçte bildirim yok.', ikon: Simgeler.notificationsNone)
                        else
                          for (final g in gruplar.entries) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                              child: Text(
                                g.key.toUpperCase(),
                                style: TextStyle(color: r.silik, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8),
                              ),
                            ),
                            Kutu(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (final (i, b) in g.value.indexed) ...[
                                    if (i > 0) Divider(height: 1, indent: 66, color: r.kenar.withValues(alpha: .6)),
                                    _satir(b, r, ilk: i == 0, son: i == g.value.length - 1),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _satir(Bildirim b, Renkler r, {required bool ilk, required bool son}) {
    final (ikon, renk) = _gorunum(b, r);
    return InkWell(
      onTap: () => _ac(b),
      borderRadius: BorderRadius.vertical(top: Radius.circular(ilk ? 18 : 0), bottom: Radius.circular(son ? 18 : 0)),
      child: Container(
        decoration: BoxDecoration(
          color: b.okundu ? null : r.vurguYumusak.withValues(alpha: .35),
          borderRadius: BorderRadius.vertical(top: Radius.circular(ilk ? 18 : 0), bottom: Radius.circular(son ? 18 : 0)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: (b.okundu ? r.soluk : renk).withValues(alpha: .13), borderRadius: BorderRadius.circular(12)),
              child: Icon(ikon, color: b.okundu ? r.soluk : renk, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.baslik,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: b.okundu ? FontWeight.w500 : FontWeight.w700, fontSize: 14, color: r.metin),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_sure(b.yasSn), style: TextStyle(color: r.silik, fontSize: 11.5)),
                      if (!b.okundu) const Padding(padding: EdgeInsets.only(left: 8), child: Nokta(Marka.gul, boyut: 8)),
                    ],
                  ),
                  if (b.govde.isNotEmpty)
                    Text(
                      b.govde,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: r.soluk, fontSize: 12.5),
                    ),
                  if (b.sohbetId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Sohbet #${b.sohbetId} · aç →',
                        style: TextStyle(color: r.vurgu, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
