// Ortak sayfa parçaları: KPI kartları (eşit boy), ızgara, sayfa başlığı, hover'lı kart, grafik ve halka.
import 'dart:math' as math;

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import 'simgeler.dart';

/// Sayfa başlığı: büyük başlık + alt açıklama + sağda eylemler. Web panelindeki `page-head` karşılığı.
class SayfaBasi extends StatelessWidget {
  const SayfaBasi(this.baslik, {super.key, this.alt, this.sag = const [], this.rozet});
  final String baslik;
  final String? alt;
  final List<Widget> sag;
  final Widget? rozet;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.end,
        runSpacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    baslik,
                    style: gosterim(22, renk: r.metin, agirlik: FontWeight.w700),
                  ),
                  if (rozet != null) ...[const SizedBox(width: 10), rozet!],
                ],
              ),
              if (alt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(alt!, style: TextStyle(color: r.soluk, fontSize: 13)),
                ),
            ],
          ),
          if (sag.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: sag),
        ],
      ),
    );
  }
}

/// Canlı noktası: yanıp sönen yeşil nokta + "canlı" yazısı.
class CanliIsareti extends StatefulWidget {
  const CanliIsareti({super.key, this.metin = 'canlı', this.renk = Marka.zumrut});
  final String metin;
  final Color renk;
  @override
  State<CanliIsareti> createState() => _CanliIsaretiState();
}

class _CanliIsaretiState extends State<CanliIsareti> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FadeTransition(
        opacity: Tween(begin: .35, end: 1.0).animate(_c),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: widget.renk, shape: BoxShape.circle),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        widget.metin,
        style: TextStyle(color: widget.renk, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

/// KPI kartı: renkli ikon rozeti, büyük sayı, etiket, alt metin. Yükseklik dıştan sabitlenir (EsitIzgara).
class KpiKart extends StatelessWidget {
  const KpiKart({
    super.key,
    required this.etiket,
    required this.deger,
    required this.ikon,
    required this.renk,
    this.alt,
    this.canli = false,
    this.onTap,
    this.egilim,
    this.kucuk = false,
  });
  final String etiket, deger;
  final String? alt;
  final IconData ikon;
  final Color renk;
  final bool canli, kucuk;
  final VoidCallback? onTap;

  /// Pozitif/negatif değişim (ör. +12). Null ise gösterilmez.
  final double? egilim;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return HoverKutu(
      onTap: onTap,
      padding: EdgeInsets.all(kucuk ? 12 : 16),
      child: kucuk
          ? Row(
              children: [
                _rozet(36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        deger,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: gosterim(22, renk: r.metin, agirlik: FontWeight.w700),
                      ),
                      Text(
                        alt == null ? etiket : '$etiket · $alt',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: r.soluk, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [_rozet(40), const Spacer(), if (canli) const CanliIsareti(), if (egilim != null) _egilim(egilim!)]),
                const Spacer(),
                Text(
                  deger,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gosterim(28, renk: r.metin, agirlik: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  etiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: r.metin, fontWeight: FontWeight.w500, fontSize: 13),
                ),
                if (alt != null)
                  Text(
                    alt!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: r.silik, fontSize: 11.5),
                  ),
              ],
            ),
    );
  }

  Widget _rozet(double b) => Container(
    width: b,
    height: b,
    decoration: BoxDecoration(color: renk.withValues(alpha: .13), borderRadius: BorderRadius.circular(b * .3)),
    child: Icon(ikon, color: renk, size: b * .52),
  );

  Widget _egilim(double e) {
    final art = e >= 0;
    final c = art ? Marka.zumrut : Marka.gul;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(art ? Simgeler.trendingUp : Simgeler.trendingDown, size: 14, color: c),
        const SizedBox(width: 3),
        Text(
          '${art ? '+' : ''}${e.abs() % 1 == 0 ? e.toInt() : e.toStringAsFixed(1)}',
          style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Eşit boyutlu ızgara: genişliğe göre sütun sayısı; tüm hücreler aynı yükseklikte (KPI'lar eşit boyda).
class EsitIzgara extends StatelessWidget {
  const EsitIzgara({super.key, required this.children, this.enAz = 160, this.yukseklik = 128, this.bosluk = 12, this.enCokSutun});
  final List<Widget> children;
  final double enAz, yukseklik, bosluk;
  final int? enCokSutun;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, k) {
      if (children.isEmpty) return const SizedBox.shrink();
      var sutun = ((k.maxWidth + bosluk) / (enAz + bosluk)).floor().clamp(1, children.length);
      if (enCokSutun != null) sutun = math.min(sutun, enCokSutun!);
      final satirlar = <List<Widget>>[];
      for (var i = 0; i < children.length; i += sutun) {
        satirlar.add(children.sublist(i, math.min(i + sutun, children.length)));
      }
      return Column(
        children: [
          for (final (si, s) in satirlar.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: si == satirlar.length - 1 ? 0 : bosluk),
              child: SizedBox(
                height: yukseklik,
                child: Row(
                  children: [
                    for (final (i, c) in s.indexed) ...[if (i > 0) SizedBox(width: bosluk), Expanded(child: c)],
                    // Son satır eksikse hizayı korumak için boş hücreler
                    for (var i = s.length; i < sutun; i++) ...[SizedBox(width: bosluk), const Expanded(child: SizedBox())],
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Üzerine gelince hafif yükselen, gölgelenen kart (masaüstü); dokunmatikte normal kart.
class HoverKutu extends StatefulWidget {
  const HoverKutu({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.renk, this.vurgulu = false});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? renk;
  final bool vurgulu;
  @override
  State<HoverKutu> createState() => _HoverKutuState();
}

class _HoverKutuState extends State<HoverKutu> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final aktif = _h && widget.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: Matrix4.translationValues(0, aktif ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: widget.renk ?? r.kart,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.vurgulu ? r.vurgu.withValues(alpha: .5) : (aktif ? r.vurgu.withValues(alpha: .35) : r.kenar)),
          boxShadow: aktif
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: r.koyu ? .35 : .08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTap,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Kart başlığı: sol başlık (+ küçük not), sağda bağlantı/eylem.
class KartBasi extends StatelessWidget {
  const KartBasi(this.baslik, {super.key, this.not, this.sag, this.rozet});
  final String baslik;
  final String? not;
  final Widget? sag, rozet;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    baslik,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 14.5),
                  ),
                ),
                if (not != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(not!, style: TextStyle(color: r.silik, fontSize: 11.5)),
                  ),
                if (rozet != null) Padding(padding: const EdgeInsets.only(left: 8), child: rozet!),
              ],
            ),
          ),
          ?sag,
        ],
      ),
    );
  }
}

