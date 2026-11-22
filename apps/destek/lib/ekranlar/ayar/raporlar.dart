import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

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
            Wrap(
              spacing: 10,
              runSpacing: 10,
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
            Kutu(child: SizedBox(height: 170, child: _Seri(seri, r))),
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
            const Baslik('SLA'),
            Kutu(
              child: Column(
                children: [
                  bilgi(context, 'Hedef', tamsayi(sla['target_min']) == 0 ? 'Tanımlı değil' : '${tamsayi(sla['target_min'])} dk'),
                  bilgi(context, 'Yanıtlanan', '${tamsayi(sla['answered'])}'),
                  bilgi(context, 'Ort. ilk yanıt', _sure(ondalik(sla['avg_response']))),
                  bilgi(context, 'En uzun yanıt', _sure(ondalik(sla['max_response']))),
                  bilgi(context, 'Hedef içinde', sla['within_pct'] == null ? '—' : '%${ondalik(sla['within_pct']).toStringAsFixed(0)}'),
                  bilgi(context, 'Aşılan', '${tamsayi(sla['breached'])}'),
                  bilgi(context, 'Ort. çözüm', _sure(ondalik(sla['avg_resolution']))),
                  bilgi(context, 'Şu an bekleyen', '${tamsayi(sla['waiting_now'])}'),
                ],
              ),
            ),
            if (d.isNotEmpty) ...[
              Baslik('Detaylı rapor · ${metin(d['fromStr'])} – ${metin(d['toStr'])}'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
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

  Widget _kart(String ad, String deger, Color renk, Renkler r, {String? alt}) => SizedBox(
    width: 150,
    child: Kutu(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(deger, style: gosterim(22, renk: renk)),
          Text(ad, style: TextStyle(color: r.soluk, fontSize: 12)),
          if (alt != null) Text(alt, style: TextStyle(color: r.silik, fontSize: 11)),
        ],
      ),
    ),
  );
}

/// Sohbet + ziyaretçi serisi: çubuk (sohbet) + ince çizgi (ziyaretçi, ayrı ölçek).
class _Seri extends StatelessWidget {
  const _Seri(this.l, this.r);
  final List<Map<String, dynamic>> l;
  final Renkler r;
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SeriBoyayici(l, r), size: Size.infinite);
}

class _SeriBoyayici extends CustomPainter {
  _SeriBoyayici(this.l, this.r);
  final List<Map<String, dynamic>> l;
  final Renkler r;
  @override
  void paint(Canvas c, Size s) {
    if (l.isEmpty) return;
    final altBos = 18.0, ustBos = 14.0;
    final h = s.height - altBos - ustBos;
    final enCok = l.fold<int>(1, (a, b) => tamsayi(b['count']) > a ? tamsayi(b['count']) : a);
    final zEnCok = l.fold<int>(1, (a, b) => tamsayi(b['visitors']) > a ? tamsayi(b['visitors']) : a);
    final adim = s.width / l.length;
    final cubuk = Paint()..color = Marka.mor.withValues(alpha: .85);
    final cizgi = Paint()
      ..color = Marka.zumrut
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final yol = Path();
    for (final (i, x) in l.indexed) {
      final cx = adim * i + adim / 2;
      final ch = h * tamsayi(x['count']) / enCok;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - adim * .3, ustBos + h - ch, adim * .6, ch), const Radius.circular(3)), cubuk);
      final zy = ustBos + h - h * tamsayi(x['visitors']) / zEnCok;
      i == 0 ? yol.moveTo(cx, zy) : yol.lineTo(cx, zy);
      if (l.length <= 12 || i % 5 == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: metin(x['label']),
            style: TextStyle(color: r.silik, fontSize: 9.5),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(cx - tp.width / 2, s.height - altBos + 4));
      }
    }
    c.drawPath(yol, cizgi);
    final tp = TextPainter(
      text: TextSpan(
        text: '■ sohbet  — ziyaretçi (en çok $enCok / $zEnCok)',
        style: TextStyle(color: r.silik, fontSize: 9.5),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, const Offset(0, 0));
  }

  @override
  bool shouldRepaint(_SeriBoyayici o) => o.l != l;
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
