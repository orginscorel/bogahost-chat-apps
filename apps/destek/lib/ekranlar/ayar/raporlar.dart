import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/parcalar.dart';
import '../../ortak/simgeler.dart';
import '../../ortak/yardimci.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Raporlar: günlük/aylık seri, durum dağılımı, saat/gün yoğunluğu, personel performansı, SLA, detaylı rapor
/// (ilk yanıt, çözüm süresi, en çok ziyaret edilen sayfalar, terk edilen sayfalar, dönüşüm, duygu, etkileşim).
class RaporlarEkrani extends StatefulWidget {
  const RaporlarEkrani({super.key});
  @override
  State<RaporlarEkrani> createState() => _RaporlarEkraniState();
}

class _RaporlarEkraniState extends State<RaporlarEkrani> {
  String _donem = 'daily';
  int _anahtar = 0;

  String _sure(num sn) => sn >= 3600
      ? '${(sn / 3600).toStringAsFixed(1)} sa'
      : sn >= 60
      ? '${(sn / 60).toStringAsFixed(0)} dk'
      : '${sn.toStringAsFixed(0)} sn';

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      key: ValueKey(_anahtar),
      baslik: 'Raporlar',
      yukle: () async {
        final a = await Panel.raporlar(donem: _donem);
        try {
          a['detay'] = await Panel.raporDetay();
        } catch (_) {}
        return a;
      },
      govde: (context, v, yenile) {
        final oz = harita(v['summary']);
        final seri = haritalar(v['series']);
        final durumlar = harita(v['statusRows']);
        final saatler = haritalar(v['byHour']);
        final gunler = haritalar(v['byDay']);
        final personel = haritalar(v['agents']);
        final sla = harita(v['sla']);
        final d = harita(v['detay']);
        return ListView(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Son 30 gün')),
                ButtonSegment(value: 'monthly', label: Text('Son 12 ay')),
              ],
              selected: {_donem},
              onSelectionChanged: (s) => setState(() {
                _donem = s.first;
                _anahtar++;
              }),
            ),
            const SizedBox(height: 12),
            EsitIzgara(
              enAz: 150,
              yukseklik: 66,
              children: [
                _kart('Bugün', '${tamsayi(oz['today'])}', Marka.mor, r),
                _kart('Bu hafta', '${tamsayi(oz['week'])}', Marka.mavi, r),
                _kart('Bu ay', '${tamsayi(oz['month'])}', Marka.lavanta, r),
                _kart('Toplam', '${tamsayi(oz['total'])}', const Color(0xFF0891B2), r),
                _kart('Ort. puan', ondalik(oz['avg_rating']).toStringAsFixed(1), Marka.kehribar, r, alt: '${tamsayi(oz['rated'])} oy'),
                _kart('Ziyaretçi (ay)', '${tamsayi(oz['visitors_month'])}', Marka.zumrut, r, alt: 'bugün ${tamsayi(oz['visitors_today'])}'),
              ],
            ),
            Baslik(_donem == 'daily' ? 'Günlük sohbet / ziyaretçi' : 'Aylık sohbet / ziyaretçi'),
            Kutu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Nokta(r.vurgu, boyut: 9),
                      const SizedBox(width: 5),
                      Text('Sohbet', style: TextStyle(color: r.soluk, fontSize: 12)),
                      const SizedBox(width: 14),
                      const Nokta(Marka.zumrut, boyut: 9),
                      const SizedBox(width: 5),
                      Text('Ziyaretçi', style: TextStyle(color: r.soluk, fontSize: 12)),
                      const Spacer(),
                      Text(
                        '${seri.fold<int>(0, (a, b) => a + tamsayi(b['count']))} sohbet · ${seri.fold<int>(0, (a, b) => a + tamsayi(b['visitors']))} ziyaretçi',
                        style: TextStyle(color: r.silik, fontSize: 11.5),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 220,
                    child: seri.isEmpty
                        ? const BosKucuk('Veri yok.', ikon: Simgeler.showChart)
                        : TrendGrafigi(
                            degerler: [for (final x in seri) tamsayi(x['count'])],
                            etiketler: [for (final x in seri) metin(x['label'])],
                            ikinci: [for (final x in seri) tamsayi(x['visitors'])],
                          ),
                  ),
                ],
              ),
            ),
            const Baslik('Durum dağılımı'),
            Kutu(
              child: Row(
                children: [
                  for (final (k, ad, renk) in [
                    ('open', 'Açık', Marka.zumrut),
                    ('closed', 'Kapalı', const Color(0xFF64748B)),
                    ('offline', 'Çevrimdışı', Marka.kehribar),
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          Text('${tamsayi(durumlar[k])}', style: gosterim(22, renk: renk)),
                          Text(ad, style: TextStyle(color: r.soluk, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Baslik('Saatlere göre yoğunluk'),
            Kutu(
              child: SizedBox(height: 110, child: _Isi(saatler, r, etiket: (x) => '${tamsayi(x['h'])}')),
            ),
            const Baslik('Günlere göre yoğunluk'),
            Kutu(
              child: SizedBox(height: 110, child: _Isi(gunler, r, etiket: (x) => metin(x['label']))),
            ),
            const Baslik('Personel performansı'),
            Kutu(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  for (final a in personel)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          KisiAvatar(metin(a['name']), url: metinYa(a['avatar']), boyut: 30),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              metin(a['name']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: r.metin, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text('${tamsayi(a['chats'])} sohbet', style: TextStyle(color: r.soluk, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(
                            '★ ${ondalik(a['avg']).toStringAsFixed(1)}',
                            style: const TextStyle(color: Marka.kehribar, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Text(_sure(ondalik(a['resp'])), style: TextStyle(color: r.silik, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Baslik('SLA · ilk yanıt hedefi'),
            _sla(sla, r),
            if (d.isNotEmpty) ...[
              Baslik('Detaylı rapor · ${metin(d['fromStr'])} – ${metin(d['toStr'])}'),
              EsitIzgara(
                enAz: 150,
                yukseklik: 66,
                children: [
                  _kart('İlk yanıt', metin(harita(d['firstResponse'])['human'], '—'), Marka.mor, r),
                  _kart('Çözüm süresi', metin(harita(d['resolution'])['human'], '—'), Marka.mavi, r),
                  _kart(
                    'Dönüşüm',
                    '%${ondalik(harita(d['conversion'])['rate']).toStringAsFixed(0)}',
                    Marka.zumrut,
                    r,
                    alt: '${tamsayi(harita(d['conversion'])['converted'])}/${tamsayi(harita(d['conversion'])['total'])}',
                  ),
                  _kart('Çevrimdışı mesaj', '${tamsayi(d['offlineCount'])}', Marka.kehribar, r),
                  _kart('Mesaj / sohbet', ondalik(harita(d['engagement'])['msg_per_conv']).toStringAsFixed(1), Marka.lavanta, r),
                  _kart('Sayfa / oturum', ondalik(harita(d['engagement'])['pv_per_session']).toStringAsFixed(1), const Color(0xFF0891B2), r),
                ],
              ),
              const Baslik('Duygu analizi'),
              Kutu(
                child: Row(
                  children: [
                    for (final (k, ad, renk) in [
                      ('positive', 'Olumlu', Marka.zumrut),
                      ('neutral', 'Nötr', const Color(0xFF64748B)),
                      ('negative', 'Olumsuz', Marka.gul),
                    ])
                      Expanded(
                        child: Column(
                          children: [
                            Text('${tamsayi(harita(d['sentiment'])[k])}', style: gosterim(22, renk: renk)),
                            Text(ad, style: TextStyle(color: r.soluk, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Baslik('Sohbet başlatılan sayfalar'),
              Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(children: [for (final p in haritalar(d['topPages'])) _sayfa(p, r)]),
              ),
              const Baslik('Terk edilen sayfalar'),
              Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(children: [for (final p in haritalar(d['abandoned'])) _sayfa(p, r)]),
              ),
            ],
          ],
        );
      },
    );
  }

  /// SLA paneli (web ile aynı): büyük renkli "hedef içinde" yüzdesi + 6 eşit kart.
  Widget _sla(Map<String, dynamic> sla, Renkler r) {
    final hedef = tamsayi(sla['target_min']);
    final pct = sla['within_pct'] == null ? null : ondalik(sla['within_pct']);
    final renk = pct == null
        ? Marka.grafitAcik
        : pct >= 90
        ? Marka.zumrut
        : pct >= 70
        ? Marka.kehribar
        : Marka.gul;
    return Kutu(
      child: LayoutBuilder(
        builder: (_, k) {
          final genis = k.maxWidth >= 640;
          final ozet = Column(
            crossAxisAlignment: genis ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pct == null ? '—' : '%${pct.toStringAsFixed(0)}',
                style: gosterim(44, renk: renk, agirlik: FontWeight.w800),
              ),
              Text('hedef içinde yanıtlanan', style: TextStyle(color: r.soluk, fontSize: 12.5)),
              const SizedBox(height: 4),
              Text(hedef == 0 ? 'Hedef tanımlı değil' : 'Hedef: ilk yanıt ≤ $hedef dk', style: TextStyle(color: r.silik, fontSize: 11.5)),
              if (pct != null) ...[const SizedBox(height: 8), SizedBox(width: 160, child: IlerlemeCubugu(pct / 100, renk: renk, yukseklik: 8))],
            ],
          );
          final kartlar = EsitIzgara(
            enAz: 140,
            yukseklik: 62,
            bosluk: 10,
            children: [
              KpiKart(kucuk: true, etiket: 'Yanıtlanan', deger: '${tamsayi(sla['answered'])}', ikon: Simgeler.checkCircle, renk: Marka.zumrut),
              KpiKart(kucuk: true, etiket: 'Ort. ilk yanıt', deger: _sure(ondalik(sla['avg_response'])), ikon: Simgeler.timer, renk: Marka.mavi),
              KpiKart(kucuk: true, etiket: 'En uzun yanıt', deger: _sure(ondalik(sla['max_response'])), ikon: Simgeler.hourglassBottom, renk: Marka.kehribar),
              KpiKart(kucuk: true, etiket: 'Aşılan', deger: '${tamsayi(sla['breached'])}', ikon: Simgeler.warningAmber, renk: Marka.gul),
              KpiKart(kucuk: true, etiket: 'Ort. çözüm', deger: _sure(ondalik(sla['avg_resolution'])), ikon: Simgeler.taskAlt, renk: Marka.lavanta),
              KpiKart(kucuk: true, etiket: 'Şu an bekleyen', deger: '${tamsayi(sla['waiting_now'])}', ikon: Simgeler.pending, renk: Marka.mor),
            ],
          );
          return genis
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 210, child: ozet),
                    const SizedBox(width: 18),
                    Expanded(child: kartlar),
                  ],
                )
              : Column(children: [ozet, const SizedBox(height: 14), kartlar]);
        },
      ),
    );
  }

  Widget _sayfa(Map<String, dynamic> p, Renkler r) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            metin(p['url']).replaceFirst(RegExp(r'^https?://'), ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: r.metin, fontSize: 12.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${tamsayi(p['count'])}',
          style: TextStyle(color: r.soluk, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _kart(String ad, String deger, Color renk, Renkler r, {String? alt}) =>
      KpiKart(kucuk: true, etiket: ad, deger: deger, ikon: Simgeler.chartBar, renk: renk, alt: alt);
}

/// Isı şeridi: değerler yoğunluğa göre renk alır.
class _Isi extends StatelessWidget {
  const _Isi(this.l, this.r, {required this.etiket});
  final List<Map<String, dynamic>> l;
  final Renkler r;
  final String Function(Map<String, dynamic>) etiket;
  @override
  Widget build(BuildContext context) {
    final enCok = l.fold<int>(1, (a, b) => tamsayi(b['count']) > a ? tamsayi(b['count']) : a);
    return Row(
      children: [
        for (final x in l)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Column(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: '${etiket(x)}: ${tamsayi(x['count'])}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Marka.mor.withValues(alpha: .12 + .88 * tamsayi(x['count']) / enCok),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    etiket(x),
                    style: TextStyle(color: r.silik, fontSize: l.length > 12 ? 8 : 10),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
