import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Butoi maskotu: web widget'ı ve personel panelindeki avatar paketiyle aynı görsel
/// (assets/butoi/*.png, kaynak: livechat/public/img/butoi/circle/static/*.svg).
/// Durumlar: idle, thinking, typing, responding, greeting, handoff, offline.
/// [dusunuyor] → "thinking" karesi + hafif sallanma; [mutlu] → "greeting".
class ButoiMaskot extends StatefulWidget {
  const ButoiMaskot({super.key, this.boyut = 40, this.dusunuyor = false, this.mutlu = false, this.durum});
  final double boyut;
  final bool dusunuyor;
  final bool mutlu;

  /// Açık durum adı; verilmezse [dusunuyor] / [mutlu] bayraklarından türetilir.
  final String? durum;

  static const durumlar = {'idle', 'thinking', 'typing', 'responding', 'greeting', 'handoff', 'offline'};

  String get _durum {
    final d = durum;
    if (d != null && durumlar.contains(d)) return d;
    if (dusunuyor) return 'thinking';
    if (mutlu) return 'greeting';
    return 'idle';
  }

  @override
  State<ButoiMaskot> createState() => _ButoiMaskotState();
}

class _ButoiMaskotState extends State<ButoiMaskot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    if (widget.dusunuyor) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant ButoiMaskot eski) {
    super.didUpdateWidget(eski);
    if (widget.dusunuyor && !_c.isAnimating) _c.repeat();
    if (!widget.dusunuyor && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resim = ClipOval(
      child: Image.asset(
        'assets/butoi/${widget._durum}.png',
        width: widget.boyut,
        height: widget.boyut,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      ),
    );
    if (!widget.dusunuyor) return resim;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final s = math.sin(_c.value * 2 * math.pi);
        return Transform.rotate(
          angle: s * 0.05,
          child: Transform.translate(offset: Offset(0, -1.5 * s.abs()), child: child),
        );
      },
      child: resim,
    );
  }
}