/// Kısa bağlantı yazısı ("Tümü →").
class Baglanti extends StatelessWidget {
  const Baglanti(this.metin, {super.key, required this.onTap});
  final String metin;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        metin,
        style: TextStyle(color: context.r.vurgu, fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

/// İnce ilerleme çubuğu.
class IlerlemeCubugu extends StatelessWidget {
  const IlerlemeCubugu(this.oran, {super.key, this.renk, this.yukseklik = 6});
  final double oran;
  final Color? renk;
  final double yukseklik;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: yukseklik,
        child: Stack(
          children: [
            Container(color: r.zemin),
            FractionallySizedBox(
              widthFactor: oran.clamp(0, 1),
              child: Container(color: renk ?? r.vurgu),
            ),
          ],
        ),
      ),
    );
  }
}

/// Memnuniyet halkası: ortalama / 5.
class MemnuniyetHalkasi extends StatelessWidget {
  const MemnuniyetHalkasi(this.ort, {super.key, this.boyut = 140});
  final double ort;
  final double boyut;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return SizedBox(
      width: boyut,
      height: boyut,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(boyut),
            painter: _HalkaBoyayici(
              ort / 5,
              r.kenar,
              ort >= 4
                  ? Marka.zumrut
                  : ort >= 3
                  ? Marka.kehribar
                  : Marka.gul,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ort == 0 ? '–' : ort.toStringAsFixed(1),
                style: gosterim(30, renk: r.metin, agirlik: FontWeight.w700),
              ),
              Text('/ 5.0', style: TextStyle(color: r.silik, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HalkaBoyayici extends CustomPainter {
  _HalkaBoyayici(this.oran, this.zemin, this.renk);
  final double oran;
  final Color zemin, renk;
  @override
  void paint(Canvas c, Size s) {
    final k = 10.0;
    final rect = Rect.fromLTWH(k / 2, k / 2, s.width - k, s.height - k);
    c.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = zemin
        ..style = PaintingStyle.stroke
        ..strokeWidth = k,
    );
    c.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * oran.clamp(0, 1),
      false,
      Paint()
        ..color = renk
        ..style = PaintingStyle.stroke
        ..strokeWidth = k
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HalkaBoyayici o) => o.oran != oran || o.renk != renk;
}

/// Düzgün alan-çizgi grafiği (son 7 gün trendi): yumuşatılmış eğri, degrade dolgu, kılavuz çizgileri,
/// nokta ve üzerine gelince değer balonu.
class TrendGrafigi extends StatefulWidget {
  const TrendGrafigi({super.key, required this.degerler, required this.etiketler, this.renk, this.ikinci, this.ikinciRenk});
  final List<num> degerler;
  final List<String> etiketler;
  final Color? renk;
  final List<num>? ikinci;
  final Color? ikinciRenk;
  @override
  State<TrendGrafigi> createState() => _TrendGrafigiState();
}

class _TrendGrafigiState extends State<TrendGrafigi> {
  int? _secili;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final renk = widget.renk ?? r.vurgu;
    return LayoutBuilder(
      builder: (_, k) {
        final n = widget.degerler.length;
        void sec(Offset p) {
          if (n == 0) return;
          final adim = (k.maxWidth - 24) / math.max(1, n - 1);
          final i = ((p.dx - 12) / adim).round().clamp(0, n - 1);
          if (i != _secili) setState(() => _secili = i);
        }

        return MouseRegion(
          onHover: (e) => sec(e.localPosition),
          onExit: (_) => setState(() => _secili = null),
          child: GestureDetector(
            onPanDown: (d) => sec(d.localPosition),
            onPanUpdate: (d) => sec(d.localPosition),
            onPanEnd: (_) => setState(() => _secili = null),
            child: CustomPaint(
              size: Size(k.maxWidth, k.maxHeight),
              painter: _TrendBoyayici(widget.degerler, widget.etiketler, renk, r, _secili, widget.ikinci, widget.ikinciRenk ?? Marka.zumrut),
            ),
          ),
        );
      },
    );
  }
}

class _TrendBoyayici extends CustomPainter {
  _TrendBoyayici(this.v, this.et, this.renk, this.r, this.secili, this.v2, this.renk2);
  final List<num> v;
  final List<num>? v2;
  final List<String> et;
  final Color renk, renk2;
  final Renkler r;
  final int? secili;

  @override
  void paint(Canvas c, Size s) {
    if (v.isEmpty) return;
    const solBos = 12.0, sagBos = 12.0, ustBos = 26.0, altBos = 26.0;
    final iw = s.width - solBos - sagBos, ih = s.height - ustBos - altBos;
    final hepsi = [...v, ...?v2];
    final enCok = math.max(1, hepsi.fold<num>(0, (a, b) => b > a ? b : a)).toDouble();
    final n = v.length;
    List<Offset> noktalar(List<num> l) => [
      for (final (i, d) in l.indexed) Offset(n > 1 ? solBos + i / (n - 1) * iw : solBos + iw / 2, ustBos + ih - d / enCok * ih),
    ];
    // kılavuz
    for (var g = 0; g <= 4; g++) {
      final y = ustBos + ih * g / 4;
      c.drawLine(
        Offset(solBos, y),
        Offset(s.width - sagBos, y),
        Paint()
          ..color = r.kenar.withValues(alpha: g == 4 ? 1 : .6)
          ..strokeWidth = 1,
      );
    }
    Path egri(List<Offset> p) {
      final d = Path()..moveTo(p[0].dx, p[0].dy);
      if (p.length < 2) return d;
      const t = .16;
      for (var i = 0; i < p.length - 1; i++) {
        final p0 = p[math.max(0, i - 1)], p1 = p[i], p2 = p[i + 1], p3 = p[math.min(p.length - 1, i + 2)];
        d.cubicTo(p1.dx + (p2.dx - p0.dx) * t, p1.dy + (p2.dy - p0.dy) * t, p2.dx - (p3.dx - p1.dx) * t, p2.dy - (p3.dy - p1.dy) * t, p2.dx, p2.dy);
      }
      return d;
    }

    if (v2 != null && v2!.length == n) {
      final p2 = noktalar(v2!);
      c.drawPath(
        egri(p2),
        Paint()
          ..color = renk2.withValues(alpha: .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
    final p = noktalar(v);
    final cizgi = egri(p);
    final alan = Path.from(cizgi)
      ..lineTo(p.last.dx, ustBos + ih)
      ..lineTo(p.first.dx, ustBos + ih)
      ..close();
    c.drawPath(
      alan,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [renk.withValues(alpha: .26), renk.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, ustBos, s.width, ih)),
    );
    c.drawPath(
      cizgi,
      Paint()
        ..color = renk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final (i, o) in p.indexed) {
      final sec = i == secili;
      c.drawCircle(o, sec ? 6 : 4, Paint()..color = r.kart);
      c.drawCircle(
        o,
        sec ? 6 : 4,
        Paint()
          ..color = renk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final adim = n <= 8 ? 1 : (n / 7).ceil();
      if (sec || i % adim == 0 || i == n - 1) {
        final tp = TextPainter(
          text: TextSpan(
            text: et.elementAtOrNull(i) ?? '',
            style: TextStyle(color: sec ? r.metin : r.silik, fontSize: 11, fontWeight: sec ? FontWeight.w600 : FontWeight.w500),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset((o.dx - tp.width / 2).clamp(0, s.width - tp.width), s.height - altBos + 8));
      }
      if (sec) {
        final etiket = v2 != null && v2!.length == n ? '${v[i]} sohbet · ${v2![i]} ziyaretçi' : '${v[i]}';
        final bt = TextPainter(
          text: TextSpan(
            text: etiket,
            style: TextStyle(color: r.kart, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final bw = bt.width + 14, bh = bt.height + 6;
        final bx = (o.dx - bw / 2).clamp(0, s.width - bw).toDouble(), by = math.max(0, o.dy - bh - 10).toDouble();
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(6)), Paint()..color = r.metin);
        bt.paint(c, Offset(bx + 7, by + 3));
      }
    }
  }

  @override
  bool shouldRepaint(_TrendBoyayici o) => o.v != v || o.secili != secili || o.v2 != v2 || o.r != r;
}

/// Sıralı liste satırı (lider tablosu vb.): sıra numarası + avatar + ad + sağ değer + ilerleme.
class SiraSatiri extends StatelessWidget {
  const SiraSatiri({super.key, required this.sira, required this.ad, required this.oran, this.avatar, this.sag, this.renk});
  final int sira;
  final String ad;
  final double oran;
  final Widget? avatar;
  final String? sag;
  final Color? renk;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$sira',
              textAlign: TextAlign.center,
              style: TextStyle(color: sira == 1 ? Marka.kehribar : r.silik, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          if (avatar != null) ...[const SizedBox(width: 6), avatar!, const SizedBox(width: 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: r.metin, fontWeight: FontWeight.w500, fontSize: 13.5),
                      ),
                    ),
                    if (sag != null) Text(sag!, style: TextStyle(color: r.soluk, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                IlerlemeCubugu(oran, renk: renk),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Boş durum (kart içinde küçük).
class BosKucuk extends StatelessWidget {
  const BosKucuk(this.metin, {super.key, this.ikon = Simgeler.checkCircleOutline});
  final String metin;
  final IconData ikon;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          Icon(ikon, size: 30, color: r.silik.withValues(alpha: .6)),
          const SizedBox(height: 6),
          Text(metin, style: TextStyle(color: r.silik, fontSize: 13)),
        ],
      ),
    );
  }
}

/// Saniyeyi kısa süreye çevirir (sn / dk / sa / gün).
String yasYaz(int sn) => sn < 60
    ? '$sn sn'
    : sn < 3600
    ? '${sn ~/ 60} dk'
    : sn < 86400
    ? '${sn ~/ 3600} sa'
    : '${sn ~/ 86400} gün';

/// Tablo başlık satırı (geniş ekran listeleri).
class TabloBasi extends StatelessWidget {
  const TabloBasi(this.sutunlar, {super.key});
  final List<(String, int)> sutunlar;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: r.zemin.withValues(alpha: .6),
        border: Border(bottom: BorderSide(color: r.kenar)),
      ),
      child: Row(
        children: [
          for (final (ad, f) in sutunlar)
            Expanded(
              flex: f,
              child: Text(
                ad,
                style: TextStyle(color: r.silik, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: .3),
              ),
            ),
        ],
      ),
    );
  }
}
