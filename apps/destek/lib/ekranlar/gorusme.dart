import 'dart:async';
import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';

/// Tek görüşme: mesaj akışı (2 sn yoklama), yanıt kutusu, hazır yanıtlar, ekler, eylemler, ziyaretçi bilgisi.
class GorusmeEkrani extends StatefulWidget {
  const GorusmeEkrani({super.key, required this.sohbetId, this.ilk, this.gomulu = false});
  final int sohbetId;
  final Sohbet? ilk;

  /// Geniş ekranda liste yanında gömülü (geri oku yok).
  final bool gomulu;
  @override
  State<GorusmeEkrani> createState() => _GorusmeEkraniState();
}

class _GorusmeEkraniState extends State<GorusmeEkrani> {
  final _mesajlar = <Mesaj>[];
  Yoklama? _son;
  String? _hata;
  Timer? _sayac;
  bool _yukleniyor = false;
  final _kutu = TextEditingController();
  final _odak = FocusNode();
  final _kaydirma = ScrollController();
  bool _icNot = false;
  bool _fisilti = false;
  bool _gonderiyor = false;
  DateTime _sonYaziyor = DateTime(2000);
  List<HazirYanit> _oneriler = [];
  bool _bilgiAcik = false;
  double? _yuklemeOrani;

  int get _id => widget.sohbetId;
  int get _sonId => _mesajlar.isEmpty ? 0 : _mesajlar.last.id;
  bool get _kapali => (_son?.durum ?? widget.ilk?.durum) == 'closed';
  bool get _yanitYetkisi => Uyg.yetki('chats.reply');

