import 'dart:async';
import 'dart:convert';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../veri/json.dart';
import '../veri/panel.dart';

/// Sesli / görüntülü görüşme (WebRTC). Web paneliyle aynı sinyalleşme: temsilci offer üretir → sunucu
/// önbelleğine yazar → ziyaretçi widget'ı answer verir; ICE adayları 1,5 sn'lik yoklamayla taşınır.
/// 45 sn yanıt gelmezse kapanır; bağlantı koparsa en fazla 2 kez ICE restart ile yeniden kurulur.
/// Yalnız TURN relay yolu kullanılır (panelle aynı: kanıtlanmış yol, NAT tuzağı yok).
class AramaEkrani extends StatefulWidget {
  const AramaEkrani({super.key, required this.sohbetId, required this.ad, this.video = true});
  final int sohbetId;
  final String ad;
  final bool video;

  /// Tam ekran arama; kapanınca döner.
  static Future<void> baslat(BuildContext context, {required int sohbetId, required String ad, bool video = true}) =>
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => AramaEkrani(sohbetId: sohbetId, ad: ad, video: video),
        ),
      );

  @override
  State<AramaEkrani> createState() => _AramaEkraniState();
}

class _AramaEkraniState extends State<AramaEkrani> {
  final _yerel = RTCVideoRenderer();
  final _uzak = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  MediaStream? _yerelAkis;
  Timer? _yoklama, _sure, _adayZaman, _calmaZaman, _kopukZaman, _yenidenZaman;
  final _iptal = CancelToken();
  String _durum = 'Hazırlanıyor…';
  bool _bagli = false, _bitti = false, _sessiz = false, _kameraKapali = false, _hoparlor = true, _uzakAnswer = false;
  bool _yukleniyor = false, _baslatildi = false, _adayGonderiliyor = false, _yenidenKuruluyor = false, _temizlendi = false;
  final _bekleyenAdaylar = <Map<String, dynamic>>[];
  // Yerel adaylar toplanır, ~300 ms'de bir sırayla gönderilir (onlarca paralel POST yerine).
  final _adayKuyrugu = <Map<String, dynamic>>[];
  // Uzak adaylar aday metnine göre tekilleştirilir (yoklama aynı listeyi tekrar döndürebilir).
  final _gorulenAdaylar = <String>{};
  String? _sonAnswer;
  int _saniye = 0, _relay = 0, _yenidenDeneme = 0;

  static const _calmaSuresi = Duration(seconds: 45);
  static const _azamiYenidenDeneme = 2;

  @override
  void initState() {
    super.initState();
    _kur();
  }

