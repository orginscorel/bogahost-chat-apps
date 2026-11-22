import 'dart:async';
import 'dart:math' as math;

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bogahost Chat açılışı — gerçek Bogahost logosu kendini çizer.
///
/// Koreografi (2,6 sn, "hareketi azalt" açıksa anında):
///  1. İndigo zemin; arkada yavaşça yükselen yarı saydam sohbet balonları ve nefes alan ışık halkası.
///  2. Amblemin üç sunucu sütunu kalemle çizilir, dolar; gösterge çubukları yeşile yanar.
///  3. "bogahost" harfleri soldan sağa çizilip dolar; üzerinden bir ışık süpürmesi geçer.
///  4. Yeşil sohbet balonu rozeti yaylanarak oturur; içindeki üç nokta "yazıyor" ritmiyle oynar.
///  5. "CANLI DESTEK" etiketi ve ince ilerleme çizgisi belirir; hazırlık sürüyorsa çizgi akmaya devam eder.
///  6. Sonraki ekran yumuşak yakınlaşmayla açılır.
class AcilisChat extends StatefulWidget {
  const AcilisChat({super.key, required this.hazirla});

  /// Sonraki ekranı hazırlar; hata fırlatırsa mesaj + "Tekrar dene".
  final Future<Widget> Function() hazirla;

  @override
  State<AcilisChat> createState() => _AcilisChatState();
}

