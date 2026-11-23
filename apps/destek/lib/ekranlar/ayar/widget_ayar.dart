import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Widget ayarları: başlık, alt başlık, karşılama, renk, konum, izinli alan adları, önizleme (sneak peek),
/// arama, başlatıcı etiketi/boyutu, başlık stili, köşe, marka gizleme, balon sesi. Canlı önizleme kartı.
class WidgetAyarEkrani extends StatefulWidget {
  const WidgetAyarEkrani({super.key});
  @override
  State<WidgetAyarEkrani> createState() => _WidgetAyarEkraniState();
}

class _WidgetAyarEkraniState extends State<WidgetAyarEkrani> {
  final _baslik = TextEditingController(),
      _alt = TextEditingController(),
      _hos = TextEditingController(),
      _renk = TextEditingController(),
      _alanlar = TextEditingController(),
      _avatar = TextEditingController(),
      _etiket = TextEditingController(),
      _boyut = TextEditingController();
  String _konum = 'right', _baslikStil = 'solid', _kose = 'round';
  bool _sneak = true, _arama = true, _markaGizle = false, _ses = true, _dolu = false, _mesgul = false;

  Future<Map<String, dynamic>> _yukle() async {
    final v = await Panel.widgetAyar();
    if (!_dolu) {
      final s = harita(v['site']);
      final w = harita(s['widget']);
      _baslik.text = metin(w['title']);
      _alt.text = metin(w['subtitle']);
      _hos.text = metin(w['welcome']);
      _renk.text = metin(w['color'], '#5443d2');
      _alanlar.text = metinler(s['allowed_domains']).join('\n');
      _avatar.text = metin(w['avatar']);
      _etiket.text = metin(w['launcher_label']);
      _boyut.text = '${tamsayi(w['launcher_size'], 52)}';
      _konum = metin(w['position'], 'right');
      _baslikStil = metin(w['header_style'], 'solid');
      _kose = metin(w['corner'], 'round');
      _sneak = mantik(s['sneak_peek'], true);
      _arama = mantik(w['call_enabled'], true);
      _markaGizle = mantik(w['hide_branding']);
      _ses = mantik(w['bubble_sound'], true);
      _dolu = true;
    }
    return v;
  }

  Future<void> _kaydet() async {
    setState(() => _mesgul = true);
    await kaydet(
      () => Panel.widgetKaydet({
        'title': _baslik.text.trim(),
        'subtitle': _alt.text.trim(),
        'welcome': _hos.text.trim(),
        'color': _renk.text.trim(),
        'position': _konum,
        'allowed_domains': _alanlar.text,
        'sneak_peek': _sneak ? 1 : 0,
        'call_enabled': _arama ? 1 : 0,
        'avatar': _avatar.text.trim(),
        'launcher_label': _etiket.text.trim(),
        'launcher_size': int.tryParse(_boyut.text) ?? 52,
        'header_style': _baslikStil,
        'corner': _kose,
        'hide_branding': _markaGizle ? 1 : 0,
        'bubble_sound': _ses ? 1 : 0,
      }),
    );
    if (mounted) setState(() => _mesgul = false);
  }

  Color get _rengi {
    final h = _renk.text.trim().replaceFirst('#', '');
    return h.length == 6 ? Color(int.tryParse('FF$h', radix: 16) ?? 0xFF5443D2) : Marka.mor;
  }

