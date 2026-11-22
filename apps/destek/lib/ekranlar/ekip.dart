import 'dart:async';
import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';

/// Dahili ekip sohbeti: kanal (herkes) + kişiye özel. Geniş ekranda kişi listesi + sohbet yan yana.
class EkipEkrani extends StatefulWidget {
  const EkipEkrani({super.key});
  @override
  State<EkipEkrani> createState() => _EkipEkraniState();
}

class _EkipEkraniState extends State<EkipEkrani> {
  List<Uye>? _kisiler;
  Map<String, int> _okunmamis = {};
  int _kisi = 0; // 0 = ekip kanalı
  String? _hata;
  Timer? _sayac;

  @override
  void initState() {
    super.initState();
    _yukle();
    _sayac = Timer.periodic(const Duration(seconds: 6), (_) => _yukle(sessiz: true));
  }

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  Future<void> _yukle({bool sessiz = false}) async {
    try {
      final v = await Depo.icKisiler();
      if (!mounted) return;
      setState(() {
        _kisiler = v.kisiler.where((u) => u.id != Uyg.benId).toList();
        _okunmamis = v.okunmamis;
        _hata = null;
      });
    } catch (e) {
      if (mounted && !sessiz) setState(() => _hata = hataMetni(e));
    }
  }

  void _ac(int kisi, String ad) {
    if (context.genis) {
      setState(() => _kisi = kisi);
    } else {
      Navigator.of(context).push(
        HizliRota(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(ad)),
            body: IcSohbet(kisi: kisi),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    if (!Uyg.yetki('internal.use')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ekip')),
        body: const Yetkisiz('Ekip sohbetini kullanmak'),
      );
    }
    final liste = Scaffold(
      appBar: AppBar(
        title: const Text('Ekip'),
        actions: [IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh))],
      ),
      body: _hata != null
          ? Durum.hata(_hata!, tekrar: _yukle)
          : _kisiler == null
          ? const Durum.yukleniyor()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _satir(0, 'Ekip kanalı', null, 'Tüm personel', true, r, ikon: Simgeler.groups),
                const Baslik('Kişiler'),
                for (final u in _kisiler!)
                  _satir(
                    u.id,
                    u.ad,
                    u.avatar,
                    u.cevrimici ? musaitlikAdi(u.musaitlik) : (u.sonGorulme == null ? 'çevrimdışı' : 'son: ${goreliZaman(u.sonGorulme)}'),
                    u.cevrimici,
                    r,
                    musaitlik: u.musaitlik,
                  ),
              ],
            ),
    );
    if (!context.genis) return liste;
    final ad = _kisi == 0 ? 'Ekip kanalı' : (_kisiler?.firstWhere((u) => u.id == _kisi, orElse: () => _kisiler!.first).ad ?? '');
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: r.kenar)),
            ),
            child: liste,
          ),
        ),
        Expanded(
          child: Scaffold(
            appBar: AppBar(title: Text(ad), automaticallyImplyLeading: false),
            body: IcSohbet(key: ValueKey(_kisi), kisi: _kisi),
          ),
        ),
      ],
    );
  }

  Widget _satir(int id, String ad, String? avatar, String alt, bool cevrimici, Renkler r, {IconData? ikon, String musaitlik = 'online'}) {
    final n = _okunmamis['$id'] ?? 0;
    final secili = context.genis && _kisi == id;
    return ListTile(
      selected: secili,
      selectedTileColor: r.vurguYumusak,
      leading: ikon != null
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: Marka.mor.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Simgeler.groups, color: Marka.mor),
            )
          : Stack(
              children: [
                KisiAvatar(ad, url: avatar, boyut: 40),
                Positioned(right: 0, bottom: 0, child: Nokta(cevrimici ? musaitlikRengi(musaitlik) : const Color(0xFF94A3B8), boyut: 12, halka: r.kart)),
              ],
            ),
      title: Text(ad, style: TextStyle(fontWeight: n > 0 ? FontWeight.w700 : FontWeight.w500)),
      subtitle: Text(alt, style: TextStyle(color: r.silik, fontSize: 12)),
      trailing: Sayac(n, renk: Marka.mor),
      onTap: () => _ac(id, ad),
    );
  }
}

