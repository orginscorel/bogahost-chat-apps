import 'dart:async';
import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pasteboard/pasteboard.dart';

import '../ortak/parcalar.dart';
import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'arama.dart';
import 'ekran_izle.dart';
import 'iptal_talebi.dart';
import 'sohbet_ziyaretci.dart';
import 'ziyaretci_detay.dart';

/// Tek görüşme: mesaj akışı (uyarlanır yoklama 0,9 / 2,5 / 6 sn), yanıt kutusu, hazır yanıtlar, ekler (seç · sürükle · Ctrl+V),
/// eylemler (talep formu · PDF · iptal talebi · dil), ziyaretçi talebi şeridi, ziyaretçi bilgisi.
class GorusmeEkrani extends StatefulWidget {
  const GorusmeEkrani({super.key, required this.sohbetId, this.ilk, this.gomulu = false});
  final int sohbetId;
  final Sohbet? ilk;

  /// Geniş ekranda liste yanında gömülü (geri oku yok).
  final bool gomulu;
  @override
  State<GorusmeEkrani> createState() => _GorusmeEkraniState();
}

class _GorusmeEkraniState extends State<GorusmeEkrani> with WidgetsBindingObserver {
  final _mesajlar = <Mesaj>[];
  final _indeks = <int, int>{};
  final _iptal = CancelToken();
  Map<String, dynamic>? _detay;
  DateTime _sonEtkinlik = DateTime.now();
  AppLifecycleState _yasam = AppLifecycleState.resumed;
  int _sonOkunan = 0;
  String _sonTalep = '';
  bool _surukleniyor = false;
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
  bool _aiBekliyor = false;

  /// Son yapay zeka önerisi: gönderimde öneri ↔ gönderilen farkı öğrenme için bildirilir.
  ({int? logId, String text})? _aiSon;

  int get _id => widget.sohbetId;
  int get _sonId => _mesajlar.isEmpty ? 0 : _mesajlar.last.id;
  bool get _kapali => (_son?.durum ?? widget.ilk?.durum) == 'closed';
  bool get _yanitYetkisi => Uyg.yetki('chats.reply');
  String get _ad => widget.ilk?.ziyaretci ?? 'Sohbet #$_id';
  bool get _aramaOlur => _yanitYetkisi && !_kapali && Uyg.yetki('chats.call');
  bool get _ziyaretciCevrimici => _son?.cevrimici ?? widget.ilk?.cevrimici ?? false;
  bool get _favori => _detay == null ? widget.ilk?.favori == true : _detay!['favorite'] == true;
  bool get _arsiv => _detay == null ? widget.ilk?.arsiv == true : _detay!['archived'] == true;
  bool get _kacan => _detay == null ? widget.ilk?.kacan == true : _detay!['missed'] == true;
  bool get _ceviriAcik => _detay?['translate_on'] == true;
  Object? get _whmcsId => _detay == null ? null : (_detay!['visitor'] is Map ? (_detay!['visitor'] as Map)['whmcs_id'] : null);
  Map<String, dynamic> get _meta => _detay?['meta'] is Map ? Map<String, dynamic>.from(_detay!['meta'] as Map) : const {};
  int get _aiTur => _meta['ai_turns'] is num ? (_meta['ai_turns'] as num).toInt() : int.tryParse('${_meta['ai_turns'] ?? ''}') ?? 0;
  bool get _aiDevredildi => _meta['ai_handoff'] == true || _meta['ai_handoff'] == 1 || _meta['ai_handoff'] == '1';
  Map<String, dynamic>? get _talep => _son?.iletisimTalebi is Map ? Map<String, dynamic>.from(_son!.iletisimTalebi as Map) : null;

