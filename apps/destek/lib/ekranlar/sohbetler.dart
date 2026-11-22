import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'gorusme.dart';

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

  Future<void> _yukle({bool sessiz = false, bool daha = false}) async {
    if (_yukleniyor) return;
    _yukleniyor = true;
    try {
      final sayfa = daha ? _sayfa + 1 : 1;
      final v = await Depo.sohbetler(durum: _durum, sayfa: sayfa);
      if (!mounted) return;
      setState(() {
        _liste = daha ? [...?_liste, ...v.sohbetler] : v.sohbetler;
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
      return Scaffold(
        appBar: AppBar(title: const Text('Sohbetler')),
        body: const Yetkisiz('Sohbetleri görüntülemek'),
      );
    }
    final liste = Scaffold(
      appBar: AppBar(
        title: const Text('Sohbetler'),
        actions: [
          if (_durum == 'missed' && (_sayilar['missed'] ?? 0) > 0 && Uyg.yetki('chats.reply'))
            TextButton(onPressed: _hepsiniCoz, child: const Text('Hepsini kapalıya al')),
          IconButton(tooltip: 'Yenile', onPressed: () => _yukle(), icon: const Icon(Simgeler.refresh)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: TextField(
                  controller: _arama,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Ziyaretçi, e-posta, mesaj ya da #numara',
                    prefixIcon: const Icon(Simgeler.search, size: 18),
                    isDense: true,
                    suffixIcon: _arama.text.isEmpty ? null : IconButton(icon: const Icon(Simgeler.close, size: 16), onPressed: () => setState(_arama.clear)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (k, ad) in _sekmeler)
                      ChoiceChip(
                        selected: _durum == k,
                        onSelected: (_) => _sekme(k),
                        visualDensity: VisualDensity.compact,
                        avatar: _durum == k ? null : Nokta(durumRengi(k), boyut: 8),
                        label: Text('$ad${(_sayilar[k] ?? 0) > 0 ? ' · ${_sayilar[k]}' : ''}'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _hata != null
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
    );
    if (!context.genis) return liste;
    return Row(
      children: [
        SizedBox(
          width: 380,
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
              : GorusmeEkrani(key: ValueKey(secilenSohbet.value), sohbetId: secilenSohbet.value!, gomulu: true),
        ),
      ],
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
