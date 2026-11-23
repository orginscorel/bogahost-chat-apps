import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/parcalar.dart';
import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import '../kabuk.dart';
import 'ortak.dart';

/// Yapay zeka asistanı (dış servis kullanmayan, kendi kendine öğrenen iç motor): 30 günlük özet, ayarlar
/// (kip, eşikler, öğrenme), bilgi tabanı, onay bekleyen öğrenilmiş yanıtlar, günlük ve deneme. settings.manage ister.
class YapayZekaEkrani extends StatefulWidget {
  const YapayZekaEkrani({super.key});
  @override
  State<YapayZekaEkrani> createState() => _YapayZekaEkraniState();
}

class _YapayZekaEkraniState extends State<YapayZekaEkrani> {
  String _bolum = 'egitim';

  static String _oran(int a, int b) => a + b == 0 ? '–' : '%${(a * 100 / (a + b)).round()}';

  @override
  Widget build(BuildContext context) {
    return AyarSayfa(
      baslik: 'Yapay zeka asistanı',
      yukle: Panel.ai,
      govde: (context, v, yenile) {
        final o = harita(v['summary']);
        final bekleyen = tamsayi(o['knowledge_pending']);
        final botAdi = metin(harita(v['config'])['name'], 'Butoi');
        final bolumler = [
          ('egitim', "$botAdi'yi eğit", Simgeler.chatText),
          ('ayarlar', 'Ayarlar', Simgeler.tune),
          ('bilgi', 'Bilgi tabanı', Simgeler.lightbulbOutline),
          ('onay', 'Onay bekleyen ($bekleyen)', Simgeler.pending),
          ('gunluk', 'Günlük', Simgeler.history),
          ('deneme', 'Deneme', Simgeler.science),
        ];
        return ListView(
          children: [
            const SizedBox(height: 8),
            EsitIzgara(
              enAz: 170,
              yukseklik: 72,
              children: [
                KpiKart(
                  kucuk: true,
                  etiket: 'Aktif bilgi',
                  deger: sayiYaz(tamsayi(o['knowledge_active'])),
                  ikon: Simgeler.lightbulbOutline,
                  renk: Marka.mor,
                  onTap: () => setState(() => _bolum = 'bilgi'),
                ),
                KpiKart(
                  kucuk: true,
                  etiket: 'Onay bekleyen',
                  deger: sayiYaz(bekleyen),
                  ikon: Simgeler.pending,
                  renk: Marka.kehribar,
                  onTap: () => setState(() => _bolum = 'onay'),
                ),
                KpiKart(
                  kucuk: true,
                  etiket: '30g çağrı',
                  alt: tamsayi(o['errors_30d']) > 0 ? '${tamsayi(o['errors_30d'])} hata' : null,
                  deger: sayiYaz(tamsayi(o['calls_30d'])),
                  ikon: Simgeler.sparkle,
                  renk: Marka.indigo,
                  onTap: () => setState(() => _bolum = 'gunluk'),
                ),
                KpiKart(
                  kucuk: true,
                  etiket: 'Otomatik yanıt',
                  alt: '${tamsayi(o['handoff_30d'])} devir',
                  deger: sayiYaz(tamsayi(o['auto_30d'])),
                  ikon: Simgeler.bolt,
                  renk: Marka.zumrut,
                ),
                KpiKart(
                  kucuk: true,
                  etiket: 'Öneri kabul',
                  alt: '${tamsayi(o['suggest_30d'])} öneri',
                  deger: _oran(tamsayi(o['suggest_sent_30d']), tamsayi(o['suggest_edited_30d'])),
                  ikon: Simgeler.checkCircle,
                  renk: Marka.mavi,
                ),
                KpiKart(
                  kucuk: true,
                  etiket: 'Öğrenilen (etkin)',
                  alt: tamsayi(o['learned_30d']) > 0 ? '30g +${tamsayi(o['learned_30d'])}' : null,
                  deger: sayiYaz(tamsayi(o['knowledge_learned'])),
                  ikon: Simgeler.autoFixHigh,
                  renk: Marka.zumrut,
                  onTap: () => setState(() => _bolum = 'bilgi'),
                ),
                KpiKart(
                  kucuk: true,
                  etiket: 'Sistem bilgisi',
                  alt: 'ürün, fiyat, alan adı, bilgi bankası',
                  deger: sayiYaz(tamsayi(o['knowledge_system'])),
                  ikon: Simgeler.storage,
                  renk: Marka.mavi,
                  onTap: () => setState(() => _bolum = 'bilgi'),
                ),
                KpiKart(kucuk: true, etiket: 'Hazır cevaplar', deger: sayiYaz(tamsayi(o['canned'])), ikon: Simgeler.forum, renk: Marka.indigo),
                KpiKart(
                  kucuk: true,
                  etiket: 'Ortalama eşleşme',
                  deger: tamsayi(o['calls_30d']) == 0 ? '–' : '%${tamsayi(o['avg_score_30d'])}',
                  ikon: Simgeler.speed,
                  renk: Marka.grafitAcik,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (k, ad, ikon) in bolumler)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(ikon, size: 16, color: k == 'onay' && bekleyen > 0 ? Marka.kehribar : null),
                        label: Text(ad),
                        selected: _bolum == k,
                        onSelected: (_) => setState(() => _bolum = k),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            switch (_bolum) {
              'egitim' => _Egitim(key: const ValueKey('egitim'), botAdi: botAdi, yenile: yenile),
              'bilgi' => _BilgiTabani(key: const ValueKey('bilgi'), tazele: v, yenile: yenile),
              'onay' => _OnayBekleyen(key: const ValueKey('onay'), tazele: v, yenile: yenile),
              'gunluk' => _Gunluk(key: const ValueKey('gunluk'), tazele: v),
              'deneme' => const _Deneme(key: ValueKey('deneme')),
              _ => _AyarFormu(key: const ValueKey('ayarlar'), v: v, yenile: yenile),
            },
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------- Ayarlar

class _AyarFormu extends StatefulWidget {
  const _AyarFormu({super.key, required this.v, required this.yenile});
  final Map<String, dynamic> v;
  final VoidCallback yenile;
  @override
  State<_AyarFormu> createState() => _AyarFormuState();
}

class _AyarFormuState extends State<_AyarFormu> {
  late final Map<String, dynamic> _c = harita(widget.v['config']);
  late bool _etkin = mantik(_c['enabled']);
  late bool _ogren = mantik(_c['learn']);
  late bool _otoOgren = mantik(_c['auto_learn']);
  late bool _sistemSenkron = mantik(_c['sync_system']);
  bool _senkronluyor = false;
  late String _kip = metin(_c['mode'], 'suggest');
  late double _oneriEsik = tamsayi(_c['suggest_threshold'], 35).clamp(5, 100).toDouble();
  late double _otoEsik = tamsayi(_c['auto_threshold'], 70).clamp(5, 100).toDouble();
  late final _ad = TextEditingController(text: metin(_c['name']));
  late final _devir = TextEditingController(text: _c['handoff_words'] is List ? metinler(_c['handoff_words']).join(', ') : metin(_c['handoff_words']));
  late final _devirCumlesi = TextEditingController(text: metin(_c['fallback_text']));
  late final _tur = TextEditingController(text: '${tamsayi(_c['max_bot_turns'])}');
  late final _tekrar = TextEditingController(text: '${tamsayi(_c['min_repeats'], 2)}');
  late final _karsilama = TextEditingController(text: metin(_c['greeting']));
  final _gun = TextEditingController(text: '365');
  final _enCok = TextEditingController(text: '1000');
  bool _mesgul = false;
  bool _ogreniyor = false;

  @override
  void dispose() {
    for (final c in [_ad, _devir, _devirCumlesi, _tur, _tekrar, _karsilama, _gun, _enCok]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _kaydet() async {
    setState(() => _mesgul = true);
    final ok = await kaydet(
      () => Panel.aiKaydet({
        'enabled': _etkin,
        'name': _ad.text.trim(),
        'mode': _kip,
        'learn': _ogren,
        'auto_learn': _otoOgren,
        'sync_system': _sistemSenkron,
        'min_repeats': int.tryParse(_tekrar.text.trim()) ?? 2,
        'suggest_threshold': _oneriEsik.round(),
        'auto_threshold': _otoEsik.round(),
        'handoff_words': _devir.text.trim(),
        'fallback_text': _devirCumlesi.text,
        'max_bot_turns': int.tryParse(_tur.text.trim()) ?? 0,
        'greeting': _karsilama.text,
      }),
    );
    if (!mounted) return;
    setState(() => _mesgul = false);
    if (ok) widget.yenile();
  }

  Future<void> _sistemdenGuncelle() async {
    if (_senkronluyor) return;
    setState(() => _senkronluyor = true);
    final v = await islem(Panel.aiSistemSenkron);
    if (!mounted) return;
    setState(() => _senkronluyor = false);
    if (v == null) return;
    if (!mantik(v['ok'])) {
      bildir(metin(v['error'], 'Senkron başarısız'), tur: MesajTur.hata);
      return;
    }
    bildir(
      '${sayiYaz(tamsayi(v['total']))} sistem kaydı: ${sayiYaz(tamsayi(v['created']))} yeni, ${sayiYaz(tamsayi(v['updated']))} güncellendi',
      tur: MesajTur.basari,
    );
    widget.yenile();
  }

  Future<void> _gecmistenOgren() async {
    if (_ogreniyor) return;
    setState(() => _ogreniyor = true);
    final v = await islem(() => Panel.aiGecmistenOgren(gun: int.tryParse(_gun.text.trim()) ?? 365, enCok: int.tryParse(_enCok.text.trim()) ?? 1000));
    if (!mounted) return;
    setState(() => _ogreniyor = false);
    if (v == null) return;
    bildir('${sayiYaz(tamsayi(v['conversations']))} görüşme tarandı, ${sayiYaz(tamsayi(v['pairs']))} çift öğrenildi', tur: MesajTur.basari);
    widget.yenile();
  }

  Widget _esik(String etiket, String alt, double deger, ValueChanged<double> onChanged) {
    final r = context.r;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(etiket, style: TextStyle(color: r.metin, fontSize: 13.5)),
              ),
              Text(
                '%${deger.round()}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Marka.mor),
              ),
            ],
          ),
          Slider(value: deger, min: 5, max: 100, divisions: 19, label: '%${deger.round()}', onChanged: onChanged),
          Text(alt, style: TextStyle(color: r.silik, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Asistan dış servis kullanmaz: WHMCS ürün/fiyat/alan adı/bilgi bankasını kendisi bilir, hazır cevaplardan eşleştirir, ekibin yanıtlarından, kapanan görüşmelerden ve eğitim sohbetinden öğrenir.',
            style: TextStyle(color: r.soluk, fontSize: 12.5),
          ),
        ),
        Kutu(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              anahtar('Asistan etkin', _etkin, (x) => setState(() => _etkin = x), alt: 'Kapalıyken öneri ve otomatik yanıt çalışmaz', ikon: Simgeler.sparkle),
              const SizedBox(height: 8),
              alan('Asistan adı', _ad, ipucu: 'Butoi'),
            ],
          ),
        ),
        const Baslik('Kip'),
        Kutu(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: RadioGroup<String>(
            groupValue: _kip,
            onChanged: (x) => x == null ? null : setState(() => _kip = x),
            child: Column(
              children: [
                for (final (k, ad, alt) in [
                  ('suggest', 'Yalnız öneri', 'Temsilciye bilgi tabanından yanıt önerir, ziyaretçiye yazmaz'),
                  ('offline', 'Temsilci yokken yanıtlar', 'Çevrimiçi temsilci ve atanmış sohbet yoksa, eşleşme otomatik eşiğin üstündeyse ziyaretçiye yazar'),
                  ('always', 'Her zaman yanıtlar', 'Temsilci devralana kadar, eşik üstü eşleşmelerde bot yanıtlar'),
                ])
                  RadioListTile<String>(
                    value: k,
                    dense: true,
                    title: Text(ad),
                    subtitle: Text(alt, style: TextStyle(color: r.silik, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
        const Baslik('Eşikler'),
        Kutu(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _esik('Öneri eşiği', 'Bu oranın altındaki eşleşmeler temsilciye önerilmez', _oneriEsik, (x) => setState(() => _oneriEsik = x)),
              const SizedBox(height: 6),
              _esik('Otomatik yanıt eşiği', 'Bot yalnız bu oranın üstündeki eşleşmelerde ziyaretçiye yazar', _otoEsik, (x) => setState(() => _otoEsik = x)),
            ],
          ),
        ),
        const Baslik('Davranış'),
        Kutu(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            children: [
              alan('Karşılama mesajı', _karsilama, satir: 2, alt: 'Bot sohbeti üstlendiğinde ilk mesaj (boş: yok)'),
              alan('Devir cümlesi', _devirCumlesi, satir: 2, alt: 'Eşleşme bulunamayınca ya da devirde ziyaretçiye yazılır'),
              alan('Devir kelimeleri', _devir, ipucu: 'temsilci, insan, yetkili', alt: 'Ziyaretçi bunlardan birini yazınca sohbet temsilciye devredilir'),
              alan('En çok bot turu', _tur, tur: TextInputType.number, alt: 'Bu kadar yanıttan sonra temsilciye devreder (0: sınırsız)'),
            ],
          ),
        ),
        const Baslik('Öğrenme'),
        Kutu(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            children: [
              anahtar(
                'Görüşmelerden öğren',
                _ogren,
                (x) => setState(() => _ogren = x),
                alt: 'Kapanan görüşmeler ve temsilci düzeltmelerinden soru → yanıt çiftleri çıkarır',
                ikon: Simgeler.lightbulbOutline,
              ),
              anahtar(
                'Öğrenilenleri onaysız etkinleştir',
                _otoOgren,
                (x) => setState(() => _otoOgren = x),
                alt: 'Kapalıysa onay bekler; aynı soru tekrar sayısı kadar görülürse kendiliğinden etkinleşir',
                ikon: Simgeler.autoFixHigh,
              ),
              const SizedBox(height: 8),
              alan('Tekrar sayısı', _tekrar, tur: TextInputType.number, alt: 'Öğrenilen yanıtın kendiliğinden etkinleşmesi için aynı sorunun görülme sayısı'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _mesgul ? null : _kaydet,
            icon: _mesgul ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Simgeler.save, size: 18),
            label: const Text('Kaydet'),
          ),
        ),
        const Baslik('Sistem bilgisi (WHMCS)'),
        Kutu(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              anahtar(
                'Gece senkronu',
                _sistemSenkron,
                (x) => setState(() => _sistemSenkron = x),
                alt: 'Her gece 05:15: ürün grupları, paket fiyat ve özellikleri, alan adı ücretleri, bilgi bankası, ödeme yöntemleri. Müşteri verisi okunmaz.',
                ikon: Simgeler.storage,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _senkronluyor ? null : _sistemdenGuncelle,
                  icon: _senkronluyor
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Simgeler.refresh, size: 18),
                  label: const Text('Sistemden şimdi güncelle'),
                ),
              ),
            ],
          ),
        ),
        const Baslik('Geçmişten öğren'),
        Kutu(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kapanmış eski görüşmeleri tarar ve ziyaretçi sorusu → temsilci yanıtı çiftlerini bilgi tabanına öğrenir.',
                style: TextStyle(color: r.soluk, fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: alan('Gün', _gun, tur: TextInputType.number, alt: 'Son kaç gün'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: alan('En çok', _enCok, tur: TextInputType.number, alt: 'Görüşme sayısı'),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _ogreniyor ? null : _gecmistenOgren,
                  icon: _ogreniyor
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Simgeler.history, size: 18),
                  label: const Text('Geçmişten öğren'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Ortak parçalar

String _turAdi(String t) => t == 'doc' ? 'Belge' : 'Soru-yanıt';

(String, Color) _kaynak(String s) => switch (s) {
  'learned' => ('Öğrenildi', Marka.zumrut),
  'feedback' => ('Düzeltme', Marka.kehribar),
  'system' => ('Sistem', Marka.indigo),
  _ => ('Elle', Marka.mavi),
};

String _agirlik(double w) => w.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');

Color _skorRengi(int s) => s >= 70 ? Marka.zumrut : (s >= 40 ? Marka.kehribar : Marka.gul);

String _etiketler(Object? v) => v is List ? metinler(v).join(', ') : metin(v);

/// Sayfa yenilendiğinde (`tazele` haritası değişince) kendi listesini de yeniden yükleyen bölüm iskeleti.
abstract class _ListeDurumu<T extends StatefulWidget> extends State<T> {
  List<Map<String, dynamic>>? ogeler;
  String? hata;

  Object? get tazele;
  Future<Map<String, dynamic>> getir();

  Object? _sonTazele;

  @override
  void initState() {
    super.initState();
    _sonTazele = tazele;
    yukle();
  }

  @override
  void didUpdateWidget(covariant T eski) {
    super.didUpdateWidget(eski);
    if (!identical(_sonTazele, tazele)) {
      _sonTazele = tazele;
      yukle();
    }
  }

  Future<void> yukle() async {
    try {
      final v = await getir();
      if (mounted) {
        setState(() {
          ogeler = haritalar(v['items']);
          hata = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => hata = hataMetni(e));
    }
  }

  Widget? durum() {
    if (hata != null) return Durum.hata(hata!, tekrar: yukle);
    if (ogeler == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return null;
  }
}

// ---------------------------------------------------------------- Bilgi tabanı

class _BilgiTabani extends StatefulWidget {
  const _BilgiTabani({super.key, required this.tazele, required this.yenile});
  final Object? tazele;
  final VoidCallback yenile;
  @override
  State<_BilgiTabani> createState() => _BilgiTabaniState();
}

class _BilgiTabaniState extends _ListeDurumu<_BilgiTabani> {
  final _ara = TextEditingController();
  String _durum = 'active';

  @override
  Object? get tazele => widget.tazele;

  @override
  Future<Map<String, dynamic>> getir() => Panel.aiBilgiler(durum: _durum, q: _ara.text.trim());

  @override
  void dispose() {
    _ara.dispose();
    super.dispose();
  }

  Future<void> _form({Map<String, dynamic>? x}) async {
    var tur = metin(x?['type'], 'qa');
    final baslik = TextEditingController(text: metin(x?['title'])),
        icerik = TextEditingController(text: metin(x?['content'])),
        etiket = TextEditingController(text: _etiketler(x?['tags']));
    final id = x == null ? 0 : tamsayi(x['id']);
    final aktif = metin(x?['status']) == 'active';
    var degisti = false;
    final ok = await formDiyalog(
      context,
      x == null ? 'Bilgi ekle' : 'Bilgiyi düzenle',
      alanlar: [
        secim<String>('Tür', tur, const [('qa', 'Soru-yanıt'), ('doc', 'Belge')], (v) => tur = v ?? 'qa'),
        alan('Başlık / soru', baslik),
        alan('İçerik / yanıt', icerik, satir: 6),
        alan('Etiketler', etiket, ipucu: 'fatura, alan adı, iade', alt: 'Virgülle ayırın'),
        if (x != null)
          Builder(
            builder: (dc) => Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    if (!await onayla(dc, 'Bilgi silinsin mi?', evet: 'Sil', tehlikeli: true)) return;
                    if (await kaydet(() => Panel.aiBilgiSil(id))) {
                      degisti = true;
                      if (dc.mounted) Navigator.pop(dc, false);
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Marka.gul),
                  icon: const Icon(Simgeler.deleteOutline, size: 18),
                  label: const Text('Sil'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    if (await kaydet(() => Panel.aiBilgiGuncelle(id, {'status': aktif ? 'rejected' : 'active'}))) {
                      degisti = true;
                      if (dc.mounted) Navigator.pop(dc, false);
                    }
                  },
                  icon: Icon(aktif ? Simgeler.toggleOff : Simgeler.toggleOn, size: 18),
                  label: Text(aktif ? 'Pasifleştir' : 'Etkinleştir'),
                ),
              ],
            ),
          ),
      ],
      kaydetF: () {
        final g = {'type': tur, 'title': baslik.text.trim(), 'content': icerik.text.trim(), 'tags': etiket.text.trim()};
        return x == null ? Panel.aiBilgiEkle(g) : Panel.aiBilgiGuncelle(id, g);
      },
    );
    if (ok || degisti) widget.yenile();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l = ogeler ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                controller: _ara,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => yukle(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Bilgi ara…',
                  prefixIcon: const Icon(Simgeler.search, size: 18),
                  suffixIcon: IconButton(tooltip: 'Ara', icon: const Icon(Simgeler.arrowForward, size: 18), onPressed: yukle),
                ),
              ),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'active', label: Text('Etkin')),
                ButtonSegment(value: 'rejected', label: Text('Pasif')),
                ButtonSegment(value: 'all', label: Text('Tümü')),
              ],
              selected: {_durum},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                setState(() => _durum = s.first);
                yukle();
              },
            ),
            FilledButton.icon(onPressed: _form, icon: const Icon(Simgeler.add, size: 18), label: const Text('Ekle')),
          ],
        ),
        const SizedBox(height: 12),
        ?durum(),
        if (ogeler != null && l.isEmpty) Durum.bos('Kayıt yok.', ikon: Simgeler.lightbulbOutline),
        for (final x in l)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Kutu(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              onTap: () => _form(x: x),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Rozet(_turAdi(metin(x['type'])), renk: Marka.mor),
                      const SizedBox(width: 6),
                      Rozet(_kaynak(metin(x['source'])).$1, renk: _kaynak(metin(x['source'])).$2),
                      if (metin(x['status']) != 'active') ...[
                        const SizedBox(width: 6),
                        Rozet(metin(x['status']) == 'pending' ? 'Onay bekliyor' : 'Pasif', renk: Marka.grafitAcik),
                      ],
                      if (ondalik(x['weight'], 1) != 1.0) ...[
                        const SizedBox(width: 6),
                        Rozet('×${_agirlik(ondalik(x['weight'], 1))}', renk: ondalik(x['weight'], 1) > 1 ? Marka.zumrut : Marka.kehribar),
                      ],
                      const Spacer(),
                      Flexible(
                        child: Text(
                          '${tamsayi(x['hits'])} kez görüldü · ${tamsayi(x['uses'])} kullanım · ${kisaZaman(tarihOku(x['created_at']))}',
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(color: r.silik, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    metin(x['title']),
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metin(x['content']),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: r.soluk, fontSize: 13),
                  ),
                  if (_etiketler(x['tags']).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_etiketler(x['tags']), style: TextStyle(color: r.silik, fontSize: 11.5)),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Onay bekleyen

class _OnayBekleyen extends StatefulWidget {
  const _OnayBekleyen({super.key, required this.tazele, required this.yenile});
  final Object? tazele;
  final VoidCallback yenile;
  @override
  State<_OnayBekleyen> createState() => _OnayBekleyenState();
}

class _OnayBekleyenState extends _ListeDurumu<_OnayBekleyen> {
  final _acik = <int>{};

  @override
  Object? get tazele => widget.tazele;

  @override
  Future<Map<String, dynamic>> getir() => Panel.aiBilgiler(durum: 'pending');

  Future<void> _incele(List<int> ids, String durum) async {
    if (ids.isEmpty) return;
    final ok = await kaydet(() => Panel.aiBilgiIncele(ids, durum), tamam: durum == 'active' ? 'Onaylandı' : 'Reddedildi');
    if (ok) widget.yenile();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l = ogeler ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Öğrenilmiş yanıtlar onaylanınca bilgi tabanına girer ve asistan kullanmaya başlar.',
                style: TextStyle(color: r.soluk, fontSize: 12.5),
              ),
            ),
            if (l.isNotEmpty)
              FilledButton.tonalIcon(
                onPressed: () async {
                  if (await onayla(context, 'Tümü onaylansın mı?', mesaj: '${l.length} öğrenilmiş yanıt bilgi tabanına eklenecek.', evet: 'Tümünü onayla')) {
                    await _incele([for (final x in l) tamsayi(x['id'])], 'active');
                  }
                },
                icon: const Icon(Simgeler.doneAll, size: 18),
                label: const Text('Tümünü onayla'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ?durum(),
        if (ogeler != null && l.isEmpty) Durum.bos('Onay bekleyen yanıt yok.', ikon: Simgeler.checkCircle),
        for (final x in l)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Kutu(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              onTap: () => setState(() => _acik.contains(tamsayi(x['id'])) ? _acik.remove(tamsayi(x['id'])) : _acik.add(tamsayi(x['id']))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Rozet(_kaynak(metin(x['source'])).$1, renk: _kaynak(metin(x['source'])).$2),
                      const SizedBox(width: 6),
                      if (tamsayi(x['conversation_id']) > 0)
                        InkWell(
                          onTap: () => sohbetIstegi.value = tamsayi(x['conversation_id']),
                          child: Text(
                            '#${tamsayi(x['conversation_id'])}',
                            style: const TextStyle(color: Marka.mavi, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const Spacer(),
                      Text(kisaZaman(tarihOku(x['created_at'])), style: TextStyle(color: r.silik, fontSize: 11.5)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    metin(x['title']),
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metin(x['content']),
                    maxLines: _acik.contains(tamsayi(x['id'])) ? null : 3,
                    overflow: _acik.contains(tamsayi(x['id'])) ? null : TextOverflow.ellipsis,
                    style: TextStyle(color: r.soluk, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _incele([tamsayi(x['id'])], 'rejected'),
                        style: TextButton.styleFrom(foregroundColor: Marka.gul),
                        icon: const Icon(Simgeler.cancel, size: 18),
                        label: const Text('Reddet'),
                      ),
                      const SizedBox(width: 4),
                      FilledButton.tonalIcon(
                        onPressed: () => _incele([tamsayi(x['id'])], 'active'),
                        icon: const Icon(Simgeler.check, size: 18),
                        label: const Text('Onayla'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Günlük

class _Gunluk extends StatefulWidget {
  const _Gunluk({super.key, required this.tazele});
  final Object? tazele;
  @override
  State<_Gunluk> createState() => _GunlukState();
}

class _GunlukState extends _ListeDurumu<_Gunluk> {
  final _acik = <int>{};

  @override
  Object? get tazele => widget.tazele;

  @override
  Future<Map<String, dynamic>> getir() => Panel.aiGunluk();

  static String _tur(String k) => switch (k) {
    'suggest' => 'Öneri',
    'auto' => 'Otomatik',
    'test' => 'Deneme',
    'train' => 'Eğitim',
    'learn' => 'Öğrenme',
    _ => k.isEmpty ? '–' : k,
  };

  static (String, Color) _sonuc(String s) => switch (s) {
    'sent' => ('Aynen gönderildi', Marka.zumrut),
    'edited' => ('Düzenlendi', Marka.kehribar),
    'replied' => ('Yanıtlandı', Marka.zumrut),
    'handoff' => ('Devredildi', Marka.mavi),
    'ignored' => ('Kullanılmadı', Marka.grafitAcik),
    _ => (s, Marka.grafitAcik),
  };

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l = ogeler ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?durum(),
        if (ogeler != null && l.isEmpty) Durum.bos('Henüz çağrı yok.', ikon: Simgeler.history),
        for (final x in l)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Kutu(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              onTap: () => setState(() => _acik.contains(tamsayi(x['id'])) ? _acik.remove(tamsayi(x['id'])) : _acik.add(tamsayi(x['id']))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(tamZaman(tarihOku(x['at'])), style: TextStyle(color: r.soluk, fontSize: 12)),
                      Rozet(_tur(metin(x['kind'])), renk: Marka.mor),
                      if (tamsayi(x['conversation_id']) > 0)
                        InkWell(
                          onTap: () => sohbetIstegi.value = tamsayi(x['conversation_id']),
                          child: Text(
                            '#${tamsayi(x['conversation_id'])}',
                            style: const TextStyle(color: Marka.mavi, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (tamsayiYa(x['score']) != null) Rozet('%${tamsayi(x['score'])}', renk: _skorRengi(tamsayi(x['score']))),
                      if (metinYa(x['outcome']) != null) Rozet(_sonuc(metin(x['outcome'])).$1, renk: _sonuc(metin(x['outcome'])).$2),
                      if (!mantik(x['ok'], true)) const Rozet('Hata', renk: Marka.gul),
                    ],
                  ),
                  if (metinYa(x['error']) != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(metin(x['error']), style: const TextStyle(color: Marka.gul, fontSize: 12)),
                    ),
                  if (_acik.contains(tamsayi(x['id']))) ...[
                    if (metinYa(x['question']) != null) ...[
                      const SizedBox(height: 8),
                      Text('Soru', style: TextStyle(color: r.silik, fontSize: 11.5)),
                      SelectableText(metin(x['question']), style: TextStyle(color: r.metin, fontSize: 13)),
                    ],
                    if (metinYa(x['answer']) != null) ...[
                      const SizedBox(height: 8),
                      Text('Yanıt', style: TextStyle(color: r.silik, fontSize: 11.5)),
                      SelectableText(metin(x['answer']), style: TextStyle(color: r.metin, fontSize: 13)),
                    ],
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Deneme

class _Deneme extends StatefulWidget {
  const _Deneme({super.key});
  @override
  State<_Deneme> createState() => _DenemeState();
}

class _DenemeState extends State<_Deneme> {
  final _soru = TextEditingController();
  bool _mesgul = false;
  Map<String, dynamic>? _sonuc;
  String? _hata;

  @override
  void dispose() {
    _soru.dispose();
    super.dispose();
  }

  Future<void> _sor() async {
    final q = _soru.text.trim();
    if (q.isEmpty || _mesgul) return;
    setState(() {
      _mesgul = true;
      _hata = null;
      _sonuc = null;
    });
    try {
      final v = await Panel.aiDene(q);
      if (!mounted) return;
      setState(() {
        _sonuc = v;
        _hata = metinYa(v['error']);
      });
    } catch (e) {
      if (mounted) setState(() => _hata = hataMetni(e));
    } finally {
      if (mounted) setState(() => _mesgul = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final s = _sonuc;
    final kaynaklar = haritalar(s?['sources']);
    final skor = tamsayiYa(s?['score']);
    final yanit = metinYa(s?['text']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ziyaretçi gibi bir soru yazın; asistan bilgi tabanı ve hazır cevaplardan eşleştirir (ziyaretçiye gitmez).',
          style: TextStyle(color: r.soluk, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _soru,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Soru', hintText: 'Alan adımı nasıl transfer ederim?', alignLabelWithHint: true),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _mesgul ? null : _sor,
            icon: _mesgul ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Simgeler.send, size: 18),
            label: const Text('Sor'),
          ),
        ),
        const SizedBox(height: 12),
        if (_hata != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(_hata!, style: const TextStyle(color: Marka.kehribar, fontSize: 13)),
          ),
        if (s != null && (skor != null || yanit != null || kaynaklar.isNotEmpty))
          Kutu(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (skor != null)
                      Text(
                        '%$skor eşleşme',
                        style: TextStyle(color: _skorRengi(skor), fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    if (mantik(s['auto'])) const Rozet('Otomatik yanıtlanır', renk: Marka.zumrut),
                    if (mantik(s['handoff'])) const Rozet('Temsilciye devredilir', renk: Marka.kehribar),
                  ],
                ),
                if (yanit != null) ...[const SizedBox(height: 10), SelectableText(yanit, style: TextStyle(color: r.metin, fontSize: 14, height: 1.4))],
                if (kaynaklar.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Kaynaklar', style: TextStyle(color: r.silik, fontSize: 11.5)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final k in kaynaklar)
                        Chip(
                          avatar: Icon(metin(k['kind']) == 'canned' ? Simgeler.forum : Simgeler.lightbulbOutline, size: 14),
                          label: Text(
                            '${metin(k['kind']) == 'canned' ? 'Hazır cevap' : 'Bilgi'} · ${metin(k['title'], '#${tamsayi(k['id'])}')} · %${tamsayi(k['score'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Eğitim sohbeti

/// Butoi ile sohbet ederek eğitme: soru sor → yanlışsa Düzelt (ya da "Doğrusu: …"), doğruysa Doğru; "Soru: … | Cevap: …" tek seferde öğretir.
class _Egitim extends StatefulWidget {
  const _Egitim({super.key, required this.botAdi, required this.yenile});
  final String botAdi;
  final VoidCallback yenile;
  @override
  State<_Egitim> createState() => _EgitimState();
}

class _EgitimState extends State<_Egitim> {
  final _metin = TextEditingController();
  final _duzelt = TextEditingController();
  final _kaydirma = ScrollController();
  List<Map<String, dynamic>> _mesajlar = [];
  bool _yukleniyor = true;
  bool _mesgul = false;
  int? _duzeltId;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _metin.dispose();
    _duzelt.dispose();
    _kaydirma.dispose();
    super.dispose();
  }

  void _sonaKaydir() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_kaydirma.hasClients) _kaydirma.jumpTo(_kaydirma.position.maxScrollExtent);
    });
  }

  Future<void> _yukle() async {
    final v = await islem(Panel.aiEgitim);
    if (!mounted) return;
    setState(() {
      _yukleniyor = false;
      if (v != null) _mesajlar = haritalar(v['messages']);
    });
    _sonaKaydir();
  }

  void _ekle(Map<String, dynamic>? v) {
    if (v == null) return;
    setState(() => _mesajlar = [..._mesajlar, ...haritalar(v['messages'])]);
    _sonaKaydir();
  }

  Future<void> _gonder() async {
    final t = _metin.text.trim();
    if (t.isEmpty || _mesgul) return;
    setState(() {
      _mesgul = true;
      _duzeltId = null;
    });
    _metin.clear();
    final v = await islem(() => Panel.aiEgitimMesaj(t));
    if (!mounted) return;
    setState(() => _mesgul = false);
    if (v == null) {
      _metin.text = t;
      return;
    }
    _ekle(v);
    widget.yenile();
  }

  Future<void> _ogret(Map<String, dynamic> m) async {
    final yanit = _duzelt.text.trim();
    if (yanit.isEmpty || _mesgul) return;
    setState(() => _mesgul = true);
    final v = await islem(() => Panel.aiEgitimOgret(metin(harita(m['meta'])['question']), yanit, logId: tamsayiYa(m['log_id'])));
    if (!mounted) return;
    setState(() {
      _mesgul = false;
      if (v != null && mantik(v['ok'])) _duzeltId = null;
    });
    _ekle(v);
    widget.yenile();
  }

  Future<void> _dogru(Map<String, dynamic> m) async {
    final v = await islem(() => Panel.aiEgitimOnayla(tamsayiYa(m['log_id'])));
    if (!mounted || v == null) return;
    setState(() => (m['meta'] as Map?)?['approved'] = true);
    _ekle(v);
  }

  Future<void> _temizle() async {
    final tamam = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sohbeti temizle'),
        content: const Text('Eğitim sohbeti silinsin mi? Öğretilen bilgiler silinmez.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Temizle')),
        ],
      ),
    );
    if (tamam != true) return;
    final v = await islem(Panel.aiEgitimTemizle);
    if (!mounted || v == null) return;
    setState(() => _mesajlar = []);
  }

  Widget _balon(BuildContext context, Map<String, dynamic> m) {
    final r = context.r;
    final kullanici = metin(m['role']) == 'user';
    final meta = harita(m['meta']);
    final soru = metinYa(meta['question']);
    final skor = tamsayi(meta['score']);
    final kaynaklar = haritalar(meta['sources']);
    final duzeltiliyor = _duzeltId == tamsayi(m['id']);
    final renkler = Theme.of(context).colorScheme;
    return Align(
      alignment: kullanici ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: kullanici ? Marka.mor : renkler.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(kullanici ? 16 : 4),
              bottomRight: Radius.circular(kullanici ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kullanici ? 'Siz' : widget.botAdi,
                style: TextStyle(color: kullanici ? Colors.white70 : r.silik, fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: .4),
              ),
              const SizedBox(height: 2),
              SelectableText(metin(m['text']), style: TextStyle(color: kullanici ? Colors.white : r.metin, fontSize: 14, height: 1.4)),
              if (!kullanici && soru != null && !mantik(meta['taught'])) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Rozet('%$skor eşleşme', renk: _skorRengi(skor)),
                    for (final k in kaynaklar.take(3)) Rozet('${metin(k['title'], '#${tamsayi(k['id'])}')} · %${tamsayi(k['score'])}', renk: Marka.grafitAcik),
                    if (mantik(meta['ok']) && meta['intent'] == null && !mantik(meta['approved']))
                      ActionChip(
                        avatar: const Icon(Simgeler.checkCircle, size: 16, color: Marka.zumrut),
                        label: const Text('Doğru'),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _dogru(m),
                      ),
                    if (mantik(meta['approved'])) const Rozet('Pekiştirildi', renk: Marka.zumrut, ikon: Simgeler.check),
                    if (!duzeltiliyor)
                      ActionChip(
                        avatar: const Icon(Simgeler.edit, size: 16),
                        label: const Text('Düzelt'),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() {
                          _duzeltId = tamsayi(m['id']);
                          _duzelt.text = mantik(meta['ok']) ? metin(m['text']) : '';
                        }),
                      ),
                  ],
                ),
              ],
              if (duzeltiliyor) ...[
                const SizedBox(height: 8),
                Text('Soru: $soru', style: TextStyle(color: r.soluk, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: _duzelt,
                  minLines: 2,
                  maxLines: 6,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Doğru yanıt',
                    hintText: '{name} ve {email} yer tutucuları kullanılabilir',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => setState(() => _duzeltId = null), child: const Text('Vazgeç')),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _mesgul ? null : () => _ogret(m),
                      icon: const Icon(Simgeler.autoFixHigh, size: 18),
                      label: const Text('Öğret'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Soru sorun; yanıt yanlışsa Düzelt (ya da "Doğrusu: …"), doğruysa Doğru. "Soru: … | Cevap: …" tek seferde öğretir. Öğretilenler hemen etkinleşir.',
                style: TextStyle(color: r.soluk, fontSize: 12.5),
              ),
            ),
            if (_mesajlar.isNotEmpty) IconButton(tooltip: 'Sohbeti temizle', onPressed: _temizle, icon: const Icon(Simgeler.deleteSweep, size: 20)),
          ],
        ),
        const SizedBox(height: 8),
        Kutu(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: SizedBox(
            height: 440,
            child: _yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : _mesajlar.isEmpty
                ? Durum.bos('Henüz konuşma yok. Örneğin: "com alan adı ne kadar?"', ikon: Simgeler.chatText)
                : ListView.builder(
                    controller: _kaydirma,
                    itemCount: _mesajlar.length + (_mesgul ? 1 : 0),
                    itemBuilder: (c, i) => i == _mesajlar.length
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('${widget.botAdi} yazıyor…', style: TextStyle(color: r.silik, fontSize: 12)),
                          )
                        : _balon(c, _mesajlar[i]),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _metin,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _gonder(),
                decoration: const InputDecoration(hintText: "Soru sorun ya da 'Doğrusu: …' ile öğretin"),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _mesgul ? null : _gonder,
              child: _mesgul ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Simgeler.send, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
