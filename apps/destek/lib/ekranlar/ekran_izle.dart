import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
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

  @override
  State<EkranIzleEkrani> createState() => _EkranIzleEkraniState();
}

class _EkranIzleEkraniState extends State<EkranIzleEkrani> {
  InAppWebViewController? _web;
  Timer? _yoklama;
  String _durum = 'connecting';
  String? _hata;
  Object? _hv;
  double _sw = 1280, _sh = 800, _sx = 0, _sy = 0, _px = 0, _py = 0;
  bool _yonlendir = false, _kareVar = false, _yukleniyor = false;
  String? _baseUrl;

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    try {
      await Panel.ekranIste(widget.oturumId, kip: widget.kip);
    } catch (e) {
      setState(() => _hata = hataMetni(e));
      return;
    }
    _yoklama = Timer.periodic(const Duration(milliseconds: 1200), (_) => _yokla());
    _yokla();
  }

  Future<void> _yokla() async {
    if (_yukleniyor) return;
    _yukleniyor = true;
    try {
      final d = await Panel.ekranAl(widget.oturumId, hv: _hv);
      final st = metin(d['state'], 'idle');
      final s = d['snapshot'];
      if (mounted) setState(() => _durum = st);
      if (st == 'active' && s is Map) {
        final m = harita(s);
        _sw = ondalik(m['sw'], 1280);
        _sh = ondalik(m['sh'], 800);
        _sx = ondalik(m['sx']);
        _sy = ondalik(m['sy']);
        _px = ondalik(m['px']);
        _py = ondalik(m['py']);
        final html = m['html'];
        if (html is String && html.isNotEmpty && m['hv'] != _hv) {
          _hv = m['hv'];
          _baseUrl ??= metinYa(m['url']) ?? widget.url;
          await _web?.loadData(data: html, baseUrl: _baseUrl != null ? WebUri(_baseUrl!) : null, mimeType: 'text/html', encoding: 'utf-8');
          _kareVar = true;
        } else {
          await _web?.evaluateJavascript(source: 'window.scrollTo(${_sx.toInt()}, ${_sy.toInt()});');
        }
        if (mounted) setState(() {});
      }
    } catch (_) {
    } finally {
      _yukleniyor = false;
    }
  }

  Future<void> _kapat() async {
    _yoklama?.cancel();
    try {
      await Panel.ekranIsaret(widget.oturumId);
      await Panel.ekranDurdur(widget.oturumId);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _yoklama?.cancel();
    Panel.ekranIsaret(widget.oturumId).catchError((_) => const <String, dynamic>{});
    Panel.ekranDurdur(widget.oturumId).catchError((_) => const <String, dynamic>{});
    super.dispose();
  }

  String get _durumMetni => switch (_durum) {
    'active' => _kareVar ? 'Canlı' : 'Ekran görüntüsü alınıyor…',
    'pending' => 'Ziyaretçinin ekran paylaşımına izin vermesi bekleniyor…',
    'declined' => 'Ziyaretçi ekran paylaşımını reddetti.',
    'ended' => 'Paylaşım sona erdi.',
    _ => 'Bağlanıyor…',
  };

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
          if (_durum == 'active')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _yonlendir,
                avatar: Icon(Simgeler.handPointing, size: 16, color: _yonlendir ? Marka.mor : Colors.white),
                label: Text('Yönlendir', style: TextStyle(color: _yonlendir ? Marka.mor : Colors.white)),
                onSelected: (v) => setState(() => _yonlendir = v),
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .12),
                side: BorderSide.none,
              ),
            ),
        ],
      ),
      body: _hata != null
          ? Durum.hata(_hata!, tekrar: _baslat)
          : Column(
              children: [
                if (_durum != 'active' || !_kareVar)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: _durum == 'declined' ? Marka.gul.withValues(alpha: .25) : Colors.white.withValues(alpha: .08),
                    child: Text(_durumMetni, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, k) {
                      final olcek = [(k.maxWidth - 16) / _sw, (k.maxHeight - 16) / _sh, 1.0].reduce((a, b) => a < b ? a : b);
                      return Center(
                        child: SizedBox(
                          width: _sw * olcek,
                          height: _sh * olcek,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: SizedBox(
                                      width: _sw,
                                      height: _sh,
                                      child: IgnorePointer(
                                        child: InAppWebView(
                                          initialSettings: InAppWebViewSettings(
                                            javaScriptEnabled: false,
                                            transparentBackground: false,
                                            supportZoom: false,
                                            disableContextMenu: true,
                                          ),
                                          onWebViewCreated: (c) {
                                            _web = c;
                                            c.loadData(
                                              data: '<html><body style="background:#fff;font-family:sans-serif;color:#64748b;padding:24px">Ekran görüntüsü bekleniyor…</body></html>',
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Ziyaretçi imleci
                              if (_kareVar)
                                Positioned(
                                  left: (_px - _sx) * olcek - 6,
                                  top: (_py - _sy) * olcek - 6,
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
                              // Yönlendirme dokunuşu
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: !_yonlendir
                                      ? null
                                      : (d) async {
                                          final x = d.localPosition.dx / olcek + _sx, y = d.localPosition.dy / olcek + _sy;
                                          await islem(
                                            () => Panel.ekranIsaret(widget.oturumId, x: x, y: y, etiket: 'Buraya bakın'),
                                            tamam: 'İşaret gönderildi',
                                          );
                                        },
                                  child: const SizedBox.expand(),
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
                            _yonlendir ? 'Dokunduğunuz nokta ziyaretçinin ekranında işaretlenir.' : 'Salt izleme. Yönlendirmek için "Yönlendir"i açın.',
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