  Future<void> _kur() async {
    await _yerel.initialize();
    await _uzak.initialize();
    try {
      _durumYaz(widget.video ? 'Kamera açılıyor…' : 'Mikrofon açılıyor…');
      final akis = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': widget.video ? {'facingMode': 'user', 'width': 640, 'height': 480} : false,
      });
      if (_bitti) {
        // Kamera açılırken ekran kapandı: izleri hemen bırak.
        for (final t in akis.getTracks()) {
          await t.stop();
        }
        await akis.dispose();
        return;
      }
      _yerelAkis = akis;
      _yerel.srcObject = akis;
    } catch (e) {
      _durumYaz('${widget.video ? 'Kamera/mikrofona' : 'Mikrofona'} erişilemedi. Sistem ayarlarından izin verin.');
      return;
    }
    List<Map<String, dynamic>> ice;
    try {
      ice = await Panel.iceSunuculari();
    } catch (e) {
      _durumYaz(hataMetni(e));
      return;
    }
    if (_bitti) return;
    _durumYaz('Bağlanıyor…');
    final pc = await createPeerConnection({'iceServers': ice, 'iceTransportPolicy': 'relay', 'sdpSemantics': 'unified-plan'});
    if (_bitti) {
      await pc.close();
      return;
    }
    _pc = pc;
    for (final t in _yerelAkis!.getTracks()) {
      await pc.addTrack(t, _yerelAkis!);
    }
    pc.onTrack = (e) {
      if (e.streams.isNotEmpty) {
        _uzak.srcObject = e.streams.first;
        if (mounted) setState(() {});
      }
    };
    pc.onIceCandidate = (c) {
      if (c.candidate == null) return;
      if ((c.candidate ?? '').contains(' typ relay')) _relay++;
      _adayKuyrugu.add({'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex});
    };
    pc.onIceGatheringState = (s) {
      if (s == RTCIceGatheringState.RTCIceGatheringStateComplete && _relay == 0 && !_bagli) _durumYaz('Görüşme sunucusuna ulaşılamıyor');
    };
    pc.onIceConnectionState = (s) {
      if (s == RTCIceConnectionState.RTCIceConnectionStateConnected || s == RTCIceConnectionState.RTCIceConnectionStateCompleted) _baglandi();
    };
    pc.onConnectionState = (s) {
      switch (s) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _baglandi();
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _kopukZaman?.cancel();
          _yenidenKur();
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          // Kısa kopmalar kendiliğinden düzelir; 5 sn sürerse ICE yeniden başlatılır.
          _kopukZaman?.cancel();
          _kopukZaman = Timer(const Duration(seconds: 5), _yenidenKur);
          if (_bagli) _durumYaz('Bağlantı zayıf…');
        default:
          break;
      }
    };
    _adayZaman = Timer.periodic(const Duration(milliseconds: 300), (_) => _adaylariGonder());
    if (!await _teklifGonder(pc)) return;
    _durumYaz('Çalıyor…');
    // Ziyaretçi 45 sn içinde açmazsa görüşme "Yanıt yok" ile kapanır.
    _calmaZaman = Timer(_calmaSuresi, () {
      if (!_uzakAnswer && !_bagli && !_bitti) _sonlandir('Yanıt yok');
    });
    _yoklama = Timer.periodic(const Duration(milliseconds: 1500), (_) => _yokla());
  }

  /// Offer üretir ve `call/start` ile sunucuya yazar. [yenidenBaslat] → ICE restart offer'ı.
  Future<bool> _teklifGonder(RTCPeerConnection pc, {bool yenidenBaslat = false}) async {
    _baslatildi = false;
    try {
      final offer = await pc.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': widget.video, if (yenidenBaslat) 'iceRestart': true});
      await pc.setLocalDescription(offer);
      await Panel.aramaBaslat(widget.sohbetId, jsonEncode({'type': offer.type, 'sdp': offer.sdp}), video: widget.video);
    } catch (e) {
      if (!yenidenBaslat) _durumYaz(hataMetni(e));
      return false;
    }
    _baslatildi = true;
    return true;
  }

  void _baglandi() {
    _kopukZaman?.cancel();
    _yenidenZaman?.cancel();
    _calmaZaman?.cancel();
    if (!_bagli) {
      _bagli = true;
      _sure = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() => _saniye++) : null);
    }
    _yenidenKuruluyor = false;
    if (mounted) setState(() {});
  }

  /// ICE restart: en fazla [_azamiYenidenDeneme] kez yeni offer gönderilir; olmazsa görüşme kapanır.
  Future<void> _yenidenKur() async {
    final pc = _pc;
    if (pc == null || _bitti) return;
    final s = pc.connectionState;
    if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) return;
    if (_yenidenDeneme >= _azamiYenidenDeneme) {
      _sonlandir('Bağlantı kurulamadı');
      return;
    }
    _yenidenDeneme++;
    _yenidenKuruluyor = true;
    _durumYaz('Bağlantı yeniden kuruluyor…');
    _yenidenZaman?.cancel();
    try {
      await pc.restartIce();
    } catch (_) {}
    _uzakAnswer = false;
    _bekleyenAdaylar.clear();
    final ok = await _teklifGonder(pc, yenidenBaslat: true);
    if (_bitti) return;
    // Yanıt gelmez ya da bağlantı yine kurulamazsa bir sonraki deneme (ya da kapanış).
    _yenidenZaman = Timer(Duration(seconds: ok ? 15 : 3), _yenidenKur);
  }

  Future<void> _adaylariGonder() async {
    if (_adayGonderiliyor || !_baslatildi || _adayKuyrugu.isEmpty || _bitti) return;
    _adayGonderiliyor = true;
    final paket = List<Map<String, dynamic>>.of(_adayKuyrugu);
    _adayKuyrugu.clear();
    try {
      for (final a in paket) {
        if (_bitti) break;
        try {
          await Panel.aramaIce(widget.sohbetId, a);
        } catch (_) {}
      }
    } finally {
      _adayGonderiliyor = false;
    }
  }

  Future<void> _yokla() async {
    final pc = _pc;
    if (pc == null || _bitti || _yukleniyor) return;
    _yukleniyor = true;
    try {
      final d = await Panel.aramaYoklaHizli(widget.sohbetId, iptal: _iptal);
      if (_bitti) return;
      final st = metin(d['state']);
      if (st == 'rejected') {
        _durumYaz('Ziyaretçi reddetti');
        _kapat(gecikme: 1500);
        return;
      }
      if (st == 'idle' || st == 'ended') {
        _durumYaz('Görüşme sonlandı');
        _kapat(gecikme: 1200);
        return;
      }
      if (!_uzakAnswer && !_yenidenKuruluyor && !_bagli) {
        if (st == 'ringing') _durumYaz('Çalıyor…');
        if (st == 'pending') _durumYaz('Bağlanıyor…');
      }
      final ans = d['answer'];
      if (ans is String && ans.isNotEmpty && !_uzakAnswer && ans != _sonAnswer) {
        final a = harita(jsonDecode(ans));
        await pc.setRemoteDescription(RTCSessionDescription(metin(a['sdp']), metin(a['type'], 'answer')));
        _uzakAnswer = true;
        _sonAnswer = ans;
        _calmaZaman?.cancel();
        if (!_bagli && !_yenidenKuruluyor) _durumYaz('Bağlanıyor…');
        for (final c in _bekleyenAdaylar) {
          await _adayEkle(c);
        }
        _bekleyenAdaylar.clear();
      }
      for (final c in haritalar(d['ice'])) {
        final anahtar = metin(c['candidate']);
        if (anahtar.isEmpty || !_gorulenAdaylar.add(anahtar)) continue;
        if (_uzakAnswer) {
          await _adayEkle(c);
        } else {
          _bekleyenAdaylar.add(c);
        }
      }
    } on IstekIptal {
      return;
    } catch (_) {
    } finally {
      _yukleniyor = false;
    }
  }

  Future<void> _adayEkle(Map<String, dynamic> c) async {
    try {
      await _pc?.addCandidate(RTCIceCandidate(metin(c['candidate']), metinYa(c['sdpMid']), tamsayiYa(c['sdpMLineIndex'])));
    } catch (_) {}
  }

  void _durumYaz(String s) {
    if (mounted) setState(() => _durum = s);
  }

  void _zamanlayicilariDurdur() {
    for (final t in [_yoklama, _sure, _adayZaman, _calmaZaman, _kopukZaman, _yenidenZaman]) {
      t?.cancel();
    }
    _iptal.cancel();
  }

  /// Yerel izleri durdurur, akışı ve bağlantıyı kapatır (bir kez).
  Future<void> _temizle() async {
    if (_temizlendi) return;
    _temizlendi = true;
    _zamanlayicilariDurdur();
    final akis = _yerelAkis, pc = _pc;
    _yerelAkis = null;
    _pc = null;
    try {
      _yerel.srcObject = null;
      _uzak.srcObject = null;
    } catch (_) {}
    if (akis != null) {
      for (final t in akis.getTracks()) {
        try {
          await t.stop();
        } catch (_) {}
      }
      try {
        await akis.dispose();
      } catch (_) {}
    }
    try {
      await pc?.close();
    } catch (_) {}
  }

  /// Karşı taraf kapattı / reddetti: temizlik + kısa gecikmeyle çık.
  Future<void> _kapat({int gecikme = 0}) async {
    if (_bitti) return;
    _bitti = true;
    _zamanlayicilariDurdur();
    await _temizle();
    await Future.delayed(Duration(milliseconds: gecikme));
    if (mounted) Navigator.of(context).pop();
  }

  /// Bizim tarafımızdan sonlandırma (yanıt yok / bağlantı kurulamadı): sunucuya `call/end` gider.
  void _sonlandir(String neden) {
    if (_bitti) return;
    _yenidenKuruluyor = false;
    _durumYaz(neden);
    unawaited(Panel.aramaBitir(widget.sohbetId).catchError((_) {}));
    _kapat(gecikme: 1800);
  }

  Future<void> _bitir() async {
    if (_bitti) return;
    unawaited(Panel.aramaBitir(widget.sohbetId).catchError((_) {}));
    await _kapat();
  }

  @override
  void dispose() {
    _bitti = true;
    _zamanlayicilariDurdur();
    unawaited(
      _temizle().whenComplete(() {
        _yerel.dispose();
        _uzak.dispose();
      }),
    );
    super.dispose();
  }

  String get _sureMetni => '${(_saniye ~/ 60).toString().padLeft(2, '0')}:${(_saniye % 60).toString().padLeft(2, '0')}';

  String get _gosterilenDurum => _yenidenKuruluyor ? 'Bağlantı yeniden kuruluyor…' : (_bagli && !_bitti ? 'Görüşmede $_sureMetni' : _durum);

  @override
  Widget build(BuildContext context) {
    final uzakVideo = widget.video && _uzak.srcObject != null;
    final durumMetni = _gosterilenDurum;
    return Scaffold(
      backgroundColor: Marka.grafit,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (uzakVideo)
            RTCVideoView(_uzak, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Avatar(widget.ad, boyut: 96, tohum: widget.ad),
                  const SizedBox(height: 18),
                  Text(
                    widget.ad,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(durumMetni, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 14)),
                ],
              ),
            ),
          if (widget.video && !_kameraKapali)
            Positioned(
              right: 16,
              top: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 110,
                  height: 150,
                  child: RTCVideoView(_yerel, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              ),
            ),
          Positioned(
            left: 16,
            top: 52,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: .45), borderRadius: BorderRadius.circular(99)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Nokta(_bagli && !_yenidenKuruluyor ? Marka.yesil : Marka.kehribar, boyut: 9),
                  const SizedBox(width: 8),
                  Text(
                    _bagli && uzakVideo && !_yenidenKuruluyor ? '${widget.ad} · $_sureMetni' : durumMetni,
                    style: const TextStyle(color: Colors.white, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dugme(_sessiz ? Simgeler.micOff : Simgeler.mic, _sessiz ? 'Sesi aç' : 'Sessize al', aktif: _sessiz, () {
                    _sessiz = !_sessiz;
                    _yerelAkis?.getAudioTracks().forEach((t) => t.enabled = !_sessiz);
                    setState(() {});
                  }),
                  if (widget.video) ...[
                    const SizedBox(width: 16),
                    _dugme(
                      _kameraKapali ? Simgeler.videocamOff : Simgeler.videocam,
                      _kameraKapali ? 'Kamerayı aç' : 'Kamerayı kapat',
                      aktif: _kameraKapali,
                      () {
                        _kameraKapali = !_kameraKapali;
                        _yerelAkis?.getVideoTracks().forEach((t) => t.enabled = !_kameraKapali);
                        setState(() {});
                      },
                    ),
                    const SizedBox(width: 16),
                    _dugme(Simgeler.cameraRotate, 'Kamerayı çevir', () {
                      final v = _yerelAkis?.getVideoTracks();
                      if (v != null && v.isNotEmpty) Helper.switchCamera(v.first);
                    }),
                  ] else ...[
                    const SizedBox(width: 16),
                    _dugme(_hoparlor ? Simgeler.speaker : Simgeler.speakerOff, 'Hoparlör', aktif: !_hoparlor, () {
                      _hoparlor = !_hoparlor;
                      Helper.setSpeakerphoneOn(_hoparlor);
                      setState(() {});
                    }),
                  ],
                  const SizedBox(width: 16),
                  _dugme(Simgeler.phoneX, 'Görüşmeyi bitir', renk: Marka.gul, _bitir),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dugme(IconData ikon, String ipucu, VoidCallback onTap, {bool aktif = false, Color? renk}) => Tooltip(
    message: ipucu,
    child: Material(
      color: renk ?? (aktif ? Colors.white : Colors.white.withValues(alpha: .18)),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 58, height: 58, child: Icon(ikon, color: renk != null ? Colors.white : (aktif ? Marka.grafit : Colors.white), size: 26)),
      ),
    ),
  );
}