/// Bir kanal / kişi için mesaj akışı.
class IcSohbet extends StatefulWidget {
  const IcSohbet({super.key, required this.kisi});
  final int kisi;
  @override
  State<IcSohbet> createState() => _IcSohbetState();
}

class _IcSohbetState extends State<IcSohbet> {
  final _mesajlar = <IcMesaj>[];
  Timer? _sayac;
  bool _yukleniyor = false;
  bool _ilk = true;
  String? _hata;
  final _kutu = TextEditingController();
  final _odak = FocusNode();
  final _kaydirma = ScrollController();

  @override
  void initState() {
    super.initState();
    _yokla();
    _sayac = Timer.periodic(const Duration(seconds: 3), (_) => _yokla());
  }

  @override
  void dispose() {
    _sayac?.cancel();
    _kutu.dispose();
    _odak.dispose();
    _kaydirma.dispose();
    super.dispose();
  }

  Future<void> _yokla() async {
    if (_yukleniyor) return;
    _yukleniyor = true;
    try {
      final v = await Depo.icYokla(kisi: widget.kisi, sonra: _mesajlar.isEmpty ? 0 : _mesajlar.last.id);
      if (!mounted) return;
      setState(() {
        for (final m in v.mesajlar) {
          final i = _mesajlar.indexWhere((x) => x.id == m.id);
          if (i >= 0) {
            _mesajlar[i] = m;
          } else {
            _mesajlar.add(m);
          }
        }
        _hata = null;
        _ilk = false;
      });
      if (v.mesajlar.isNotEmpty) _altaKay();
    } catch (e) {
      if (mounted && _ilk) setState(() => _hata = hataMetni(e));
    } finally {
      _yukleniyor = false;
    }
  }