class _AcilisChatState extends State<AcilisChat> with TickerProviderStateMixin {
  static const _sureMs = 2600;
  late final _giris = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _sureMs),
  );
  late final _akis = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  late final _cikis = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  String? _hata;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (hareketAzalt(context)) {
        _giris.value = 1;
      } else {
        _giris.forward();
      }
    });
    _basla();
  }

  Future<void> _basla() async {
    setState(() => _hata = null);
    Widget sonraki;
    try {
      sonraki = await widget.hazirla();
    } catch (e) {
      if (!mounted) return;
      setState(() => _hata = hataMetni(e));
      return;
    }
    if (!mounted) return;
    // Animasyon her zaman sonuna kadar oynar (marka anı); hazırlık uzun sürerse çizgi akar.
    if (_giris.value < 1) {
      await _giris.forward().orCancel.catchError((_) {});
    }
    if (!mounted) return;
    await _cikis.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: hareketAzalt(context) ? 0 : 380),
        pageBuilder: (_, _, _) => sonraki,
        transitionsBuilder: (_, a, _, child) {
          final e = Curves.easeOutCubic.transform(a.value);
          return Opacity(
            opacity: e,
            child: Transform.scale(scale: .97 + .03 * e, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _giris.dispose();
    _akis.dispose();
    _cikis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Marka.morKoyu,
        body: AnimatedBuilder(
          animation: Listenable.merge([_giris, _akis, _cikis]),
          builder: (context, _) {
            final t = _giris.value;
            final cik = Curves.easeInCubic.transform(_cikis.value);
            final hazirlikBekliyor = _hata == null && t >= 1;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _Zemin(t: t, akis: _akis.value),
                ),
                Center(
                  child: Opacity(
                    opacity: 1 - cik,
                    child: Transform.scale(
                      scale: 1 - .05 * cik,
                      child: LayoutBuilder(
                        builder: (_, k) {
                          final gen = math.min(k.maxWidth * .72, 340.0);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: gen + 56,
                                height: gen * (BogahostLogo.kutu.height / BogahostLogo.kutu.width) + 36,
                                child: CustomPaint(
                                  painter: _LogoBoyayici(t: t, akis: _akis.value, logoGen: gen),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Opacity(
                                opacity: _aralik(t, .78, .95),
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - _aralik(t, .78, .95, Curves.easeOutCubic))),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(color: Colors.white.withValues(alpha: .18)),
                                    ),
                                    child: const Text(
                                      'CANLI DESTEK',
                                      style: TextStyle(
                                        fontFamily: 'packages/boga_ortak/Poppins',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 3.4,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 34),
                              SizedBox(
                                width: 132,
                                height: 3,
                                child: Opacity(
                                  opacity: _aralik(t, .85, 1),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: CustomPaint(
                                      painter: _Cizgi(akis: _akis.value, dolu: !hazirlikBekliyor && _hata == null ? _aralik(t, .85, 1) : null),
                                    ),
                                  ),
                                ),
                              ),
                              if (_hata != null) ...[
                                const SizedBox(height: 22),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Text(
                                    _hata!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 13.5),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.tonal(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .16), foregroundColor: Colors.white),
                                  onPressed: _basla,
                                  child: const Text('Tekrar dene'),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 28,
                  child: SafeArea(
                    top: false,
                    child: Opacity(
                      opacity: _aralik(t, .9, 1) * (1 - cik),
                      child: Text(
                        'chat.bogahost.com',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withValues(alpha: .45), fontSize: 11.5, letterSpacing: .4),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

double _aralik(double t, double a, double b, [Curve c = Curves.easeOut]) => c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// İndigo zemin: köşe ışık halkaları (nefes), yükselen balonlar (döngü), giriş sırasında açılan parlama.
class _Zemin extends CustomPainter {
  _Zemin({required this.t, required this.akis});
  final double t, akis;

  static final _r = math.Random(7);
  static final _balonlar = List.generate(
    14,
    (i) => (x: _r.nextDouble(), hiz: .35 + _r.nextDouble() * .5, boy: 14 + _r.nextDouble() * 26, faz: _r.nextDouble(), sag: _r.nextBool()),
  );

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A5AE0), Marka.mor, Color(0xFF2E1F93)],
          stops: [0, .45, 1],
        ).createShader(r),
    );
    // nefes alan ışık halkaları
    final nefes = .5 + .5 * math.sin(akis * math.pi * 2);
    for (final (merkez, yc, alfa) in [
      (Offset(s.width * .85, s.height * .18), s.width * .55, .16),
      (Offset(s.width * .12, s.height * .86), s.width * .5, .12),
    ]) {
      c.drawCircle(
        merkez,
        yc * (0.92 + .08 * nefes) * _aralik(t, 0, .6, Curves.easeOutCubic),
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: alfa),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: merkez, radius: yc)),
      );
    }
    // yükselen balonlar
    final gorunur = _aralik(t, .05, .5);
    for (final b in _balonlar) {
      final p = (akis * b.hiz + b.faz) % 1.0;
      final y = s.height * (1.1 - p * 1.3);
      final x = s.width * b.x + math.sin(p * math.pi * 2) * 10;
      final alfa = (p < .15 ? p / .15 : (p > .85 ? (1 - p) / .15 : 1)) * .13 * gorunur;
      final k = RRect.fromRectAndCorners(
        Rect.fromCenter(center: Offset(x, y), width: b.boy * 1.35, height: b.boy),
        topLeft: Radius.circular(b.boy * .45),
        topRight: Radius.circular(b.boy * .45),
        bottomLeft: Radius.circular(b.sag ? b.boy * .45 : 3),
        bottomRight: Radius.circular(b.sag ? 3 : b.boy * .45),
      );
      c.drawRRect(k, Paint()..color = Colors.white.withValues(alpha: alfa));
    }
  }

  @override
  bool shouldRepaint(_Zemin o) => o.t != t || o.akis != akis;
}

/// Logo + rozet + ışık süpürmesi.
class _LogoBoyayici extends CustomPainter {
  _LogoBoyayici({required this.t, required this.akis, required this.logoGen});
  final double t, akis, logoGen;

  @override
  void paint(Canvas c, Size s) {
    final oran = BogahostLogo.kutu.height / BogahostLogo.kutu.width;
    final hedef = Rect.fromCenter(center: Offset(s.width / 2 - 14, s.height / 2 + 6), width: logoGen, height: logoGen * oran);
    // Yumuşak gölge/ışıma
    final isima = _aralik(t, .5, .9);
    if (isima > 0) {
      c.drawRRect(
        RRect.fromRectAndRadius(hedef.inflate(18), const Radius.circular(40)),
        Paint()
          ..color = Colors.white.withValues(alpha: .10 * isima)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }
    final amblemT = _aralik(t, .04, .52, Curves.easeInOut);
    final yaziT = _aralik(t, .30, .82, Curves.easeInOut);
    BogahostLogo.cizAnimasyonlu(c, hedef, amblemT: amblemT, yaziT: yaziT, renk: Colors.white, vurgu: amblemT >= 1 ? Marka.yesil : Colors.white);
    // Gösterge çubukları yeşile "yanar" (amblem bittikten sonra kısa parlama)
    final yan = _aralik(t, .52, .62);
    if (yan > 0 && yan < 1) {
      c.save();
      c.clipRect(hedef);
      c.drawRect(hedef, Paint()..color = Marka.yesil.withValues(alpha: .18 * math.sin(yan * math.pi)));
      c.restore();
    }
    // Işık süpürmesi
    final sup = _aralik(t, .70, .98, Curves.easeInOut);
    if (sup > 0 && sup < 1) {
      c.save();
      c.clipRect(hedef.inflate(4));
      final x = hedef.left - 80 + (hedef.width + 160) * sup;
      c.drawRect(
        Rect.fromLTWH(x - 40, hedef.top - 10, 80, hedef.height + 20),
        Paint()
          ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .55), Colors.white.withValues(alpha: 0)])
              .createShader(Rect.fromLTWH(x - 40, 0, 80, 1))
          ..blendMode = BlendMode.plus,
      );
      c.restore();
    }
    // Yeşil sohbet rozeti (amblemin sağ altında)
    final roz = _aralik(t, .60, .96, Curves.elasticOut);
    if (roz > 0) {
      final amb = BogahostLogo.amblemKutusu;
      final k = hedef.width / BogahostLogo.kutu.width;
      final merkez = Offset(hedef.left + (amb.right) * k + 4, hedef.top + amb.bottom * k - 2);
      final yc = logoGen * .085 * roz;
      c.drawCircle(merkez, yc + 3.5, Paint()..color = Marka.morKoyu);
      c.drawCircle(merkez, yc, Paint()..color = Marka.yesil);
      final b = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(merkez.dx, merkez.dy - yc * .06), width: yc * 1.14, height: yc * .86),
        Radius.circular(yc * .3),
      );
      final beyaz = Paint()..color = Colors.white;
      c.drawRRect(b, beyaz);
      c.drawPath(
        Path()
          ..moveTo(merkez.dx - yc * .22, b.bottom - yc * .04)
          ..lineTo(merkez.dx - yc * .42, b.bottom + yc * .3)
          ..lineTo(merkez.dx + yc * .1, b.bottom - yc * .04)
          ..close(),
        beyaz,
      );
      // yazıyor noktaları: sırayla zıplar
      for (final (i, x) in [-.3, 0.0, .3].indexed) {
        final f = (akis * 2 - i * .18) % 1.0;
        final z = f < .5 ? math.sin(f * math.pi) : 0.0;
        c.drawCircle(Offset(merkez.dx + x * yc, merkez.dy - yc * .06 - z * yc * .12), yc * .09, Paint()..color = Marka.yesil);
      }
    }
  }

  @override
  bool shouldRepaint(_LogoBoyayici o) => o.t != t || o.akis != akis || o.logoGen != logoGen;
}

/// İnce ilerleme çizgisi: giriş sırasında dolar, hazırlık beklerken akar.
class _Cizgi extends CustomPainter {
  _Cizgi({required this.akis, this.dolu});
  final double akis;
  final double? dolu;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = Colors.white.withValues(alpha: .18));
    if (dolu != null) {
      c.drawRect(Rect.fromLTWH(0, 0, s.width * dolu!, s.height), Paint()..color = Colors.white.withValues(alpha: .9));
    } else {
      final w = s.width * .38;
      final x = -w + (s.width + w) * akis;
      c.drawRect(
        Rect.fromLTWH(x, 0, w, s.height),
        Paint()
          ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white, Colors.white.withValues(alpha: 0)])
              .createShader(Rect.fromLTWH(x, 0, w, s.height)),
      );
    }
  }

  @override
  bool shouldRepaint(_Cizgi o) => o.akis != akis || o.dolu != dolu;
}
