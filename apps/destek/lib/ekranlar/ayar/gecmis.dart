import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/parcalar.dart';
import '../../ortak/simgeler.dart';
import '../../ortak/yardimci.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import '../kabuk.dart';
import 'ortak.dart';

/// Geçmiş sohbetler: tarih aralığı, durum, metin, personel, bölüm, e-posta/telefon/IP, puan süzgeçleri; sayfalama.
class GecmisEkrani extends StatefulWidget {
  const GecmisEkrani({super.key});
  @override
  State<GecmisEkrani> createState() => _GecmisEkraniState();
}

class _GecmisEkraniState extends State<GecmisEkrani> {
  final _q = TextEditingController(), _eposta = TextEditingController(), _ip = TextEditingController();
  String? _durum, _puan;
  int? _temsilci, _bolum;
  DateTime? _bas, _bit;
  int _sayfa = 1, _anahtar = 0;
  bool _suzgecAcik = false;

  @override
  void initState() {
    super.initState();
    _sorguAl();
    gecmisSorgusu.addListener(_sorguAl);
  }

  @override
  void dispose() {
    gecmisSorgusu.removeListener(_sorguAl);
    super.dispose();
  }

  /// Üst çubuktaki genel aramadan gelen metin.
  void _sorguAl() {
    final q = gecmisSorgusu.value;
    if (q == null) return;
    gecmisSorgusu.value = null;
    _q.text = q;
    _sayfa = 1;
    if (mounted) _yenile();
  }

  String _t(DateTime? d) => d == null ? '' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> get _sorgu => {
    'page': _sayfa,
    if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(),
    if (_eposta.text.trim().isNotEmpty) 'email': _eposta.text.trim(),
    if (_ip.text.trim().isNotEmpty) 'ip': _ip.text.trim(),
    'status': ?_durum,
    'rating': ?_puan,
    'agent_id': ?_temsilci,
    'department_id': ?_bolum,
    if (_bas != null) 'from': _t(_bas),
    if (_bit != null) 'to': _t(_bit),
  };