  static const _hazirRenkler = ['#5443d2', '#2563eb', '#0ea5e9', '#059669', '#16a34a', '#f59e0b', '#ef4444', '#db2777', '#7c3aed', '#0f172a'];

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Widget',
      yukle: _yukle,
      altBar: KaydetSeridi(mesgul: _mesgul, onKaydet: _kaydet),
      govde: (context, v, yenile) => LayoutBuilder(
        builder: (_, k) {
          final ikiSutun = k.maxWidth >= 860;
          final form = _form(r);
          if (!ikiSutun) {
            return ListView(children: [const Baslik('Önizleme'), _onizlemeKutusu(r), ...form]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ListView(children: form)),
              const SizedBox(width: 20),
              SizedBox(
                width: 360,
                child: ListView(
                  children: [
                    const Baslik('Canlı önizleme'),
                    _onizlemeKutusu(r),
                    const SizedBox(height: 10),
                    Text('Önizleme yazdıkça güncellenir; siteye yansıması için Kaydet\'e basın.', style: TextStyle(color: r.silik, fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _form(Renkler r) => [
    const Baslik('Metinler'),
    Kutu(
      child: Column(
        children: [
          alan('Başlık', _baslik),
          alan('Alt başlık', _alt),
          alan('Karşılama mesajı', _hos, satir: 3),
          alan('Başlatıcı etiketi', _etiket, ipucu: 'Boşsa yalnız simge'),
        ],
      ),
    ),
    const Baslik('Görünüm'),
    Kutu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: alan('Ana renk (hex)', _renk, ipucu: '#5443d2')),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _rengi,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: r.kenar),
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in _hazirRenkler)
                InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => setState(() => _renk.text = h),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(int.parse('FF${h.substring(1)}', radix: 16)),
                      shape: BoxShape.circle,
                      border: Border.all(color: _renk.text.toLowerCase() == h ? r.metin : Colors.transparent, width: 2.5),
                    ),
                    child: _renk.text.toLowerCase() == h ? const Icon(Simgeler.check, size: 16, color: Colors.white) : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _secenek(
            'Konum',
            r,
            [('right', 'Sağ alt', Simgeler.chevronRight), ('left', 'Sol alt', Simgeler.chevronLeft)],
            _konum,
            (x) => setState(() => _konum = x),
          ),
          _secenek(
            'Başlık stili',
            r,
            [('solid', 'Düz renk', Simgeler.category), ('gradient', 'Degrade', Simgeler.palette)],
            _baslikStil,
            (x) => setState(() => _baslikStil = x),
          ),
          _secenek(
            'Köşeler',
            r,
            [('round', 'Yuvarlak', Simgeler.radioButtonOff), ('sharp', 'Keskin', Simgeler.category)],
            _kose,
            (x) => setState(() => _kose = x),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: alan('Başlatıcı boyutu (px)', _boyut, tur: TextInputType.number, alt: '48–80'),
              ),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: alan('Avatar görseli (URL)', _avatar, ipucu: 'https://…/avatar.png')),
            ],
          ),
        ],
      ),
    ),
    const Baslik('Davranış'),
    Kutu(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          anahtar(
            'Yazarken önizleme (sneak peek)',
            _sneak,
            (x) => setState(() => _sneak = x),
            alt: 'Ziyaretçi göndermeden yazdığını görün',
            ikon: Simgeler.visibility,
          ),
          anahtar('Sesli/görüntülü arama', _arama, (x) => setState(() => _arama = x), alt: 'Widget\'ta arama kabul edilebilsin', ikon: Simgeler.videocam),
          anahtar('Balon sesi', _ses, (x) => setState(() => _ses = x), alt: 'Ziyaretçi tarafında yeni mesaj sesi', ikon: Simgeler.speaker),
          anahtar('Markayı gizle', _markaGizle, (x) => setState(() => _markaGizle = x), ikon: Simgeler.visibilityOff),
        ],
      ),
    ),
    const Baslik('İzinli alan adları'),
    Kutu(
      child: alan('Alan adları', _alanlar, satir: 3, ipucu: 'bogahost.com', alt: 'Her satıra bir alan adı; widget yalnız bunlarda çalışır'),
    ),
  ];

  /// Etiket + SegmentedButton satırı.
  Widget _secenek(String ad, Renkler r, List<(String, String, IconData)> secenekler, String deger, ValueChanged<String> onSec) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            ad,
            style: TextStyle(color: r.soluk, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [for (final (k, etiket, ikon) in secenekler) ButtonSegment(value: k, label: Text(etiket), icon: Icon(ikon, size: 16))],
            selected: {deger},
            onSelectionChanged: (s) => onSec(s.first),
          ),
        ),
      ],
    ),
  );

  Widget _onizlemeKutusu(Renkler r) => Kutu(
    padding: const EdgeInsets.all(14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [r.zemin, r.koyu ? Colors.black.withValues(alpha: .25) : const Color(0xFFEEF0F6)],
        ),
        border: Border.all(color: r.kenar),
      ),
      child: Align(
        alignment: _konum == 'left' ? Alignment.centerLeft : Alignment.centerRight,
        child: Column(
          crossAxisAlignment: _konum == 'left' ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: r.kart,
                borderRadius: BorderRadius.circular(_kose == 'sharp' ? 6 : 16),
                border: Border.all(color: r.kenar),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 14, offset: const Offset(0, 6))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _baslikStil == 'gradient' ? LinearGradient(colors: [_rengi, _rengi.withValues(alpha: .7)]) : null,
                      color: _baslikStil == 'gradient' ? null : _rengi,
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white24,
                          child: Icon(Simgeler.chatDots, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _baslik.text.isEmpty ? 'Başlık' : _baslik.text,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                _alt.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: r.zemin, borderRadius: BorderRadius.circular(10)),
                      child: Text(_hos.text.isEmpty ? 'Karşılama mesajı' : _hos.text, style: TextStyle(fontSize: 12, color: r.metin)),
                    ),
                  ),
                  if (!_markaGizle)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                      child: Text('Bogahost Chat ile', style: TextStyle(fontSize: 10, color: r.silik)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: (double.tryParse(_boyut.text) ?? 52).clamp(48, 80),
              padding: EdgeInsets.symmetric(horizontal: _etiket.text.isEmpty ? 0 : 16),
              constraints: BoxConstraints(minWidth: (double.tryParse(_boyut.text) ?? 52).clamp(48, 80)),
              decoration: BoxDecoration(
                color: _rengi,
                borderRadius: BorderRadius.circular(99),
                boxShadow: [BoxShadow(color: _rengi.withValues(alpha: .35), blurRadius: 12, offset: const Offset(0, 5))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Simgeler.chatDots, color: Colors.white, size: 22),
                  if (_etiket.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      _etiket.text,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