  /// Ziyaretçi sekmesi kapalıysa arama bağlanamaz; yine de kullanıcıya bırak (sekme yeni açılmış olabilir).
  Future<bool> _aramaOnay() async =>
      _ziyaretciCevrimici ||
      await onayla(context, 'Ziyaretçi şu an çevrimdışı görünüyor — arama yalnız sitedeki sekmesi açıkken bağlanır. Yine de denensin mi?', evet: 'Yine de ara');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _yokla();
    _detayYukle();
    _planla();
    _kutu.addListener(_metinDegisti);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sayac?.cancel();
    _iptal.cancel();
    _kutu.dispose();
    _odak.dispose();
    _kaydirma.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final onceArkaPlan = _arkaPlanda;
    _yasam = s;
    if (s == AppLifecycleState.resumed || (onceArkaPlan && s == AppLifecycleState.inactive)) {
      _yokla();
      _planla();
    }
  }

  /// Web paneliyle aynı uyarlanır yoklama: son 25 sn'de hareket varsa 0,9 sn; 3 dk'ya kadar 2,5 sn; sonra 6 sn;
  /// pencere arkadayken 10 sn. Her yoklama bitince yeniden planlanır (üst üste binmez).
  /// Masaüstünde pencere odağı başka uygulamadayken (ör. temsilci tarayıcıda müşteriyi test ediyor) durum `inactive` olur;
  /// bu arka plan değildir — yalnız gizli/duraklatılmış (paused/hidden) uygulamada yoklama seyrekleşir.
  bool get _arkaPlanda => _yasam == AppLifecycleState.paused || _yasam == AppLifecycleState.hidden;

  Duration get _aralik {
    if (_arkaPlanda) return const Duration(seconds: 10);
    final bosta = DateTime.now().difference(_sonEtkinlik);
    if (bosta.inSeconds < 25) return const Duration(milliseconds: 900);
    if (bosta.inMinutes < 3) return const Duration(milliseconds: 2500);
    return const Duration(seconds: 6);
  }

  void _planla() {
    _sayac?.cancel();
    _sayac = Timer(_aralik, () async {
      await _yokla();
      if (mounted) _planla();
    });
  }

  /// Gönderim / yazma / yeni mesaj: hızlı kipe geç.
  void _hizlan() {
    _sonEtkinlik = DateTime.now();
    _planla();
  }

  void _mesajEkle(Mesaj m) {
    final i = _indeks[m.id];
    if (i != null) {
      _mesajlar[i] = m;
    } else {
      _indeks[m.id] = _mesajlar.length;
      _mesajlar.add(m);
    }
  }

  Future<void> _detayYukle() async {
    try {
      final d = await Depo.sohbetDetay(_id);
      if (mounted) setState(() => _detay = d);
    } catch (_) {}
  }

  static bool _farkli(Yoklama a, Yoklama b) =>
      a.durum != b.durum ||
      a.yaziyor != b.yaziyor ||
      a.cevrimici != b.cevrimici ||
      a.url != b.url ||
      a.oturumId != b.oturumId ||
      a.dil != b.dil ||
      a.puan != b.puan ||
      '${a.iletisimTalebi}' != '${b.iletisimTalebi}';

  Future<void> _yokla() async {
    if (_yukleniyor) return;
    _yukleniyor = true;
    try {
      final y = await Depo.yokla(_id, sonra: _sonId, iptal: _iptal);
      if (!mounted) return;
      final enAlt = !_kaydirma.hasClients || _kaydirma.position.pixels > _kaydirma.position.maxScrollExtent - 120;
      // Görünür bir şey değişmediyse yeniden çizme: 2 sn'de bir tüm balonların yeniden kurulması uygulamayı ağırlaştırıyordu.
      var degisti = _son == null || _hata != null || _farkli(_son!, y);
      if (y.mesajlar.isNotEmpty) {
        degisti = true;
        y.mesajlar.forEach(_mesajEkle);
        if (y.mesajlar.any((m) => m.ziyaretci)) _sonEtkinlik = DateTime.now();
      }
      // Okundu bilgisi: read_upto altındaki kendi mesajlarımız (yalnız eşik ilerleyince taranır)
      if (y.okunanSon > _sonOkunan) {
        _sonOkunan = y.okunanSon;
        for (var i = 0; i < _mesajlar.length; i++) {
          final m = _mesajlar[i];
          if (m.temsilci && !m.okundu && m.id <= y.okunanSon) {
            _mesajlar[i] = m.copyWith(okundu: true);
            degisti = true;
          }
        }
      }
      // Ziyaretçi talebi (sesli / görüntülü / ekran): yeni geldiyse bir kez duyur
      final t = y.iletisimTalebi is Map ? '${(y.iletisimTalebi as Map)['at']}' : '';
      if (t.isNotEmpty && t != _sonTalep) {
        _sonTalep = t;
        bildir('Ziyaretçi ${_talepAdi(y)} istiyor', mesaj: _ad, tur: MesajTur.uyari);
      }
      if (degisti) {
        setState(() {
          _son = y;
          _hata = null;
        });
      }
      if (y.mesajlar.isNotEmpty && enAlt) _altaKay();
    } on IstekIptal {
      return;
    } catch (e) {
      if (mounted && _mesajlar.isEmpty) setState(() => _hata = hataMetni(e));
    } finally {
      _yukleniyor = false;
    }
  }

  static String _talepAdi(Yoklama y) {
    final t = y.iletisimTalebi is Map ? '${(y.iletisimTalebi as Map)['type']}' : '';
    return switch (t) {
      'voice' => 'sesli görüşme',
      'video' => 'görüntülü görüşme',
      'screen' => 'ekran paylaşımı',
      _ => 'görüşme',
    };
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
      _sonEtkinlik = _sonYaziyor;
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
        if (mounted) setState(() => _mesajEkle(m));
        final ai = _aiSon;
        if (ai != null && !_icNot) {
          Depo.aiGeriBildirim(_id, logId: ai.logId, oneri: ai.text, gonderilen: t).catchError((_) => <String, dynamic>{});
          _aiSon = null;
        }
      }
      _kutu.clear();
      _altaKay();
      _hizlan();
      _yokla();
    } catch (e) {
      bildir('Gönderilemedi', mesaj: hataMetni(e), tur: MesajTur.hata);
    } finally {
      if (mounted) setState(() => _gonderiyor = false);
      _odak.requestFocus();
    }
  }

  /// Yapay zeka yanıt önerisi: taslağı yazım kutusuna koyar; temsilci düzenleyip gönderir.
  Future<void> _aiOner() async {
    if (_aiBekliyor) return;
    setState(() => _aiBekliyor = true);
    try {
      final v = await Depo.aiOner(_id);
      if (!mounted) return;
      final t = v['text'] is String ? v['text'] as String : '';
      if (v['ok'] == true && t.trim().isNotEmpty) {
        _kutu.text = t;
        _kutu.selection = TextSelection.collapsed(offset: t.length);
        _aiSon = (logId: v['log_id'] is num ? (v['log_id'] as num).toInt() : int.tryParse('${v['log_id'] ?? ''}'), text: t);
        _odak.requestFocus();
        final skor = v['score'] is num ? (v['score'] as num).round() : int.tryParse('${v['score'] ?? ''}');
        bildir(skor == null ? 'Öneri eklendi' : 'Öneri eklendi (%$skor eşleşme)', tur: MesajTur.basari);
      } else {
        bildir('Öneri alınamadı', mesaj: v['error'] is String ? v['error'] as String : null, tur: MesajTur.uyari);
      }
    } catch (e) {
      bildir('Öneri alınamadı', mesaj: hataMetni(e), tur: MesajTur.uyari);
    } finally {
      if (mounted) setState(() => _aiBekliyor = false);
    }
  }

  /// bot:false → temsilci devralır; bot:true → bota geri verilir.
  Future<void> _aiDevir(bool bot) async {
    final v = await islem(() => Depo.aiDevir(_id, bot: bot));
    if (v == null) return;
    await _detayYukle();
  }

  Widget _aiSeridi(Renkler r) {
    final devredildi = _aiDevredildi;
    final renk = devredildi ? Marka.grafitAcik : Marka.mor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Simgeler.sparkle, size: 14, color: renk),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              devredildi ? 'Asistan devredildi' : '🤖 Asistan yanıtlıyor',
              style: TextStyle(color: renk, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact, textStyle: const TextStyle(fontSize: 12.5)),
            onPressed: () => _aiDevir(devredildi),
            child: Text(devredildi ? 'Bota geri ver' : 'Devral'),
          ),
        ],
      ),
    );
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
    await _dosyaYukle(f);
  }

  Future<void> _fotoCek() async {
    final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
    if (x == null) return;
    await _dosyaYukle(File(x.path));
  }

  /// Tek yükleme yolu: seçilen · sürüklenen · yapıştırılan dosyalar buradan gider (ilerleme çubuğu, hata bildirimi).
  Future<void> _dosyaYukle(File f) async {
    if (_kapali) {
      bildir('Sohbet kapalı', mesaj: 'Kapalı sohbete dosya gönderilemez.', tur: MesajTur.uyari);
      return;
    }
    if (!f.existsSync()) return;
    if (f.lengthSync() > 25 * 1024 * 1024) {
      bildir('Dosya çok büyük', mesaj: 'En çok 25 MB gönderilebilir.', tur: MesajTur.uyari);
      return;
    }
    setState(() => _yuklemeOrani = 0);
    try {
      final m = await Depo.dosyaGonder(
        _id,
        f,
        ilerleme: (a, b) {
          if (mounted && b > 0) setState(() => _yuklemeOrani = a / b);
        },
      );
      if (mounted) setState(() => _mesajEkle(m));
      _altaKay();
      _hizlan();
    } catch (e) {
      bildir('Dosya gönderilemedi', mesaj: hataMetni(e), tur: MesajTur.hata);
    } finally {
      if (mounted) setState(() => _yuklemeOrani = null);
    }
  }

  /// Bellekteki baytları (pano görseli) geçici dosyaya yazıp gönderir.
  Future<void> _baytGonder(Uint8List b, String ad) async {
    final d = Directory('${Directory.systemTemp.path}/bogahost-destek');
    if (!d.existsSync()) d.createSync(recursive: true);
    final f = File('${d.path}/$ad');
    await f.writeAsBytes(b, flush: true);
    await _dosyaYukle(f);
  }

  /// Ctrl+V / Cmd+V: panoda görsel ya da dosya varsa ek olarak gönderir; yoksa metin yapıştırma alanın kendi davranışıyla sürer.
  Future<void> _yapistir() async {
    if (_yanitYetkisi && !_kapali) {
      try {
        final g = await Pasteboard.image;
        if (g != null && g.isNotEmpty) {
          await _baytGonder(g, 'yapistirilan-${DateTime.now().millisecondsSinceEpoch}.png');
          return;
        }
        final yollar = await Pasteboard.files();
        if (yollar.isNotEmpty) {
          for (final y in yollar) {
            await _dosyaYukle(File(y));
          }
          return;
        }
      } catch (_) {
        // pano erişimi yoksa metin yapıştırmaya düş
      }
    }
    final c = _odak.context;
    if (c != null && c.mounted) Actions.maybeInvoke(c, const PasteTextIntent(SelectionChangedCause.keyboard));
  }

  Future<void> _surukleBirak(DropDoneDetails d) async {
    for (final x in d.files) {
      await _dosyaYukle(File(x.path));
    }
  }

  /// Transkript PDF'i: masaüstünde "farklı kaydet", telefonda geçici dosyaya yazıp açar.
  Future<void> _pdfIndir() async {
    final b = await islem(() => Depo.transkriptPdf(_id));
    if (b == null || !mounted) return;
    final ad = 'transkript-$_id.pdf';
    if (Platform.isAndroid || Platform.isIOS) {
      final d = Directory('${Directory.systemTemp.path}/bogahost-destek');
      if (!d.existsSync()) d.createSync(recursive: true);
      final f = File('${d.path}/$ad');
      await f.writeAsBytes(b, flush: true);
      final r = await OpenFilex.open(f.path);
      if (r.type != ResultType.done) bildir('PDF açılamadı', mesaj: r.message, tur: MesajTur.uyari);
      return;
    }
    // file_picker 13: saveFile baytları kendisi yazar (Uri döner).
    final yol = await FilePicker.saveFile(dialogTitle: 'Transkripti kaydet', fileName: ad, bytes: b, mimeType: 'application/pdf');
    if (yol == null) return;
    bildir('PDF kaydedildi', mesaj: yol.toFilePath(), tur: MesajTur.basari);
  }

  /// Dil / çeviri (web: changeLang): ziyaretçi widget dili zorlanır, son mesajlar çevrilir.
  Future<void> _dilSec() async {
    const diller = {
      'tr': 'Türkçe',
      'en': 'English',
      'de': 'Deutsch',
      'fr': 'Français',
      'ar': 'العربية',
      'ru': 'Русский',
      'es': 'Español',
      'it': 'Italiano',
      'nl': 'Nederlands',
      'pt': 'Português',
      'fa': 'فارسی',
      'az': 'Azərbaycan',
      'uk': 'Українська',
      'zh': '中文',
    };
    final simdiki = _son?.dil ?? '';
    final v = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Ziyaretçi dili'),
        children: [
          for (final e in diller.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, e.key),
              child: Row(
                children: [
                  Expanded(child: Text(e.value)),
                  if (e.key == simdiki) const Icon(Simgeler.check, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
    if (v == null) return;
    await islem(() => Depo.dilAyarla(_id, v), tamam: 'Dil ${diller[v]} olarak ayarlandı');
  }

  /// Ziyaretçi talebi şeridi: Başlat → ilgili görüşme; Yoksay → sunucuda temizle.
  Future<void> _talepYanitla(bool kabul) async {
    final t = _talep;
    if (t == null) return;
    final tur = '${t['type']}';
    await islem(() => Depo.iletisimTalebiTemizle(_id));
    _sonTalep = '';
    if (!kabul || !mounted) {
      _yokla();
      return;
    }
    switch (tur) {
      case 'voice':
        await AramaEkrani.baslat(context, sohbetId: _id, ad: _ad, video: false);
      case 'video':
        await AramaEkrani.baslat(context, sohbetId: _id, ad: _ad, video: true);
      case 'screen':
        if (_son?.oturumId != null) await EkranIzleEkrani.ac(context, oturumId: _son!.oturumId!, ad: _ad, kip: 'direct', sohbetId: _id, url: _son?.url);
    }
    _yokla();
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
        await islem(() => Depo.favori(_id), tamam: _favori ? 'Önemli işareti kaldırıldı' : 'Önemli olarak işaretlendi');
        _detayYukle();
      case 'arsiv':
        await islem(() => Depo.arsivle(_id), tamam: _arsiv ? 'Arşivden çıkarıldı' : 'Arşivlendi');
        _detayYukle();
      case 'kacan':
        await islem(() => Depo.kacanCozuldu(_id), tamam: 'Kaçan sohbet işlendi');
        _detayYukle();
      case 'pdf':
        await _pdfIndir();
      case 'iptal':
        await IptalTalebiEkrani.ac(context, sohbetId: _id, ad: _ad);
      case 'dil':
        await _dilSec();
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
      case 'sesli':
        if (!await _aramaOnay() || !mounted) return;
        await AramaEkrani.baslat(context, sohbetId: _id, ad: _ad, video: false);
      case 'goruntulu':
        if (!await _aramaOnay() || !mounted) return;
        await AramaEkrani.baslat(context, sohbetId: _id, ad: _ad, video: true);
      case 'ekran':
        if (_son?.oturumId != null) await EkranIzleEkrani.sec(context, oturumId: _son!.oturumId!, ad: _ad, sohbetId: _id, url: _son?.url);
      case 'ekranDirekt':
        if (_son?.oturumId != null &&
            await onayla(context, 'Onaysız ekran izleme', mesaj: 'Ziyaretçiye izin sorulmaz; denetim kaydına yazılır. Devam edilsin mi?', evet: 'İzle')) {
          if (mounted) await EkranIzleEkrani.ac(context, oturumId: _son!.oturumId!, ad: _ad, kip: 'direct', sohbetId: _id, url: _son?.url);
        }
      case 'ziyaretci':
        if (_son?.oturumId != null) await ZiyaretciDetayEkrani.ac(context, _son!.oturumId!, ad: _ad);
    }
    _yokla();
  }

  /// Web panelindeki "Talep Formu Gönder" modalıyla aynı: form türü (Genel Destek · Ödeme Bildirimi · İptal Talebi),
  /// birim yalnız genel destekte (varsayılan "Otomatik"), kısa not iptalde gizli; iptal için WHMCS müşterisi + yetki şart.
  Future<void> _talepFormu() async {
    final bolumler = await islem(() => Depo.talepBolumleri());
    if (bolumler == null || !mounted) return;
    final iptalYetkisi = Uyg.yetki('chats.cancel_request');
    final whmcs = _whmcsId;
    var kip = 'general';
    var bolum = 0;
    final konu = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) {
          final r = c.r;
          final iptalOlur = iptalYetkisi && whmcs != null;
          Widget secenek(String deger, String ad, String aciklama, {bool acik = true}) => RadioListTile<String>(
            value: deger,
            enabled: acik,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              ad,
              style: TextStyle(fontWeight: FontWeight.w600, color: acik ? r.metin : r.silik),
            ),
            subtitle: Text(aciklama, style: TextStyle(fontSize: 12, color: r.silik)),
          );
          return AlertDialog(
            title: const Text('Talep formu gönder'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ziyaretçinin sohbet penceresinde bir form açılır; doldurunca WHMCS destek talebi oluşur.',
                      style: TextStyle(fontSize: 12.5, color: r.soluk),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<String>(
                      groupValue: kip,
                      onChanged: (v) => set(() => kip = v ?? 'general'),
                      child: Column(
                        children: [
                          secenek('general', 'Genel destek', 'Seçilen birime destek talebi açar.'),
                          secenek('payment', 'Ödeme bildirimi', 'Muhasebe birimine ödeme bildirimi formu.'),
                          if (iptalYetkisi)
                            secenek(
                              'cancel',
                              'İptal talebi',
                              iptalOlur
                                  ? 'Müşteri hizmet seçip iptal talebi formunu doldurur.'
                                  : 'Bu ziyaretçi WHMCS müşterisiyle eşleşmedi; iptal formu gönderilemez.',
                              acik: iptalOlur,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (kip == 'general')
                      DropdownButtonFormField<int>(
                        initialValue: bolum,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Birim (departman)'),
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('— Otomatik (ilk departman) —')),
                          for (final b in bolumler)
                            DropdownMenuItem(
                              value: (b['id'] as num? ?? 0).toInt(),
                              child: Text('${b['name']}', overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => set(() => bolum = v ?? 0),
                      )
                    else if (kip == 'payment')
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Birim'),
                        child: Text('Muhasebe (otomatik)', style: TextStyle(color: r.metin)),
                      ),
                    if (kip != 'cancel') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: konu,
                        maxLength: 190,
                        decoration: const InputDecoration(labelText: 'Kısa not / konu (isteğe bağlı)', counterText: ''),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
              FilledButton.icon(
                onPressed: kip == 'cancel' && !iptalOlur ? null : () => Navigator.pop(c, true),
                icon: const Icon(Simgeler.send, size: 16),
                label: const Text('Ziyaretçiye gönder'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    await islem(
      () => Depo.talepFormu(_id, kip: kip, bolum: kip == 'general' ? bolum : 0, konu: kip == 'cancel' ? '' : konu.text.trim()),
      tamam: switch (kip) {
        'payment' => 'Ödeme bildirimi formu ziyaretçiye gönderildi',
        'cancel' => 'İptal talebi formu ziyaretçiye gönderildi',
        _ => 'Destek talebi formu ziyaretçiye gönderildi',
      },
    );
    _hizlan();
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
    final govdeSutun = Column(
      children: [
        Expanded(
          child: _hata != null
              ? Durum.hata(_hata!, tekrar: _yokla)
              : _son == null
              ? const Durum.yukleniyor()
              : _mesajlar.isEmpty
              ? Durum.bos('Henüz mesaj yok.', ikon: Simgeler.forum)
              : _secilebilir(
                  ListView.builder(
                    controller: _kaydirma,
                    padding: EdgeInsets.fromLTRB(genis ? 24 : 12, 12, genis ? 24 : 12, 8),
                    itemCount: _mesajlar.length,
                    itemBuilder: (_, i) =>
                        KeyedSubtree(key: ValueKey(_mesajlar[i].id), child: _balon(_mesajlar[i], i == 0 ? null : _mesajlar[i - 1], r, genis)),
                  ),
                ),
        ),
        if (_talep != null && !_kapali) _talepSeridi(r),
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
    // Geniş ekranda mesaj sütunu en çok 1180 px: balonlar ve yazım kutusu ortada, uçsuz bucaksız boşluk yok.
    final ortali = genis ? ortala(govdeSutun, enCok: 1180) : govdeSutun;
    // Masaüstünde dosya sürükle-bırak (web: "Dosyayı buraya bırak").
    final govde = Platform.isIOS
        ? ortali
        : DropTarget(
            onDragEntered: (_) => setState(() => _surukleniyor = true),
            onDragExited: (_) => setState(() => _surukleniyor = false),
            onDragDone: (d) {
              setState(() => _surukleniyor = false);
              _surukleBirak(d);
            },
            child: Stack(
              children: [
                ortali,
                if (_surukleniyor)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: r.vurgu.withValues(alpha: .10),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                          decoration: BoxDecoration(
                            color: r.kart,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: r.vurgu, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Simgeler.attachFile, color: r.vurgu),
                              const SizedBox(width: 8),
                              Text(
                                'Dosyayı buraya bırakın',
                                style: TextStyle(color: r.metin, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
    final ekran = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.gomulu,
        titleSpacing: widget.gomulu ? 16 : 0,
        toolbarHeight: 60,
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
          if (_aramaOlur) ...[
            IconButton(tooltip: 'Sesli arama', onPressed: () => _eylem('sesli'), icon: const Icon(Simgeler.phoneCall)),
            IconButton(tooltip: 'Görüntülü arama', onPressed: () => _eylem('goruntulu'), icon: const Icon(Simgeler.videocam)),
          ],
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
              if (_son?.oturumId != null) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'ziyaretci',
                  child: ListTile(dense: true, leading: Icon(Simgeler.userCircle), title: Text('Ziyaretçi detayı / CRM')),
                ),
                if (_aramaOlur) ...[
                  const PopupMenuItem(
                    value: 'sesli',
                    child: ListTile(dense: true, leading: Icon(Simgeler.phoneCall), title: Text('Sesli arama')),
                  ),
                  const PopupMenuItem(
                    value: 'goruntulu',
                    child: ListTile(dense: true, leading: Icon(Simgeler.videocam), title: Text('Görüntülü arama')),
                  ),
                ],
                if (Uyg.yetki('screen.consent') || Uyg.yetki('screen.direct'))
                  const PopupMenuItem(
                    value: 'ekran',
                    child: ListTile(dense: true, leading: Icon(Simgeler.monitor), title: Text('Canlı ekran izle')),
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
              if (Uyg.yetki('chats.cancel_request'))
                const PopupMenuItem(
                  value: 'iptal',
                  child: ListTile(dense: true, leading: Icon(Simgeler.cancel), title: Text('Hizmetler & iptal talebi')),
                ),
              if (_yanitYetkisi && _ceviriAcik && !_kapali)
                PopupMenuItem(
                  value: 'dil',
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Simgeler.language),
                    title: Text('Ziyaretçi dili${_son?.dil != null ? ' (${_son!.dil!.toUpperCase()})' : ''}'),
                  ),
                ),
              if (Uyg.yetki('chats.transcript')) ...[
                const PopupMenuItem(
                  value: 'eposta',
                  child: ListTile(dense: true, leading: Icon(Simgeler.mailOutline), title: Text('Transkripti e-postala')),
                ),
                const PopupMenuItem(
                  value: 'baglanti',
                  child: ListTile(dense: true, leading: Icon(Simgeler.copy), title: Text('Transkript bağlantısını kopyala')),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(dense: true, leading: Icon(Simgeler.filePresent), title: Text('PDF indir')),
                ),
              ],
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'favori',
                child: ListTile(
                  dense: true,
                  leading: Icon(_favori ? simgeDolu(Simgeler.starOutline) : Simgeler.starOutline, color: _favori ? Marka.kehribar : null),
                  title: Text(_favori ? 'Önemli işaretini kaldır' : 'Önemli işaretle'),
                ),
              ),
              PopupMenuItem(
                value: 'arsiv',
                child: ListTile(dense: true, leading: const Icon(Simgeler.archive), title: Text(_arsiv ? 'Arşivden çıkar' : 'Arşivle')),
              ),
              if (_kacan && _yanitYetkisi)
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
                  width: (MediaQuery.sizeOf(context).width * .26).clamp(340.0, 460.0),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: r.kenar)),
                  ),
                  child: _bilgiPaneli(r),
                ),
              ],
            )
          : govde,
      endDrawer: genis ? null : Drawer(width: 360, child: _bilgiPaneli(r)),
    );
    if (!genis && _bilgiAcik) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bilgiAcik = false;
        if (mounted) Scaffold.of(context).openEndDrawer();
      });
    }
    return ekran;
  }

  /// Masaüstünde fareyle metin seçimi tek seçim alanıyla (balon başına SelectableText pahalıydı); telefonda uzun basış menüsünden kopyalanır.
  Widget _secilebilir(Widget w) => Platform.isAndroid || Platform.isIOS ? w : SelectionArea(child: w);

  Widget _talepSeridi(Renkler r) {
    final t = _talep!;
    final tur = '${t['type']}';
    final ad = switch (tur) {
      'voice' => 'sesli görüşme',
      'video' => 'görüntülü görüşme',
      'screen' => 'ekran paylaşımı',
      _ => 'görüşme',
    };
    final ikon = switch (tur) {
      'voice' => Simgeler.phoneCall,
      'video' => Simgeler.videocam,
      _ => Simgeler.monitor,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      color: Marka.kehribar.withValues(alpha: .14),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: Marka.kehribar),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Ziyaretçi $ad istiyor',
              style: TextStyle(color: r.metin, fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
          TextButton(onPressed: () => _talepYanitla(false), child: const Text('Yoksay')),
          const SizedBox(width: 4),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Marka.kehribar, foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
            onPressed: () => _talepYanitla(true),
            icon: Icon(ikon, size: 16),
            label: const Text('Başlat'),
          ),
        ],
      ),
    );
  }

  Widget _balon(Mesaj m, Mesaj? onceki, Renkler r, bool genis) {
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
            child: Text(
              '${m.govde ?? ''} · ${m.saat}',
              style: TextStyle(color: r.silik, fontSize: genis ? 12.5 : 11.5),
            ),
          ),
        ),
      );
    }
    final sag = !m.ziyaretci;
    final icNot = m.icNot || m.fisilti;
    final yaziBoyu = genis ? 15.5 : 14.5;
    final avatarBoyu = genis ? 34.0 : 28.0;
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
          if (!sag) ...[yeniGonderen ? Avatar(m.ad.isEmpty ? 'Z' : m.ad, boyut: avatarBoyu) : SizedBox(width: avatarBoyu), const SizedBox(width: 8)],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _mesajMenusu(m),
              onSecondaryTap: () => _mesajMenusu(m),
              child: Container(
                constraints: BoxConstraints(maxWidth: genis ? 760 : 560),
                padding: EdgeInsets.fromLTRB(genis ? 14 : 12, genis ? 10 : 8, genis ? 14 : 12, genis ? 8 : 6),
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
                          style: TextStyle(
                            fontSize: genis ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: icNot ? Marka.kehribar : Colors.white.withValues(alpha: .85),
                          ),
                        ),
                      ),
                    if (m.ek != null) _ekGorunumu(m.ek!, yazi, r),
                    if (m.silindi)
                      Text(
                        'Bu mesaj silindi',
                        style: TextStyle(color: yazi.withValues(alpha: .7), fontStyle: FontStyle.italic, fontSize: yaziBoyu),
                      )
                    else if (m.govde != null && m.govde!.isNotEmpty)
                      Text(
                        m.govde!,
                        style: TextStyle(color: yazi, fontSize: yaziBoyu, height: 1.4),
                      ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (m.duzenlendi)
                          Text(
                            'düzenlendi · ',
                            style: TextStyle(color: yazi.withValues(alpha: .65), fontSize: genis ? 11.5 : 10.5),
                          ),
                        Text(
                          m.saat,
                          style: TextStyle(color: yazi.withValues(alpha: .65), fontSize: genis ? 11.5 : 10.5),
                        ),
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
                cacheWidth: 720,
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
            if (_aiDevredildi || _aiTur > 0) _aiSeridi(r),
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
                IconButton(
                  tooltip: 'Yapay zeka yanıt önerisi',
                  onPressed: _aiBekliyor ? null : _aiOner,
                  icon: _aiBekliyor
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Simgeler.sparkle, color: Marka.mor),
                ),
                Expanded(
                  child: Shortcuts(
                    shortcuts: {
                      const SingleActivator(LogicalKeyboardKey.enter): const _GonderNiyeti(),
                      const SingleActivator(LogicalKeyboardKey.enter, meta: true): const _GonderNiyeti(),
                      const SingleActivator(LogicalKeyboardKey.enter, control: true): const _GonderNiyeti(),
                      const SingleActivator(LogicalKeyboardKey.keyV, control: true): const _YapistirNiyeti(),
                      const SingleActivator(LogicalKeyboardKey.keyV, meta: true): const _YapistirNiyeti(),
                      const SingleActivator(LogicalKeyboardKey.insert, shift: true): const _YapistirNiyeti(),
                    },
                    child: Actions(
                      actions: {
                        _GonderNiyeti: CallbackAction<_GonderNiyeti>(onInvoke: (_) => _gonder()),
                        _YapistirNiyeti: CallbackAction<_YapistirNiyeti>(onInvoke: (_) => _yapistir()),
                      },
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
                              : Platform.isAndroid || Platform.isIOS
                              ? 'Yanıt yazın · / hazır yanıt'
                              : 'Yanıt yazın · / hazır yanıt · Ctrl+V ile görsel',
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

  Widget _bilgiPaneli(Renkler r) => SohbetZiyaretciPaneli(
    key: ValueKey('zb$_id'),
    sohbetId: _id,
    kapat: () {
      if (context.genis) {
        setState(() => _bilgiAcik = false);
      } else {
        Navigator.pop(context);
      }
    },
  );
}

class _YapistirNiyeti extends Intent {
  const _YapistirNiyeti();
}

class _GonderNiyeti extends Intent {
  const _GonderNiyeti();
}