  void _yenile() => setState(() => _anahtar++);

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      key: ValueKey(_anahtar),
      baslik: 'Geçmiş sohbetler',
      yukle: () => Panel.gecmis(_sorgu),
      eylemler: [
        IconButton(
          tooltip: 'Süzgeçler',
          icon: Icon(Simgeler.funnel, color: _suzgecAcik ? r.vurgu : null),
          onPressed: () => setState(() => _suzgecAcik = !_suzgecAcik),
        ),
      ],
      govde: (context, v, yenile) {
        final convs = harita(v['convs']);
        final l = haritalar(convs['data']);
        final ozet = harita(v['summary']);
        final temsilciler = haritalar(v['agents']);
        final bolumler = haritalar(v['departments']);
        final sonSayfa = tamsayi(convs['last_page'], 1);
        return ListView(
          children: [
            EsitIzgara(
              enAz: 150,
              yukseklik: 66,
              children: [
                _kart('Toplam', '${tamsayi(ozet['total'])}', Marka.mor, r, alt: 'tüm zamanlar'),
                _kart('Kapalı', '${tamsayi(ozet['closed'])}', Marka.zumrut, r),
                _kart('Bu ay', '${tamsayi(ozet['month'])}', Marka.mavi, r),
                _kart('Ort. puan', ondalik(ozet['avg_rating']).toStringAsFixed(1), Marka.kehribar, r, alt: '/ 5'),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _q,
              decoration: InputDecoration(
                hintText: 'Mesaj metni, ad, konu…',
                prefixIcon: const Icon(Simgeler.search, size: 18),
                suffixIcon: IconButton(icon: const Icon(Simgeler.arrowForward, size: 18), onPressed: _yenile),
              ),
              onSubmitted: (_) => _yenile(),
            ),
            if (_suzgecAcik)
              Kutu(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now(),
                                initialDate: _bas ?? DateTime.now(),
                              );
                              if (d != null) setState(() => _bas = d);
                            },
                            icon: const Icon(Simgeler.calendarToday, size: 16),
                            label: Text(_bas == null ? 'Başlangıç' : _t(_bas)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now(),
                                initialDate: _bit ?? DateTime.now(),
                              );
                              if (d != null) setState(() => _bit = d);
                            },
                            icon: const Icon(Simgeler.calendarToday, size: 16),
                            label: Text(_bit == null ? 'Bitiş' : _t(_bit)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    secim<String?>('Durum', _durum, const [
                      (null, 'Tümü'),
                      ('open', 'Açık'),
                      ('pending', 'Bekleyen'),
                      ('closed', 'Kapalı'),
                      ('offline', 'Çevrimdışı'),
                    ], (x) => setState(() => _durum = x)),
                    secim<int?>('Personel', _temsilci, [
                      (null, 'Tümü'),
                      for (final a in temsilciler) (tamsayi(a['id']), metin(a['alias'] ?? a['name'], metin(a['name']))),
                    ], (x) => setState(() => _temsilci = x)),
                    secim<int?>('Bölüm', _bolum, [
                      (null, 'Tümü'),
                      for (final b in bolumler) (tamsayi(b['id']), metin(b['name'])),
                    ], (x) => setState(() => _bolum = x)),
                    secim<String?>('Puan', _puan, const [
                      (null, 'Tümü'),
                      ('5', '5 ★'),
                      ('4', '4 ★'),
                      ('3', '3 ★'),
                      ('2', '2 ★'),
                      ('1', '1 ★'),
                      ('rated', 'Puanlananlar'),
                      ('unrated', 'Puansızlar'),
                    ], (x) => setState(() => _puan = x)),
                    alan('E-posta / telefon', _eposta),
                    alan('IP', _ip),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _q.clear();
                            _eposta.clear();
                            _ip.clear();
                            _durum = _puan = null;
                            _temsilci = _bolum = null;
                            _bas = _bit = null;
                            _sayfa = 1;
                            _yenile();
                          },
                          child: const Text('Temizle'),
                        ),
                        FilledButton(
                          onPressed: () {
                            _sayfa = 1;
                            _yenile();
                          },
                          child: const Text('Uygula'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text('${tamsayi(convs['total'])} sonuç · sayfa $_sayfa / $sonSayfa', style: TextStyle(color: r.silik, fontSize: 12)),
            const SizedBox(height: 6),
            if (l.isEmpty) Durum.bos('Eşleşen sohbet yok.', ikon: Simgeler.history),
            for (final c in l) _satir(c, r),
            if (sonSayfa > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: _sayfa > 1
                          ? () {
                              _sayfa--;
                              _yenile();
                            }
                          : null,
                      child: const Text('Önceki'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _sayfa < sonSayfa
                          ? () {
                              _sayfa++;
                              _yenile();
                            }
                          : null,
                      child: const Text('Sonraki'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _satir(Map<String, dynamic> c, Renkler r) {
    final meta = harita(c['meta']);
    final ad = metin(meta['name'], metin(harita(c['visitor'])['name'], 'Ziyaretçi'));
    final durum = metin(c['status']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Kutu(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        onTap: () => sohbetIstegi.value = tamsayi(c['id']),
        child: Row(
          children: [
            Avatar(ad, boyut: 38, tohum: metin(meta['email'], ad)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${tamsayi(c['id'])} · $ad',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 13.5),
                        ),
                      ),
                      Rozet(switch (durum) {
                        'open' => 'Açık',
                        'pending' => 'Bekliyor',
                        'closed' => 'Kapalı',
                        'offline' => 'Çevrimdışı',
                        _ => durum,
                      }, renk: durumRengi(durum)),
                    ],
                  ),
                  if (metinYa(c['subject']) != null || metinYa(meta['subject']) != null)
                    Text(
                      metin(c['subject'], metin(meta['subject'])),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: r.soluk, fontSize: 12.5),
                    ),
                  Text(
                    '${tamZaman(tarihOku(c['started_at']))} · ${tamsayi(c['messages_count'])} mesaj${c['rating'] != null ? ' · ★ ${c['rating']}' : ''}${c['first_response_seconds'] != null ? ' · ilk yanıt ${tamsayi(c['first_response_seconds'])} sn' : ''}',
                    style: TextStyle(color: r.silik, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(Simgeler.chevronRight, color: r.silik),
          ],
        ),
      ),
    );
  }

  Widget _kart(String ad, String deger, Color renk, Renkler r, {String? alt}) =>
      KpiKart(kucuk: true, etiket: ad, deger: deger, ikon: Simgeler.history, renk: renk, alt: alt);
}
