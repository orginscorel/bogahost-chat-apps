import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/parcalar.dart';
import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'ayar/yapay_zeka.dart';
import 'gorusme.dart';
import 'kabuk.dart';

/// Geniş ekranda sağ bölmede açık olan sohbet.
final secilenSohbet = ValueNotifier<int?>(null);

/// Sohbet listesi: durum sekmeleri, arama, 4 sn'de bir yenileme. Geniş ekranda sol liste + sağda görüşme.
class SohbetlerEkrani extends StatefulWidget {
  const SohbetlerEkrani({super.key});
  @override
  State<SohbetlerEkrani> createState() => _SohbetlerEkraniState();
}

class _SohbetlerEkraniState extends State<SohbetlerEkrani> {
  static const _sekmeler = [('open', 'Açık'), ('pending', 'Bekleyen'), ('missed', 'Kaçan'), ('offline', 'Çevrimdışı'), ('closed', 'Kapalı')];
  String _durum = 'open';
  List<Sohbet>? _liste;
  Map<String, int> _sayilar = {};
  bool _dahaVar = false;
  int _sayfa = 1;
  String? _hata;
  Timer? _sayac;
  final _arama = TextEditingController();
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    _yukle();
    _sayac = Timer.periodic(const Duration(seconds: 4), (_) => _yukle(sessiz: true));
    secilenSohbet.addListener(_secimDegisti);
  }

  @override
  void dispose() {
    _sayac?.cancel();
    _arama.dispose();
    secilenSohbet.removeListener(_secimDegisti);
    super.dispose();
  }

  void _secimDegisti() => setState(() {});

  static bool _ayniListe(List<Sohbet> a, List<Sohbet> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].imza != b[i].imza) return false;
    }
    return true;
  }

  static bool _ayniSayilar(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final e in b.entries) {
      if (a[e.key] != e.value) return false;
    }
    return true;
  }

  Future<void> _yukle({bool sessiz = false, bool daha = false}) async {
    if (_yukleniyor) return;
    _yukleniyor = true;
    try {
      final sayfa = daha ? _sayfa + 1 : 1;
      final v = await Depo.sohbetler(durum: _durum, sayfa: sayfa);
      if (!mounted) return;
      final yeni = daha ? [...?_liste, ...v.sohbetler] : v.sohbetler;
      // Sessiz yoklamada görünür hiçbir şey değişmediyse yeniden çizme (4 sn'de bir tüm liste yenilenmesin).
      final ayni =
          sessiz && !daha && _liste != null && _hata == null && _dahaVar == v.dahaVar && _ayniSayilar(_sayilar, v.sayilar) && _ayniListe(_liste!, yeni);
      if (ayni) return;
      setState(() {
        _liste = yeni;
        _sayilar = v.sayilar;
        _dahaVar = v.dahaVar;
        _sayfa = sayfa;
        _hata = null;
      });
    } catch (e) {
      if (mounted && !sessiz) setState(() => _hata = hataMetni(e));
    } finally {
      _yukleniyor = false;
    }
  }

  void _sekme(String d) {
    if (_durum == d) return;
    setState(() {
      _durum = d;
      _liste = null;
      _hata = null;
    });
    _yukle();
  }

  List<Sohbet> get _suzulmus {
    final q = _arama.text.trim().toLowerCase();
    final l = _liste ?? [];
    if (q.isEmpty) return l;
    return l
        .where(
          (s) =>
              s.ziyaretci.toLowerCase().contains(q) ||
              (s.eposta ?? '').toLowerCase().contains(q) ||
              (s.onizleme ?? '').toLowerCase().contains(q) ||
              '#${s.id}'.contains(q),
        )
        .toList();
  }

  void _ac(Sohbet s) {
    if (context.genis) {
      secilenSohbet.value = s.id;
    } else {
      Navigator.of(context).push(
        HizliRota(
          builder: (_) => GorusmeEkrani(sohbetId: s.id, ilk: s),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    if (!Uyg.yetki('chats.view')) {
      return Scaffold(appBar: ekranBasligi(context, 'Sohbetler'), body: const Yetkisiz('Sohbetleri görüntülemek'));
    }
    final gomulu = kabukGomulu(context);
    final kacanCoz = _durum == 'missed' && (_sayilar['missed'] ?? 0) > 0 && Uyg.yetki('chats.reply');
    Widget aramaKutusu() => TextField(
      controller: _arama,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Ziyaretçi, e-posta, mesaj ya da #numara',
        prefixIcon: const Icon(Simgeler.search, size: 18),
        isDense: true,
        suffixIcon: _arama.text.isEmpty ? null : IconButton(icon: const Icon(Simgeler.close, size: 16), onPressed: () => setState(_arama.clear)),
      ),
    );
    List<Widget> cipler() => [
      for (final (k, ad) in _sekmeler)
        ChoiceChip(
          selected: _durum == k,
          onSelected: (_) => _sekme(k),
          avatar: _durum == k ? null : Nokta(durumRengi(k), boyut: 8),
          label: Text('$ad${(_sayilar[k] ?? 0) > 0 ? ' · ${_sayilar[k]}' : ''}'),
        ),
      if (kacanCoz) TextButton.icon(onPressed: _hepsiniCoz, icon: const Icon(Simgeler.doneAll, size: 18), label: const Text('Hepsini kapalıya al')),
    ];
    // Telefon: AppBar altında yatay kayan şerit. Kabuk içinde: gövdenin üstünde sarılan çipler (hepsi görünür).
    final ustCubuk = PreferredSize(
      preferredSize: const Size.fromHeight(104),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 8), child: aramaKutusu()),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              children: [for (final c in cipler()) Padding(padding: const EdgeInsets.only(right: 6), child: c)],
            ),
          ),
        ],
      ),
    );
    final gomuluBas = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: aramaKutusu()),
              IconButton(tooltip: 'Yenile', onPressed: () => _yukle(), icon: const Icon(Simgeler.refresh)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: cipler()),
        ],
      ),
    );
    final liste = Scaffold(
      appBar: gomulu
          ? null
          : AppBar(
              title: const Text('Sohbetler'),
              actions: [
                if (kacanCoz) TextButton(onPressed: _hepsiniCoz, child: const Text('Hepsini kapalıya al')),
                IconButton(tooltip: 'Yenile', onPressed: () => _yukle(), icon: const Icon(Simgeler.refresh)),
                ...kabukEylemleri(context),
              ],
              bottom: ustCubuk,
            ),
      body: Column(
        children: [
          if (gomulu) gomuluBas,
          if (Uyg.yetki('settings.manage')) _butoiSatiri(r),
          Expanded(
            child: _hata != null
                ? Durum.hata(_hata!, tekrar: _yukle)
                : _liste == null
                ? const Durum.yukleniyor()
                : _suzulmus.isEmpty
                ? Durum.bos(_arama.text.isNotEmpty ? 'Aramayla eşleşen sohbet yok.' : 'Bu listede sohbet yok.', ikon: Simgeler.forum)
                : RefreshIndicator(
                    onRefresh: () => _yukle(),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _suzulmus.length + (_dahaVar && _arama.text.isEmpty ? 1 : 0),
                      separatorBuilder: (_, _) => Divider(height: 1, indent: 72, color: r.kenar.withValues(alpha: .6)),
                      itemBuilder: (_, i) {
                        if (i == _suzulmus.length) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: OutlinedButton(onPressed: () => _yukle(daha: true), child: const Text('Daha fazla yükle')),
                            ),
                          );
                        }
                        return _satir(_suzulmus[i], r);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
    if (!context.genis) return liste;
    return Row(
      children: [
        SizedBox(
          width: (MediaQuery.sizeOf(context).width * .28).clamp(340.0, 480.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: r.kenar)),
            ),
            child: liste,
          ),
        ),
        Expanded(
          child: secilenSohbet.value == null
              ? Scaffold(body: Durum.bos('Soldan bir sohbet seçin.', ikon: Simgeler.forum))
              : secilenSohbet.value == -1
              ? const ButoiSohbetEkrani(key: ValueKey('butoi'), gomulu: true)
              : GorusmeEkrani(key: ValueKey(secilenSohbet.value), sohbetId: secilenSohbet.value!, gomulu: true),
        ),
      ],
    );
  }

  /// Listenin tepesinde sabit "Butoi" girişi: yapay zeka asistanıyla eğitim sohbeti.
  Widget _butoiSatiri(Renkler r) {
    final secili = context.genis && secilenSohbet.value == -1;
    return Material(
      color: secili ? r.vurguYumusak : Marka.mor.withValues(alpha: .06),
      child: InkWell(
        onTap: () {
          if (context.genis) {
            secilenSohbet.value = -1;
            setState(() {});
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ButoiSohbetEkrani()));
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            children: [
              Stack(
                children: [
                  const Avatar('Butoi', boyut: 44, tohum: 'butoi-asistan'),
                  Positioned(right: 0, bottom: 0, child: Nokta(Marka.mor, boyut: 13, halka: r.kart)),
                ],
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
                            'Butoi',
                            style: TextStyle(fontWeight: FontWeight.w700, color: r.metin, fontSize: 14.5),
                          ),
                        ),
                        const Rozet('Yapay zeka', renk: Marka.mor, ikon: Simgeler.sparkle),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Soru sor, düzelt, öğret — asistanı burada eğitin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: r.soluk, fontSize: 12.5),
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

  Widget _satir(Sohbet s, Renkler r) {
    final secili = context.genis && secilenSohbet.value == s.id;
    final okunmamis = s.okunmamis > 0;
    return Material(
      color: secili ? r.vurguYumusak : Colors.transparent,
      child: InkWell(
        onTap: () => _ac(s),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Avatar(s.ziyaretci, boyut: 44, tohum: s.eposta ?? s.ziyaretci),
                  Positioned(right: 0, bottom: 0, child: Nokta(s.cevrimici ? Marka.zumrut : const Color(0xFF94A3B8), boyut: 13, halka: r.kart)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (s.ulke != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(bayrak(s.ulke), style: const TextStyle(fontSize: 14)),
                          ),
                        Expanded(
                          child: Text(
                            s.ziyaretci,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: okunmamis ? FontWeight.w700 : FontWeight.w600, color: r.metin, fontSize: 14.5),
                          ),
                        ),
                        if (s.favori)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Simgeler.star, size: 14, color: Marka.kehribar),
                          ),
                        const SizedBox(width: 6),
                        Text(s.son, style: TextStyle(color: r.silik, fontSize: 11.5)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (s.yaziyor != null && s.yaziyor!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Simgeler.edit, size: 13, color: Marka.mor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              s.yaziyor!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Marka.mor, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        s.onizleme ?? '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: okunmamis ? r.metin : r.soluk, fontSize: 13, fontWeight: okunmamis ? FontWeight.w500 : FontWeight.w400),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Rozet(s.kacan ? 'Kaçan' : s.durumAdi, renk: durumRengi(s.kacan ? 'missed' : s.durum)),
                        if (s.temsilci != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              s.temsilci!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: r.silik, fontSize: 11.5),
                            ),
                          ),
                        ],
                        if (s.bolum != null) ...[const SizedBox(width: 6), Rozet(s.bolum!, renk: Marka.mavi)],
                        const Spacer(),
                        if (s.puan != null)
                          Row(
                            children: [
                              const Icon(Simgeler.star, size: 12, color: Marka.kehribar),
                              Text(' ${s.puan}', style: TextStyle(color: r.silik, fontSize: 11.5)),
                            ],
                          ),
                        if (okunmamis) Padding(padding: const EdgeInsets.only(left: 6), child: Sayac(s.okunmamis)),
                      ],
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

  Future<void> _hepsiniCoz() async {
    if (!await onayla(
      context,
      'Kaçan sohbetlerin hepsi kapalıya alınsın mı?',
      mesaj: 'Yanıtlanmamış ${_sayilar['missed']} sohbet "işlendi" olarak kapatılır.',
      evet: 'Kapalıya al',
    )) {
      return;
    }
    await islem(() => Uyg.api.post('${Uyg.apiKok}/chats-missed-resolve-all'), tamam: 'Kaçan sohbetler kapatıldı');
    _yukle();
  }
}