  void _altaKay() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_kaydirma.hasClients) _kaydirma.jumpTo(_kaydirma.position.maxScrollExtent);
  });

  Future<void> _gonder() async {
    final t = _kutu.text.trim();
    if (t.isEmpty) return;
    _kutu.clear();
    await islem(() => Depo.icGonder(t, kisi: widget.kisi));
    _yokla();
    _odak.requestFocus();
  }

  Future<void> _dosya() async {
    final r = await FilePicker.pickFiles();
    final p = r.isEmpty ? null : r.first.path;
    if (p == null) return;
    await islem(() => Depo.icDosya(File(p), kisi: widget.kisi), tamam: 'Dosya gönderildi');
    _yokla();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final sabitler = _mesajlar.where((m) => m.sabit).toList();
    return Column(
      children: [
        if (sabitler.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            color: Marka.kehribar.withValues(alpha: .1),
            child: Row(
              children: [
                const Icon(Simgeler.flag, size: 15, color: Marka.kehribar),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sabitler.last.govde ?? '(dosya)',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: r.metin, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _hata != null
              ? Durum.hata(_hata!, tekrar: _yokla)
              : _ilk
              ? const Durum.yukleniyor()
              : _mesajlar.isEmpty
              ? Durum.bos('Henüz mesaj yok. İlk mesajı siz yazın.', ikon: Simgeler.groups)
              : ListView.builder(
                  controller: _kaydirma,
                  padding: const EdgeInsets.all(12),
                  itemCount: _mesajlar.length,
                  itemBuilder: (_, i) => _balon(_mesajlar[i], i == 0 ? null : _mesajlar[i - 1], r),
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: r.kart,
            border: Border(top: BorderSide(color: r.kenar)),
          ),
          padding: const EdgeInsets.all(6),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(tooltip: 'Dosya', onPressed: _dosya, icon: const Icon(Simgeler.attachFile)),
                Expanded(
                  child: Shortcuts(
                    shortcuts: {
                      const SingleActivator(LogicalKeyboardKey.enter): const _Gonder(),
                      const SingleActivator(LogicalKeyboardKey.enter, meta: true): const _Gonder(),
                      const SingleActivator(LogicalKeyboardKey.enter, control: true): const _Gonder(),
                    },
                    child: Actions(
                      actions: {_Gonder: CallbackAction<_Gonder>(onInvoke: (_) => _gonder())},
                      child: TextField(
                        controller: _kutu,
                        focusNode: _odak,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: Platform.isIOS || Platform.isAndroid ? TextInputAction.newline : TextInputAction.none,
                        decoration: InputDecoration(
                          hintText: widget.kisi == 0 ? 'Ekibe yaz…' : 'Mesaj yaz…',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: r.kenar),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(tooltip: 'Gönder', onPressed: _gonder, icon: const Icon(Simgeler.send, size: 20)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _balon(IcMesaj m, IcMesaj? onceki, Renkler r) {
    final sag = m.benim;
    final yeni = onceki == null || onceki.kimden != m.kimden;
    final zemin = sag ? r.vurgu : r.kart;
    final yazi = sag ? Colors.white : r.metin;
    final dosya = m.dosya;
    return Padding(
      padding: EdgeInsets.only(top: yeni ? 10 : 2, bottom: 2),
      child: Row(
        mainAxisAlignment: sag ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!sag) ...[yeni ? Avatar(m.ad, boyut: 28) : const SizedBox(width: 28), const SizedBox(width: 8)],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _menu(m),
              onSecondaryTap: () => _menu(m),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                decoration: BoxDecoration(
                  color: zemin,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(sag ? 16 : 4),
                    bottomRight: Radius.circular(sag ? 4 : 16),
                  ),
                  border: sag ? null : Border.all(color: r.kenar),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!sag && yeni && widget.kisi == 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          m.ad,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Avatar.renkFor(m.ad)),
                        ),
                      ),
                    if (m.gorsel != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 300),
                            child: Image.network(
                              Uyg.tamAdres(m.gorsel),
                              headers: Uyg.api.jeton == null ? null : {'Authorization': 'Bearer ${Uyg.api.jeton}'},
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    if (dosya != null)
                      InkWell(
                        onTap: () => ekAc('${dosya['url'] ?? dosya['dl'] ?? ''}', '${dosya['name'] ?? 'dosya'}'),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Simgeler.filePresent, color: yazi, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${dosya['name'] ?? 'dosya'}',
                                  style: TextStyle(color: yazi, decoration: TextDecoration.underline, decorationColor: yazi),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (m.govde != null && m.govde!.isNotEmpty) SelectableText(m.govde!, style: TextStyle(color: yazi, fontSize: 14.5, height: 1.35)),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m.sabit) Icon(Simgeler.flag, size: 11, color: yazi.withValues(alpha: .7)),
                        Text(' ${m.saat}', style: TextStyle(color: yazi.withValues(alpha: .65), fontSize: 10.5)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _menu(IcMesaj m) async {
    final s = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.govde != null && m.govde!.isNotEmpty)
              ListTile(leading: const Icon(Simgeler.copy), title: const Text('Kopyala'), onTap: () => Navigator.pop(c, 'kopyala')),
            ListTile(leading: const Icon(Simgeler.flag), title: Text(m.sabit ? 'Sabitlemeyi kaldır' : 'Sabitle'), onTap: () => Navigator.pop(c, 'sabit')),
          ],
        ),
      ),
    );
    if (s == 'kopyala') await kopyala(m.govde!);
    if (s == 'sabit') {
      await islem(() => Depo.icSabitle(m.id));
      _yokla();
    }
  }
}

class _Gonder extends Intent {
  const _Gonder();
}