  @override
  void initState() {
    super.initState();
    _yokla();
    _sayac = Timer.periodic(const Duration(seconds: 2), (_) => _yokla());
    _kutu.addListener(_metinDegisti);
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
      final y = await Depo.yokla(_id, sonra: _sonId);
      if (!mounted) return;
      final enAlt = !_kaydirma.hasClients || _kaydirma.position.pixels > _kaydirma.position.maxScrollExtent - 120;
      setState(() {
        _son = y;
        _hata = null;
        for (final m in y.mesajlar) {
          final i = _mesajlar.indexWhere((x) => x.id == m.id);
          if (i >= 0) {
            _mesajlar[i] = m;
          } else {
            _mesajlar.add(m);
          }
        }
        // Okundu / düzenlendi bilgisi: read_upto altındaki kendi mesajlarımız
        if (y.okunanSon > 0) {
          for (var i = 0; i < _mesajlar.length; i++) {
            final m = _mesajlar[i];
            if (m.temsilci && !m.okundu && m.id <= y.okunanSon) {
              _mesajlar[i] = Mesaj.coz({
                'id': m.id,
                'sender': m.gonderen,
                'name': m.ad,
                'type': m.tur,
                'internal': m.icNot,
                'whisper': m.fisilti,
                'body': m.govde,
                'at': m.saat,
                'read': true,
                'edited': m.duzenlendi,
                'deleted': m.silindi,
                'own': m.benim,
              });
            }
          }
        }
      });
      if (y.mesajlar.isNotEmpty && enAlt) _altaKay();
    } catch (e) {
      if (mounted && _mesajlar.isEmpty) setState(() => _hata = hataMetni(e));
    } finally {
      _yukleniyor = false;
    }
  }

  void _altaKay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_kaydirma.hasClients) _kaydirma.animateTo(_kaydirma.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    });
  }

  void _metinDegisti() {
    final t = _kutu.text;
    // Yazıyor sinyali (en çok 3 sn'de bir)
    if (t.isNotEmpty && !_icNot && DateTime.now().difference(_sonYaziyor).inSeconds >= 3) {
      _sonYaziyor = DateTime.now();
      Depo.yaziyor(_id).catchError((_) {});
    }
    // Hazır yanıt: "/" ile başlıyorsa öner
    if (t.startsWith('/') && !t.contains(' ')) {
      final q = t.substring(1);
      Depo.hazirYanitlar(q)
          .then((l) {
            if (mounted && _kutu.text.startsWith('/')) setState(() => _oneriler = l.take(8).toList());
          })
          .catchError((_) {});
    } else if (_oneriler.isNotEmpty) {
      setState(() => _oneriler = []);
    }
  }

  Future<void> _gonder() async {
    final t = _kutu.text.trim();
    if (t.isEmpty || _gonderiyor) return;
    setState(() => _gonderiyor = true);
    try {
      if (_fisilti) {
        await Depo.fisilda(_id, t);
      } else {
        final m = await Depo.yanitla(_id, t, icNot: _icNot);
        if (mounted) setState(() => _mesajlar.add(m));
      }
      _kutu.clear();
      _altaKay();
      _yokla();
    } catch (e) {
      bildir('Gönderilemedi', mesaj: hataMetni(e), tur: MesajTur.hata);
    } finally {
      if (mounted) setState(() => _gonderiyor = false);
      _odak.requestFocus();
    }
  }

  Future<void> _dosyaSec({bool gorsel = false}) async {
    File? f;
    if (gorsel && (Platform.isIOS || Platform.isAndroid)) {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 2200);
      if (x != null) f = File(x.path);
    } else {
      final r = await FilePicker.pickFiles(type: gorsel ? FileType.image : FileType.any);
      final p = r.isEmpty ? null : r.first.path;
      if (p != null) f = File(p);
    }
    if (f == null) return;
    setState(() => _yuklemeOrani = 0);
    try {
      final m = await Depo.dosyaGonder(
        _id,
        f,
        ilerleme: (a, b) {
          if (mounted && b > 0) setState(() => _yuklemeOrani = a / b);
        },
      );
      if (mounted) setState(() => _mesajlar.add(m));
      _altaKay();
    } catch (e) {
      bildir('Dosya gönderilemedi', mesaj: hataMetni(e), tur: MesajTur.hata);
    } finally {
      if (mounted) setState(() => _yuklemeOrani = null);
    }
  }

  Future<void> _fotoCek() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
    if (x == null) return;
    setState(() => _yuklemeOrani = 0);
    try {
      final m = await Depo.dosyaGonder(_id, File(x.path));
      if (mounted) setState(() => _mesajlar.add(m));
      _altaKay();
    } catch (e) {
      bildir('Fotoğraf gönderilemedi', mesaj: hataMetni(e), tur: MesajTur.hata);
    } finally {
      if (mounted) setState(() => _yuklemeOrani = null);
    }
  }

  Future<void> _eylem(String ne) async {
    switch (ne) {
      case 'katil':
        await islem(() => Depo.katil(_id), tamam: 'Sohbete katıldınız');
      case 'ayril':
        await islem(() => Depo.ayril(_id), tamam: 'Sohbetten ayrıldınız');
      case 'devral':
        if (await onayla(
          context,
          'Sohbeti devralmak istiyor musunuz?',
          mesaj: 'Mevcut temsilci sohbetten çıkarılır, ziyaretçiye bilgi gider.',
          evet: 'Devral',
        )) {
          await islem(() => Depo.devral(_id), tamam: 'Sohbet devralındı');
        }
      case 'izle':
        await islem(() => Depo.izle(_id), tamam: 'İzleme modundasınız (ziyaretçi görmez)');
      case 'kapat':
        if (await onayla(context, 'Sohbet kapatılsın mı?', mesaj: 'Ziyaretçiye kapanış ve değerlendirme ekranı gösterilir.', evet: 'Kapat')) {
          await islem(() => Depo.kapat(_id), tamam: 'Sohbet kapatıldı');
        }
      case 'ac':
        await islem(() => Depo.yenidenAc(_id), tamam: 'Sohbet yeniden açıldı');
      case 'favori':
        await islem(() => Depo.favori(_id));
      case 'arsiv':
        await islem(() => Depo.arsivle(_id), tamam: 'Arşiv durumu değişti');
      case 'kacan':
        await islem(() => Depo.kacanCozuldu(_id), tamam: 'Kaçan sohbet işlendi');
      case 'eposta':
        final e = await metinSor(context, 'Transkript e-postası', ipucu: 'Boş bırakılırsa ziyaretçinin e-postasına gider', tamam: 'Gönder');
        if (e == null) return;
        await islem(() => Depo.transkriptEposta(_id, eposta: e.trim().isEmpty ? null : e.trim()), tamam: 'Transkript gönderildi');
      case 'baglanti':
        final u = await islem(() => Depo.transkriptBaglanti(_id));
        if (u != null) await panoyaKopyala(Uyg.tamAdres(u), ad: 'Transkript bağlantısı');
      case 'portal':
        final u = await islem(() => Depo.portalBaglanti(_id));
        if (u != null) await panoyaKopyala(Uyg.tamAdres(u), ad: 'Müşteri paneli bağlantısı');
      case 'talep':
        await _talepFormu();
      case 'bilgi':
        setState(() => _bilgiAcik = !_bilgiAcik);
    }
    _yokla();
  }

  Future<void> _talepFormu() async {
    final bolumler = await islem(() => Depo.talepBolumleri());
    if (bolumler == null || !mounted) return;
    var kip = 'general';
    int bolum = bolumler.isEmpty ? 0 : (bolumler.first['id'] as num? ?? 0).toInt();
    final konu = TextEditingController(text: 'Canlı destek görüşmesi #$_id');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Destek talebine dönüştür'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'general', label: Text('Genel')),
                  ButtonSegment(value: 'service', label: Text('Hizmet seçtir')),
                ],
                selected: {kip},
                onSelectionChanged: (s) => set(() => kip = s.first),
              ),
              const SizedBox(height: 12),
              if (bolumler.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: bolum,
                  decoration: const InputDecoration(labelText: 'Departman'),
                  items: [for (final b in bolumler) DropdownMenuItem(value: (b['id'] as num).toInt(), child: Text('${b['name']}'))],
                  onChanged: (v) => set(() => bolum = v ?? bolum),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: konu,
                decoration: const InputDecoration(labelText: 'Konu'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ziyaretçiye gönder')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await islem(
      () => Depo.talepFormu(_id, kip: kip, bolum: bolum, konu: konu.text.trim()),
      tamam: 'Talep formu ziyaretçiye gönderildi',
    );
  }

  Future<void> _mesajMenusu(Mesaj m) async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.govde != null && m.govde!.isNotEmpty)
              ListTile(leading: const Icon(Simgeler.copy), title: const Text('Metni kopyala'), onTap: () => Navigator.pop(c, 'kopyala')),
            if (m.ek != null) ListTile(leading: const Icon(Simgeler.download), title: const Text('Eki aç'), onTap: () => Navigator.pop(c, 'ek')),
            if (m.benim && !m.silindi && m.ek == null)
              ListTile(leading: const Icon(Simgeler.edit), title: const Text('Düzenle'), onTap: () => Navigator.pop(c, 'duzenle')),
            if ((m.benim || Uyg.yonetici) && !m.silindi)
              ListTile(
                leading: const Icon(Simgeler.deleteOutline, color: Marka.gul),
                title: const Text('Sil', style: TextStyle(color: Marka.gul)),
                onTap: () => Navigator.pop(c, 'sil'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || secim == null) return;
    switch (secim) {
      case 'kopyala':
        await panoyaKopyala(m.govde!, ad: 'Mesaj');
      case 'ek':
        await ekAc(m.ek!.indir.isNotEmpty ? m.ek!.indir : m.ek!.url, m.ek!.ad);
      case 'duzenle':
        final t = await metinSor(context, 'Mesajı düzenle', ilk: m.govde ?? '');
        if (t == null || t.trim().isEmpty) return;
        await islem(() => Depo.mesajDuzenle(_id, m.id, t.trim()), tamam: 'Mesaj düzenlendi');
        _yokla();
      case 'sil':
        if (await onayla(context, 'Mesaj silinsin mi?', evet: 'Sil', tehlikeli: true)) {
          await islem(() => Depo.mesajSil(_id, m.id), tamam: 'Mesaj silindi');
          _yokla();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final ad = widget.ilk?.ziyaretci ?? 'Sohbet #$_id';
    final durum = _son?.durum ?? widget.ilk?.durum ?? '';
    final cevrimici = _son?.cevrimici ?? widget.ilk?.cevrimici ?? false;
    final yaziyor = _son?.yaziyor;
    final genis = context.genis;
    final govde = Column(
      children: [
        Expanded(
          child: _hata != null
              ? Durum.hata(_hata!, tekrar: _yokla)
              : _son == null
              ? const Durum.yukleniyor()
              : _mesajlar.isEmpty
              ? Durum.bos('Henüz mesaj yok.', ikon: Simgeler.forum)
              : ListView.builder(
                  controller: _kaydirma,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: _mesajlar.length,
                  itemBuilder: (_, i) => _balon(_mesajlar[i], i == 0 ? null : _mesajlar[i - 1], r),
                ),
        ),
        if (yaziyor != null && yaziyor.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            color: Marka.mor.withValues(alpha: .07),
            child: Row(
              children: [
                const Icon(Simgeler.edit, size: 14, color: Marka.mor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Yazıyor: $yaziyor',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Marka.mor, fontSize: 12.5, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        if (_oneriler.isNotEmpty) _oneriKutusu(r),
        if (_yuklemeOrani != null) LinearProgressIndicator(value: _yuklemeOrani == 0 ? null : _yuklemeOrani, minHeight: 3),
        _yazimKutusu(r, durum),
      ],
    );
    final ekran = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.gomulu,
        titleSpacing: widget.gomulu ? 16 : 0,
        title: InkWell(
          onTap: () => setState(() => _bilgiAcik = !_bilgiAcik),
          child: Row(
            children: [
              Stack(
                children: [
                  Avatar(ad, boyut: 36, tohum: widget.ilk?.eposta ?? ad),
                  Positioned(right: 0, bottom: 0, child: Nokta(cevrimici ? Marka.zumrut : const Color(0xFF94A3B8), boyut: 11, halka: r.kart)),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ad,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      [
                        if (widget.ilk?.ulke != null) '${bayrak(widget.ilk!.ulke)} ',
                        cevrimici ? 'çevrimiçi' : 'çevrimdışı',
                        if (_son?.url != null) ' · ${kisaUrl(_son!.url, en: 32)}',
                      ].join(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: r.silik, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Rozet(
              durum == 'closed'
                  ? 'Kapalı'
                  : durum == 'pending'
                  ? 'Bekliyor'
                  : durum == 'offline'
                  ? 'Çevrimdışı'
                  : 'Açık',
              renk: durumRengi(durum),
            ),
          ),
          IconButton(
            tooltip: 'Ziyaretçi bilgisi',
            onPressed: () => setState(() => _bilgiAcik = !_bilgiAcik),
            icon: Icon(_bilgiAcik ? Simgeler.infoOutline : Simgeler.infoOutline, color: _bilgiAcik ? r.vurgu : null),
          ),
          PopupMenuButton<String>(
            tooltip: 'Eylemler',
            onSelected: _eylem,
            itemBuilder: (_) => [
              if (_yanitYetkisi && !_kapali) ...[
                const PopupMenuItem(
                  value: 'katil',
                  child: ListTile(dense: true, leading: Icon(Simgeler.login), title: Text('Sohbete katıl')),
                ),
                const PopupMenuItem(
                  value: 'ayril',
                  child: ListTile(dense: true, leading: Icon(Simgeler.logout), title: Text('Sohbetten ayrıl')),
                ),
              ],
              if (Uyg.yetki('chats.supervise') && !_kapali) ...[
                const PopupMenuItem(
                  value: 'devral',
                  child: ListTile(dense: true, leading: Icon(Simgeler.swapHoriz), title: Text('Devral')),
                ),
                const PopupMenuItem(
                  value: 'izle',
                  child: ListTile(dense: true, leading: Icon(Simgeler.visibility), title: Text('İzle (sessiz)')),
                ),
              ],
              const PopupMenuDivider(),
              if (_yanitYetkisi) ...[
                PopupMenuItem(
                  value: 'talep',
                  enabled: !_kapali,
                  child: const ListTile(dense: true, leading: Icon(Simgeler.receiptLong), title: Text('Destek talebi formu gönder')),
                ),
                const PopupMenuItem(
                  value: 'portal',
                  child: ListTile(dense: true, leading: Icon(Simgeler.link), title: Text('Müşteri paneli bağlantısı')),
                ),
              ],
              if (Uyg.yetki('chats.transcript')) ...[
                const PopupMenuItem(
                  value: 'eposta',
                  child: ListTile(dense: true, leading: Icon(Simgeler.mailOutline), title: Text('Transkripti e-postala')),
                ),
                const PopupMenuItem(
                  value: 'baglanti',
                  child: ListTile(dense: true, leading: Icon(Simgeler.copy), title: Text('Transkript bağlantısını kopyala')),
                ),
              ],
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'favori',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Simgeler.starOutline),
                  title: Text(widget.ilk?.favori == true ? 'Favoriden çıkar' : 'Favorilere ekle'),
                ),
              ),
              const PopupMenuItem(
                value: 'arsiv',
                child: ListTile(dense: true, leading: Icon(Simgeler.archive), title: Text('Arşivle / arşivden çıkar')),
              ),
              if (widget.ilk?.kacan == true && _yanitYetkisi)
                const PopupMenuItem(
                  value: 'kacan',
                  child: ListTile(dense: true, leading: Icon(Simgeler.taskAlt), title: Text('Kaçan: işlendi olarak kapat')),
                ),
              if (_yanitYetkisi)
                _kapali
                    ? const PopupMenuItem(
                        value: 'ac',
                        child: ListTile(dense: true, leading: Icon(Simgeler.lockOpen), title: Text('Yeniden aç')),
                      )
                    : const PopupMenuItem(
                        value: 'kapat',
                        child: ListTile(
                          dense: true,
                          leading: Icon(Simgeler.cancel, color: Marka.gul),
                          title: Text('Sohbeti kapat', style: TextStyle(color: Marka.gul)),
                        ),
                      ),
            ],
          ),
        ],
      ),
      body: genis && _bilgiAcik
          ? Row(
              children: [
                Expanded(child: govde),
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: r.kenar)),
                  ),
                  child: _bilgiPaneli(r),
                ),
              ],
            )
          : govde,
      endDrawer: genis ? null : Drawer(width: 320, child: _bilgiPaneli(r)),
    );
    if (!genis && _bilgiAcik) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bilgiAcik = false;
        if (mounted) Scaffold.of(context).openEndDrawer();
      });
    }
    return ekran;
  }

  Widget _balon(Mesaj m, Mesaj? onceki, Renkler r) {
    if (m.sistem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: r.kart,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: r.kenar),
            ),
            child: Text('${m.govde ?? ''} · ${m.saat}', style: TextStyle(color: r.silik, fontSize: 11.5)),
          ),
        ),
      );
    }
    final sag = !m.ziyaretci;
    final icNot = m.icNot || m.fisilti;
    final zemin = icNot
        ? Marka.kehribar.withValues(alpha: .16)
        : sag
        ? (m.benim ? r.vurgu : Marka.mavi)
        : r.kart;
    final yazi = icNot ? r.metin : (sag ? Colors.white : r.metin);
    final yeniGonderen = onceki == null || onceki.gonderen != m.gonderen || onceki.ad != m.ad || onceki.sistem;
    return Padding(
      padding: EdgeInsets.only(top: yeniGonderen ? 10 : 2, bottom: 2),
      child: Row(
        mainAxisAlignment: sag ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!sag) ...[yeniGonderen ? Avatar(m.ad.isEmpty ? 'Z' : m.ad, boyut: 28) : const SizedBox(width: 28), const SizedBox(width: 8)],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _mesajMenusu(m),
              onSecondaryTap: () => _mesajMenusu(m),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                decoration: BoxDecoration(
                  color: zemin,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(sag ? 16 : 4),
                    bottomRight: Radius.circular(sag ? 4 : 16),
                  ),
                  border: icNot ? Border.all(color: Marka.kehribar.withValues(alpha: .5)) : (sag ? null : Border.all(color: r.kenar)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (yeniGonderen && (sag && !m.benim || icNot))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          icNot ? (m.fisilti ? 'Fısıltı · ${m.ad}' : 'İç not · ${m.ad}') : m.ad,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: icNot ? Marka.kehribar : Colors.white.withValues(alpha: .85)),
                        ),
                      ),
                    if (m.ek != null) _ekGorunumu(m.ek!, yazi, r),
                    if (m.silindi)
                      Text(
                        'Bu mesaj silindi',
                        style: TextStyle(color: yazi.withValues(alpha: .7), fontStyle: FontStyle.italic, fontSize: 14),
                      )
                    else if (m.govde != null && m.govde!.isNotEmpty)
                      SelectableText(m.govde!, style: TextStyle(color: yazi, fontSize: 14.5, height: 1.35)),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m.duzenlendi) Text('düzenlendi · ', style: TextStyle(color: yazi.withValues(alpha: .65), fontSize: 10.5)),
                        Text(m.saat, style: TextStyle(color: yazi.withValues(alpha: .65), fontSize: 10.5)),
                        if (sag && !icNot) ...[
                          const SizedBox(width: 4),
                          Icon(m.okundu ? Simgeler.doneAll : Simgeler.check, size: 13, color: m.okundu ? Colors.white : Colors.white.withValues(alpha: .65)),
                        ],
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

  Widget _ekGorunumu(Ek e, Color yazi, Renkler r) {
    final url = Uyg.tamAdres(e.url);
    if (e.gorsel) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => _gorselBuyut(url, e.ad),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 320),
              child: Image.network(
                url,
                headers: Uyg.api.jeton == null ? null : {'Authorization': 'Bearer ${Uyg.api.jeton}'},
                fit: BoxFit.cover,
                loadingBuilder: (_, w, p) =>
                    p == null ? w : const SizedBox(height: 120, width: 200, child: Center(child: CircularProgressIndicator.adaptive())),
                errorBuilder: (_, _, _) =>
                    Container(height: 80, width: 200, alignment: Alignment.center, color: Colors.black12, child: const Icon(Simgeler.brokenImage)),
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => ekAc(e.indir.isNotEmpty ? e.indir : e.url, e.ad),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              e.ses
                  ? Simgeler.playCircleOutline
                  : e.video
                  ? Simgeler.playArrow
                  : Simgeler.filePresent,
              color: yazi,
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.ad,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: yazi, fontWeight: FontWeight.w600, fontSize: 13.5, decoration: TextDecoration.underline, decorationColor: yazi),
                  ),
                  Text(boyutYaz(e.boyut), style: TextStyle(color: yazi.withValues(alpha: .7), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _gorselBuyut(String url, String ad) {
    showDialog<void>(
      context: context,
      builder: (c) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 6,
                child: Center(child: Image.network(url, headers: Uyg.api.jeton == null ? null : {'Authorization': 'Bearer ${Uyg.api.jeton}'})),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => ekAc(url, ad),
                      icon: const Icon(Simgeler.iosShare, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(c),
                      icon: const Icon(Simgeler.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _oneriKutusu(Renkler r) => Container(
    constraints: const BoxConstraints(maxHeight: 220),
    decoration: BoxDecoration(
      color: r.kart,
      border: Border(top: BorderSide(color: r.kenar)),
    ),
    child: ListView(
      shrinkWrap: true,
      children: [
        for (final h in _oneriler)
          ListTile(
            dense: true,
            leading: Rozet('/${h.kisayol}', renk: Marka.mor),
            title: Text(h.baslik, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            subtitle: Text(
              h.govde,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: r.soluk, fontSize: 12),
            ),
            onTap: () {
              _kutu.text = h.govde;
              _kutu.selection = TextSelection.collapsed(offset: h.govde.length);
              setState(() => _oneriler = []);
              _odak.requestFocus();
            },
          ),
      ],
    ),
  );

  Widget _yazimKutusu(Renkler r, String durum) {
    if (!_yanitYetkisi) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: r.kart,
        child: SafeArea(
          top: false,
          child: Text(
            'Yalnızca görüntüleme yetkiniz var.',
            textAlign: TextAlign.center,
            style: TextStyle(color: r.silik, fontSize: 12.5),
          ),
        ),
      );
    }
    if (_kapali) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: r.kart,
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Bu sohbet kapalı.', style: TextStyle(color: r.silik, fontSize: 13)),
              const SizedBox(width: 12),
              FilledButton.tonal(onPressed: () => _eylem('ac'), child: const Text('Yeniden aç')),
            ],
          ),
        ),
      );
    }
    final kipRengi = _fisilti
        ? Marka.lavanta
        : _icNot
        ? Marka.kehribar
        : null;
    return Container(
      decoration: BoxDecoration(
        color: r.kart,
        border: Border(top: BorderSide(color: r.kenar)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kipRengi != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(_fisilti ? Simgeler.visibilityOff : Simgeler.stickyNote2, size: 14, color: kipRengi),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _fisilti ? 'Fısıltı: yalnız sohbetteki temsilci görür' : 'İç not: ziyaretçi görmez, ekibe görünür',
                        style: TextStyle(color: kipRengi, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Ekle',
                  icon: const Icon(Simgeler.add),
                  onSelected: (v) {
                    switch (v) {
                      case 'dosya':
                        _dosyaSec();
                      case 'gorsel':
                        _dosyaSec(gorsel: true);
                      case 'kamera':
                        _fotoCek();
                      case 'not':
                        setState(() {
                          _icNot = !_icNot;
                          _fisilti = false;
                        });
                      case 'fisilti':
                        setState(() {
                          _fisilti = !_fisilti;
                          _icNot = false;
                        });
                      case 'hazir':
                        _kutu.text = '/';
                        _kutu.selection = const TextSelection.collapsed(offset: 1);
                        _odak.requestFocus();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'gorsel',
                      child: ListTile(dense: true, leading: Icon(Simgeler.image), title: Text('Görsel')),
                    ),
                    if (Platform.isIOS || Platform.isAndroid)
                      const PopupMenuItem(
                        value: 'kamera',
                        child: ListTile(dense: true, leading: Icon(Simgeler.photoCamera), title: Text('Fotoğraf çek')),
                      ),
                    const PopupMenuItem(
                      value: 'dosya',
                      child: ListTile(dense: true, leading: Icon(Simgeler.attachFile), title: Text('Dosya')),
                    ),
                    const PopupMenuItem(
                      value: 'hazir',
                      child: ListTile(dense: true, leading: Icon(Simgeler.bolt), title: Text('Hazır yanıt (/)')),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'not',
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Simgeler.stickyNote2, color: Marka.kehribar),
                        title: Text(_icNot ? 'İç notu kapat' : 'İç not yaz'),
                      ),
                    ),
                    if (Uyg.yetki('chats.supervise'))
                      PopupMenuItem(
                        value: 'fisilti',
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Simgeler.visibilityOff, color: Marka.lavanta),
                          title: Text(_fisilti ? 'Fısıltıyı kapat' : 'Temsilciye fısılda'),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Shortcuts(
                    shortcuts: {
                      const SingleActivator(LogicalKeyboardKey.enter): const _GonderNiyeti(),
                      const SingleActivator(LogicalKeyboardKey.enter, meta: true): const _GonderNiyeti(),
                      const SingleActivator(LogicalKeyboardKey.enter, control: true): const _GonderNiyeti(),
                    },
                    child: Actions(
                      actions: {_GonderNiyeti: CallbackAction<_GonderNiyeti>(onInvoke: (_) => _gonder())},
                      child: TextField(
                        controller: _kutu,
                        focusNode: _odak,
                        minLines: 1,
                        maxLines: 6,
                        textInputAction: Platform.isIOS || Platform.isAndroid ? TextInputAction.newline : TextInputAction.none,
                        decoration: InputDecoration(
                          hintText: _fisilti
                              ? 'Temsilciye fısılda…'
                              : _icNot
                              ? 'İç not…'
                              : 'Yanıt yazın · / hazır yanıt',
                          isDense: true,
                          filled: true,
                          fillColor: kipRengi?.withValues(alpha: .08),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: r.kenar),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: kipRengi ?? r.kenar),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  tooltip: 'Gönder',
                  onPressed: _gonderiyor ? null : _gonder,
                  icon: _gonderiyor
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Simgeler.send, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bilgiPaneli(Renkler r) {
    final s = _son;
    final ilk = widget.ilk;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Text('Ziyaretçi', style: gosterim(17, renk: r.metin)),
              const Spacer(),
              if (!context.genis) IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Simgeler.close)),
            ],
          ),
          const SizedBox(height: 8),
          _satir('Ad', ilk?.ziyaretci ?? '—', r),
          if (ilk?.eposta != null) _satir('E-posta', ilk!.eposta!, r, kopyalanir: true),
          if (ilk?.ulke != null) _satir('Ülke', '${bayrak(ilk!.ulke)} ${ilk.ulke}', r),
          if (ilk?.bolum != null) _satir('Departman', ilk!.bolum!, r),
          if (ilk?.temsilci != null) _satir('Temsilci', ilk!.temsilci!, r),
          if (s?.dil != null) _satir('Dil', s!.dil!, r),
          if (s?.url != null) _satir('Şu an', s!.url!, r, kopyalanir: true),
          if (s?.puan != null) _satir('Değerlendirme', '${'★' * s!.puan!}${s.puanYorum == null ? '' : ' · ${s.puanYorum}'}', r),
          _satir('Sohbet', '#$_id', r),
          if (s != null && s.sayfalar.isNotEmpty) ...[
            const Baslik('Gezinme'),
            for (final p in s.sayfalar.take(15))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () => disAc(p.url),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.baslik ?? kisaUrl(p.url),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: r.metin, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${kisaUrl(p.url, en: 42)} · ${p.zaman}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: r.silik, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _satir(String ad, String deger, Renkler r, {bool kopyalanir = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(ad, style: TextStyle(color: r.silik, fontSize: 12.5)),
        ),
        Expanded(
          child: SelectableText(deger, style: TextStyle(color: r.metin, fontSize: 13.5)),
        ),
        if (kopyalanir)
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            onPressed: () => panoyaKopyala(deger, ad: ad),
            icon: const Icon(Simgeler.copy),
          ),
      ],
    ),
  );
}

class _GonderNiyeti extends Intent {
  const _GonderNiyeti();
}
