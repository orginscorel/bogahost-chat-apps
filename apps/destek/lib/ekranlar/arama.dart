import 'dart:async';
import 'dart:convert';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../veri/json.dart';
import '../veri/panel.dart';

/// Sesli / görüntülü görüşme (WebRTC). Web paneliyle aynı sinyalleşme: temsilci offer üretir → sunucu
/// önbelleğine yazar → ziyaretçi widget'ı answer verir; ICE adayları 1,5 sn'lik yoklamayla taşınır.
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
  Timer? _yoklama, _sure;
  String _durum = 'Hazırlanıyor…';
  bool _bagli = false, _bitti = false, _sessiz = false, _kameraKapali = false, _hoparlor = true, _uzakAnswer = false;
  final _bekleyenAdaylar = <Map<String, dynamic>>[];
  int _saniye = 0;
  int _relay = 0;

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
      _yerelAkis = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': widget.video ? {'facingMode': 'user', 'width': 640, 'height': 480} : false,
      });
      _yerel.srcObject = _yerelAkis;
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
    final pc = await createPeerConnection({'iceServers': ice, 'iceTransportPolicy': 'relay', 'sdpSemantics': 'unified-plan'});
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
      Panel.aramaIce(widget.sohbetId, {'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex}).catchError((_) {});
    };
    pc.onIceGatheringState = (s) {
      if (s == RTCIceGatheringState.RTCIceGatheringStateComplete && _relay == 0) _durumYaz('TURN relay adayı yok — sunucuya ulaşılamıyor');
    };
    pc.onIceConnectionState = (s) {
      switch (s) {
        case RTCIceConnectionState.RTCIceConnectionStateChecking:
          _durumYaz('Bağlanıyor… (relay: $_relay)');
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          if (!_bagli) {
            _bagli = true;
            _sure = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() => _saniye++) : null);
          }
          _durumYaz('Bağlandı');
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _durumYaz('Bağlantı kurulamadı (relay: $_relay)');
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          _durumYaz('Bağlantı koptu…');
        default:
          break;
      }
    };
    final offer = await pc.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': widget.video});
    await pc.setLocalDescription(offer);
    try {
      await Panel.aramaBaslat(widget.sohbetId, jsonEncode({'type': offer.type, 'sdp': offer.sdp}), video: widget.video);
    } catch (e) {
      _durumYaz(hataMetni(e));
      return;
    }
    _durumYaz('Ziyaretçi bekleniyor…');
    _yoklama = Timer.periodic(const Duration(milliseconds: 1500), (_) => _yokla());
  }

  Future<void> _yokla() async {
    final pc = _pc;
    if (pc == null || _bitti) return;
    try {
      final d = await Panel.aramaYokla(widget.sohbetId);
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
      final ans = d['answer'];
      if (ans is String && ans.isNotEmpty && !_uzakAnswer) {
        _uzakAnswer = true;
        final a = harita(jsonDecode(ans));
        await pc.setRemoteDescription(RTCSessionDescription(metin(a['sdp']), metin(a['type'], 'answer')));
        _durumYaz('Bağlanıyor…');
        for (final c in _bekleyenAdaylar) {
          await _adayEkle(c);
        }
        _bekleyenAdaylar.clear();
      }
      for (final c in haritalar(d['ice'])) {
        if (_uzakAnswer) {
          await _adayEkle(c);
        } else {
          _bekleyenAdaylar.add(c);
        }
      }
    } catch (_) {}
  }

  Future<void> _adayEkle(Map<String, dynamic> c) async {
    try {
      await _pc?.addCandidate(RTCIceCandidate(metin(c['candidate']), metinYa(c['sdpMid']), tamsayiYa(c['sdpMLineIndex'])));
    } catch (_) {}
  }

  void _durumYaz(String s) {
    if (mounted) setState(() => _durum = s);
  }

  void _kapat({int gecikme = 0}) {
    if (_bitti) return;
    _bitti = true;
    _yoklama?.cancel();
    _sure?.cancel();
    Future.delayed(Duration(milliseconds: gecikme), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _bitir() async {
    Panel.aramaBitir(widget.sohbetId).catchError((_) {});
    _kapat();
  }

  @override
  void dispose() {
    _yoklama?.cancel();
    _sure?.cancel();
    _yerelAkis?.getTracks().forEach((t) => t.stop());
    _yerelAkis?.dispose();
    _pc?.close();
    _yerel.dispose();
    _uzak.dispose();
    super.dispose();
  }

  String get _sureMetni => '${(_saniye ~/ 60).toString().padLeft(2, '0')}:${(_saniye % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final uzakVideo = widget.video && _uzak.srcObject != null;
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
                  Text(_bagli ? _sureMetni : _durum, style: TextStyle(color: Colors.white.withValues(alpha: .7), fontSize: 14)),
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
                  Nokta(_bagli ? Marka.yesil : Marka.kehribar, boyut: 9),
                  const SizedBox(width: 8),
                  Text(_bagli && uzakVideo ? '${widget.ad} · $_sureMetni' : _durum, style: const TextStyle(color: Colors.white, fontSize: 12.5)),
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
