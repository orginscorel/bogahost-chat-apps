import 'dart:async';
import 'dart:convert';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/json.dart';
import '../veri/panel.dart';

/// Ziyaretçi ekranı izleme (co-browse): widget'ın gönderdiği DOM anlık görüntüsü web görünümünde çizilir,
/// kaydırma konumu ve fare imleci eşlenir. "Yönlendir" kipinde dokunulan nokta ziyaretçinin ekranında işaret olur.
/// [kip] consent → ziyaretçiden izin ister; direct → onaysız (screen.direct yetkisi, hassas).
class EkranIzleEkrani extends StatefulWidget {
  const EkranIzleEkrani({super.key, required this.oturumId, required this.ad, this.kip = 'consent', this.sohbetId, this.url});
  final int oturumId;
  final String ad;
  final String kip;
  final int? sohbetId;
  final String? url;

  static Future<void> ac(BuildContext context, {required int oturumId, required String ad, String kip = 'consent', int? sohbetId, String? url}) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => EkranIzleEkrani(oturumId: oturumId, ad: ad, kip: kip, sohbetId: sohbetId, url: url),
        ),
      );

  /// Web panelindeki gibi önce yöntem sorulur: İzinli co-browse (önerilen) ya da İzinsiz izle (screen.direct yetkisi).
  /// Seçilince izleme ekranı açılır.
  static Future<void> sec(BuildContext context, {required int oturumId, required String ad, int? sohbetId, String? url}) async {
    final izinli = Uyg.yetki('screen.consent'), dogrudan = Uyg.yetki('screen.direct');
    if (!izinli && !dogrudan) {
      bildir('Ekran izleme yetkiniz yok.', tur: MesajTur.hata);
      return;
    }
    final kip = await showDialog<String>(
      context: context,
      builder: (c) {
        final r = c.r;
        Widget secenek(String deger, String baslik, String aciklama, IconData ikon, Color renk, {bool onerilen = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(c, deger),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: onerilen ? renk.withValues(alpha: .07) : r.kart,
                border: Border.all(color: onerilen ? renk : r.kenar, width: onerilen ? 1.6 : 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: renk.withValues(alpha: .14), borderRadius: BorderRadius.circular(12)),
                    child: Icon(ikon, color: renk, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              baslik,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: r.metin),
                            ),
                            if (onerilen) ...[const SizedBox(width: 8), Rozet('önerilen', renk: renk)],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(aciklama, style: TextStyle(color: r.soluk, fontSize: 13, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return AlertDialog(
          title: const Text('Canlı Ekran İzleme'),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('$ad için izleme yöntemini seçin:', style: TextStyle(color: c.r.soluk, fontSize: 13.5)),
                ),
                if (izinli)
                  secenek(
                    'consent',
                    'İzinli co-browse',
                    'Ziyaretçiye onay istemi gönderilir; kabul ederse başlar ve "paylaşılıyor" göstergesi çıkar. Hassas alanlar otomatik gizlenir, görsel yönlendirme yapabilirsiniz.',
                    Simgeler.visibility,
                    Marka.zumrut,
                    onerilen: true,
                  ),
                if (dogrudan)
                  secenek(
                    'direct',
                    'İzinsiz izle',
                    'Ziyaretçiye istem çıkmaz, izleme anında başlar (çerez/gizlilik politikanız kapsamında). Hassas alanlar yine maskelenir; denetim kaydına yazılır.',
                    Simgeler.bolt,
                    Marka.kehribar,
                  ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Vazgeç'))],
        );
      },
    );
    if (kip == null || !context.mounted) return;
    await ac(context, oturumId: oturumId, ad: ad, kip: kip, sohbetId: sohbetId, url: url);
  }

  @override
  State<EkranIzleEkrani> createState() => _EkranIzleEkraniState();
}

class _EkranIzleEkraniState extends State<EkranIzleEkrani> {
  InAppWebViewController? _web;
  Timer? _yoklama, _kaydirZaman;
  CancelToken _iptal = CancelToken();
  String _durum = 'connecting';
  String? _hata;
  Object? _hv;
  // Ziyaretçinin görüntü alanı (sw×sh), kaydırması (sx,sy) ve imleci (px,py; sayfa koordinatı).
  double _sw = 1280, _sh = 800, _sx = 0, _sy = 0, _px = 0, _py = 0;
  // "Kaydır" kipinde temsilcinin kendi kaydırma konumu.
  double _kx = 0, _ky = 0;
  bool _yonlendir = false, _kaydir = false, _kareVar = false, _yukleniyor = false, _isaretUyarildi = false, _durdu = false;
  int _hataSayisi = 0;
  String? _baseUrl;
  String? _sonHtml;

  /// Web görünümü bir kez kurulur; durum değişimlerinde yeniden oluşturulmaz.
  late final Widget _webKatmani = RepaintBoundary(
    child: IgnorePointer(
      child: InAppWebView(
        initialSettings: InAppWebViewSettings(
          // scrollTo ile kaydırma eşlemesi için gerekli; sayfa betikleri temizlenir ve CSP ile engellenir.
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: false,
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: true,
          transparentBackground: false,
          supportZoom: false,
          disableContextMenu: true,
        ),
        onWebViewCreated: (c) {
          _web = c;
          if (_sonHtml != null) {
            _htmlYukle();
          } else {
            c.loadData(data: '<html><body style="background:#fff;font-family:sans-serif;color:#64748b;padding:24px">Ekran görüntüsü bekleniyor…</body></html>');
          }
        },
        onLoadStop: (_, _) => _kaydirUygula(),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  double get _gorX => _kaydir ? _kx : _sx;
  double get _gorY => _kaydir ? _ky : _sy;

  Future<void> _baslat() async {
    _yoklama?.cancel();
    _yoklama = null;
    if (_iptal.isCancelled) _iptal = CancelToken();
    if (mounted) {
      setState(() {
        _hata = null;
        _durum = 'connecting';
        _hataSayisi = 0;
      });
    }
    _hv = null;
    try {
      await Panel.ekranIste(widget.oturumId, kip: widget.kip);
    } catch (e) {
      if (mounted) setState(() => _hata = hataMetni(e));
      return;
    }
    if (!mounted) return;
    _yoklama = Timer.periodic(const Duration(milliseconds: 1200), (_) => _yokla());
    _yokla();
  }

  Future<void> _yokla() async {
    if (_yukleniyor || !mounted) return;
    _yukleniyor = true;
    try {
      final d = await Panel.ekranAlHizli(widget.oturumId, hv: _hv, iptal: _iptal);
      if (!mounted) return;
      var degisti = _hataSayisi >= 3;
      _hataSayisi = 0;
      final st = metin(d['state'], 'idle');
      if (st != _durum) {
        _durum = st;
        degisti = true;
      }
      if (st == 'ended' || st == 'declined') {
        _yoklama?.cancel();
        _yoklama = null;
      }
      final s = d['snapshot'];
      if (st == 'active' && s is Map) {
        final m = harita(s);
        final sw = ondalik(m['sw'], 1280), sh = ondalik(m['sh'], 800);
        if (sw != _sw || sh != _sh) {
          _sw = sw;
          _sh = sh;
          degisti = true;
        }
        final px = ondalik(m['px']), py = ondalik(m['py']);
        if (px != _px || py != _py) {
          _px = px;
          _py = py;
          degisti = true;
        }
        final sx = ondalik(m['sx']), sy = ondalik(m['sy']);
        final kaydirmaDegisti = sx != _sx || sy != _sy;
        _sx = sx;
        _sy = sy;
        final url = metinYa(m['url']);
        final urlDegisti = url != null && url != _baseUrl;
        if (url != null) {
          _baseUrl = url;
        } else {
          _baseUrl ??= widget.url;
        }
        final html = m['html'];
        if (html is String && html.isNotEmpty && (m['hv'] != _hv || urlDegisti || !_kareVar)) {
          _hv = m['hv'];
          _sonHtml = _temizle(html, _baseUrl);
          final ilk = !_kareVar;
          if (ilk) {
            await _htmlYukle(); // ilk kare: görünür olana kadar bekle
            _kareVar = true;
            degisti = true;
          } else {
            unawaited(_htmlYukle()); // sonraki kareler arka planda; yoklama durmaz
          }
        } else {
          // Adres değişti ama HTML gelmediyse bir sonraki turda tam kare iste.
          if (urlDegisti && _kareVar) _hv = null;
          if (kaydirmaDegisti && !_kaydir) await _kaydirUygula();
        }
        if (kaydirmaDegisti && !_kaydir) degisti = true;
      }
      if (degisti && mounted) setState(() {});
    } on IstekIptal {
      return;
    } catch (_) {
      _hataSayisi++;
      if (_hataSayisi == 3 && mounted) setState(() {});
    } finally {
      _yukleniyor = false;
    }
  }

  /// Anlık görüntüdeki betikleri ve olay özniteliklerini temizler; kaydırma çubuklarını gizler, `<base>` ve CSP ekler.
  static String _temizle(String html, String? base) {
    var h = html
        .replaceAll(RegExp(r'<script\b[^>]*>[\s\S]*?</script\s*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<script\b[^>]*/?>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<meta[^>]+http-equiv\s*=\s*["\x27]?refresh[^>]*>', caseSensitive: false), '')
        .replaceAll(RegExp(r'\son[a-z]+\s*=\s*("[^"]*"|\x27[^\x27]*\x27|[^\s>]+)', caseSensitive: false), '');
    final ek = StringBuffer(
      '<meta http-equiv="Content-Security-Policy" content="script-src \'none\'; object-src \'none\'">'
      '<style>html,body{overflow:hidden!important}</style>',
    );
    if (base != null && !RegExp(r'<base\b', caseSensitive: false).hasMatch(h)) {
      ek.write('<base href="${base.replaceAll('&', '&amp;').replaceAll('"', '&quot;')}">');
    }
    final bas = RegExp(r'<head\b[^>]*>', caseSensitive: false).firstMatch(h);
    if (bas != null) {
      h = h.replaceRange(bas.end, bas.end, ek.toString());
    } else {
      final kok = RegExp(r'<html\b[^>]*>', caseSensitive: false).firstMatch(h);
      h = kok != null ? h.replaceRange(kok.end, kok.end, '<head>$ek</head>') : '<head>$ek</head>$h';
    }
    return h;
  }

  bool _uygulaniyor = false, _bekleyenKare = false;
  String? _yuklenenBase;

  /// Kareyi web görünümüne uygular. İlk kare (ya da adres değişince) tam yükleme; sonrakiler mevcut sayfada
  /// DOM değişimi (betiksiz HTML, aynı base) — tam yeniden yükleme her karede 5-10 sn sürüp uygulamayı kilitliyordu.
  Future<void> _htmlYukle() async {
    if (_uygulaniyor) {
      _bekleyenKare = true; // uygulama sürerken gelen kareler birleşir, en son kare uygulanır
      return;
    }
    _uygulaniyor = true;
    try {
      do {
        _bekleyenKare = false;
        final w = _web, html = _sonHtml;
        if (w == null || html == null) break;
        final tamYukle = !_kareVar || _yuklenenBase != _baseUrl;
        try {
          if (tamYukle) {
            _yuklenenBase = _baseUrl;
            await w
                .loadData(data: html, baseUrl: _baseUrl != null ? WebUri(_baseUrl!) : null, mimeType: 'text/html', encoding: 'utf-8')
                .timeout(const Duration(seconds: 8));
          } else {
            final js = jsonEncode(html);
            await w
                .evaluateJavascript(
                  source:
                      '(function(h){try{var d=new DOMParser().parseFromString(h,"text/html");document.replaceChild(document.adoptNode(d.documentElement),document.documentElement);}catch(e){document.documentElement.innerHTML=h;}window.scrollTo(${_gorX.round()},${_gorY.round()});})($js);',
                )
                .timeout(const Duration(seconds: 4));
          }
        } catch (_) {}
      } while (_bekleyenKare && mounted);
    } finally {
      _uygulaniyor = false;
    }
  }

  /// Görünümü geçerli konuma kaydırır (Kaydır açıkken temsilcinin, değilse ziyaretçinin konumu).
  Future<void> _kaydirUygula() async {
    final w = _web;
    if (w == null || _sonHtml == null) return;
    try {
      await w.evaluateJavascript(source: 'window.scrollTo(${_gorX.round()}, ${_gorY.round()});');
    } catch (_) {}
  }

  // ---- Kaydır (temsilci sayfayı kaydırır, ziyaretçinin sayfası izler)
  void _kaydirAcKapa(bool v) {
    _kaydirZaman?.cancel();
    setState(() {
      _kaydir = v;
      if (v) {
        _kx = _sx;
        _ky = _sy;
      }
    });
    if (!v) {
      _kaydirTemizle();
      _kaydirUygula();
    }
  }

  void _kaydirTemizle() {
    final oturum = widget.oturumId;
    unawaited(() async {
      try {
        await Panel.ekranKaydir(oturum, null, null);
      } catch (_) {}
    }());
  }

  Future<void> _kaydirEkle(double dx, double dy) async {
    if (!_kaydir || !_kareVar) return;
    final hx = (_kx + dx).clamp(0.0, double.infinity), hy = (_ky + dy).clamp(0.0, double.infinity);
    if (hx == _kx && hy == _ky) return;
    setState(() {
      _kx = hx;
      _ky = hy;
    });
    _kaydirZaman?.cancel();
    _kaydirZaman = Timer(const Duration(milliseconds: 150), () async {
      if (!_kaydir || !mounted) return;
      try {
        await Panel.ekranKaydir(widget.oturumId, _kx.round(), _ky.round());
      } catch (_) {}
    });
    final w = _web;
    if (w == null) return;
    try {
      // Sayfa sonunu aşan konum tarayıcıda kırpılır; gerçek konumu geri okuyup birikimi sınırla.
      final r = await w.evaluateJavascript(source: '(function(){window.scrollTo(${hx.round()},${hy.round()});return [window.scrollX,window.scrollY];})()');
      if (r is List && r.length == 2 && mounted && _kaydir) {
        final gx = ondalik(r[0], hx), gy = ondalik(r[1], hy);
        final kx = gx < hx && _kx == hx, ky = gy < hy && _ky == hy;
        if (kx || ky) {
          setState(() {
            if (kx) _kx = gx;
            if (ky) _ky = gy;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _isaretGonder(double x, double y) async {
    try {
      await Panel.ekranIsaret(widget.oturumId, x: x, y: y, etiket: 'Buraya bakın');
      bildir('İşaret gönderildi', tur: MesajTur.basari);
    } on ApiHata catch (e) {
      if (e.durum == 403 || e.kod == 'forbidden') {
        if (!_isaretUyarildi) {
          _isaretUyarildi = true;
          bildir('Bu izleme kipinde yönlendirme yapılamıyor.', tur: MesajTur.uyari);
        }
      } else {
        bildir(hataMetni(e), tur: MesajTur.hata);
      }
    } catch (e) {
      bildir(hataMetni(e), tur: MesajTur.hata);
    }
  }

  Future<void> _kapat() async {
    _yoklama?.cancel();
    _kaydirZaman?.cancel();
    _iptal.cancel();
    _durdu = true;
    try {
      if (_kaydir) await Panel.ekranKaydir(widget.oturumId, null, null);
    } catch (_) {}
    try {
      await Panel.ekranIsaret(widget.oturumId);
      await Panel.ekranDurdur(widget.oturumId);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _yoklama?.cancel();
    _kaydirZaman?.cancel();
    _iptal.cancel();
    if (!_durdu) {
      // Kapat düğmesi dışında çıkıldı (geri hareketi vb.): sunucuya sessizce bildir.
      final oturum = widget.oturumId, kaydir = _kaydir;
      unawaited(() async {
        try {
          if (kaydir) await Panel.ekranKaydir(oturum, null, null);
        } catch (_) {}
      }());
      unawaited(() async {
        try {
          await Panel.ekranIsaret(oturum);
        } catch (_) {}
      }());
      unawaited(() async {
        try {
          await Panel.ekranDurdur(oturum);
        } catch (_) {}
      }());
    }
    super.dispose();
  }

  String get _durumMetni => switch (_durum) {
    'active' => _kareVar ? 'Canlı' : 'Ekran görüntüsü alınıyor…',
    'pending' => 'Ziyaretçinin ekran paylaşımına izin vermesi bekleniyor…',
    'declined' => 'Ziyaretçi ekran paylaşımını reddetti.',
    'ended' => 'Paylaşım sona erdi.',
    _ => 'Bağlanıyor…',
  };

  bool get _bitti => _durum == 'ended' || _durum == 'declined';

  Widget _kucukCip(String yazi, IconData ikon, Color renk) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: renk.withValues(alpha: .92), borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          yazi,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _cip(String etiket, IconData ikon, bool secili, ValueChanged<bool> degis) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Material(
      color: secili ? Colors.white : Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => degis(!secili),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon, size: 16, color: secili ? Marka.mor : Colors.white),
              const SizedBox(width: 6),
              Text(
                etiket,
                style: TextStyle(color: secili ? Marka.mor : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      backgroundColor: Marka.grafit,
      appBar: AppBar(
        backgroundColor: Marka.grafit,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Nokta(_durum == 'active' && _kareVar ? Marka.yesil : Marka.kehribar, boyut: 9),
            const SizedBox(width: 8),
            Expanded(child: Text('${widget.ad} · ekran', maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        leading: IconButton(icon: const Icon(Simgeler.close), tooltip: 'Kapat', onPressed: _kapat),
        actions: [
          if (_durum == 'active') ...[
            _cip('Yönlendir', Simgeler.handPointing, _yonlendir, (v) => setState(() => _yonlendir = v)),
            _cip('Kaydır', Simgeler.swapVert, _kaydir, _kaydirAcKapa),
          ],
        ],
      ),
      body: _hata != null
          ? Durum.hata(_hata!, tekrar: _baslat)
          : Column(
              children: [
                if (_durum != 'active' || !_kareVar)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: _bitti ? 4 : 10),
                    color: _durum == 'declined' ? Marka.gul.withValues(alpha: .25) : Colors.white.withValues(alpha: .08),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_durumMetni, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        if (_bitti)
                          TextButton.icon(
                            onPressed: _baslat,
                            icon: const Icon(Simgeler.refresh, size: 16, color: Colors.white),
                            label: const Text('Yeniden iste', style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, k) {
                      final olcek = [(k.maxWidth - 16) / _sw, (k.maxHeight - 16) / _sh, 1.0].reduce((a, b) => a < b ? a : b);
                      final gw = _sw * olcek, gh = _sh * olcek;
                      return Center(
                        child: SizedBox(
                          width: gw,
                          height: gh,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: SizedBox(width: _sw, height: _sh, child: _webKatmani),
                                  ),
                                ),
                              ),
                              // Ziyaretçi imleci (sayfa koordinatı − görünen kaydırma)
                              if (_kareVar)
                                Positioned(
                                  left: (_px - _gorX) * olcek - 6,
                                  top: (_py - _gorY) * olcek - 6,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Marka.gul,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              // Yönlendirme dokunuşu + Kaydır (tekerlek / iz paneli / sürükleme)
                              Positioned.fill(
                                child: Listener(
                                  onPointerSignal: (e) {
                                    if (_kaydir && e is PointerScrollEvent) _kaydirEkle(e.scrollDelta.dx / olcek, e.scrollDelta.dy / olcek);
                                  },
                                  onPointerPanZoomUpdate: (e) {
                                    if (_kaydir) _kaydirEkle(-e.panDelta.dx / olcek, -e.panDelta.dy / olcek);
                                  },
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: !_yonlendir
                                        ? null
                                        : (d) {
                                            // Konum, ziyaretçinin görüntü alanına göre 0..1 kesir olarak gider.
                                            _isaretGonder((d.localPosition.dx / gw).clamp(0.0, 1.0), (d.localPosition.dy / gh).clamp(0.0, 1.0));
                                          },
                                    onVerticalDragUpdate: !_kaydir ? null : (d) => _kaydirEkle(0, -d.delta.dy / olcek),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                              if (_kaydir || _hataSayisi >= 3)
                                Positioned(
                                  left: 8,
                                  top: 8,
                                  child: IgnorePointer(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_kaydir) _kucukCip('Siz kaydırıyorsunuz', Simgeler.swapVert, Marka.mor),
                                        if (_kaydir && _hataSayisi >= 3) const SizedBox(height: 6),
                                        if (_hataSayisi >= 3) _kucukCip('Bağlantı bekleniyor', Simgeler.cloudOff, Marka.kehribar),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  color: Colors.black.withValues(alpha: .35),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _kaydir
                                ? 'Kaydırdığınızda ziyaretçinin sayfası da aynı konuma kayar.'
                                : _yonlendir
                                ? 'Dokunduğunuz nokta ziyaretçinin ekranında işaretlenir.'
                                : 'Salt izleme. Yönlendirmek için "Yönlendir"i, sayfayı kaydırmak için "Kaydır"ı açın.',
                            style: TextStyle(color: Colors.white.withValues(alpha: .75), fontSize: 12.5),
                          ),
                        ),
                        if (_yonlendir)
                          TextButton.icon(
                            onPressed: () => islem(() => Panel.ekranIsaret(widget.oturumId), tamam: 'İşaret kaldırıldı'),
                            icon: const Icon(Simgeler.close, size: 16, color: Colors.white),
                            label: const Text('İşareti kaldır', style: TextStyle(color: Colors.white)),
                          ),
                        Text('${_sw.toInt()}×${_sh.toInt()}', style: TextStyle(color: r.silik, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
