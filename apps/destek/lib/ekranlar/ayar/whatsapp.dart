import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// WhatsApp yönlendirme: her olay için açık/kapalı + hedef (grup ya da numara); test gönderimi.
class WhatsappEkrani extends StatefulWidget {
  const WhatsappEkrani({super.key});
  @override
  State<WhatsappEkrani> createState() => _WhatsappEkraniState();
}

class _WhatsappEkraniState extends State<WhatsappEkrani> {
  Map<String, Map<String, dynamic>>? _rotalar;
  final _test = TextEditingController();
  bool _mesgul = false;

  Future<Map<String, dynamic>> _yukle() async {
    final v = await Panel.whatsapp();
    _rotalar ??= harita(v['routes']).map((k, x) {
      final m = harita(x);
      final tip = metin(m['target_type'], 'group');
      final deger = metin(m['target_value']);
      return MapEntry(k, {
        'enabled': mantik(m['enabled']),
        'target': deger.isEmpty ? '' : (tip == 'group' ? 'group:$deger' : deger),
        'label': metin(m['label'], k),
      });
    });
    return v;
  }

  Future<void> _kaydet() async {
    setState(() => _mesgul = true);
    await kaydet(
      () => Panel.whatsappKaydet({
        'enabled': {for (final e in _rotalar!.entries) e.key: e.value['enabled'] == true ? 1 : 0},
        'target': {for (final e in _rotalar!.entries) e.key: e.value['target']},
      }),
    );
    if (mounted) setState(() => _mesgul = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'WhatsApp bağlantısı',
      yukle: _yukle,
      altBar: KaydetSeridi(mesgul: _mesgul, onKaydet: _kaydet),
      govde: (context, v, yenile) {
        final gruplar = haritalar(v['groups']).where((g) => metin(g['name']).trim().length > 1).toList();
        final secenekler = <(String, String)>[('', 'Kapalı / seçilmedi'), for (final g in gruplar) ('group:${metin(g['chat_id'])}', metin(g['name']))];
        return ListView(
          children: [
            Kutu(
              renk: Marka.zumrut.withValues(alpha: .07),
              child: Row(
                children: [
                  const Icon(Simgeler.whatsapp, color: Marka.yesilKoyu, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Seçili olaylar bağlı WhatsApp hesabından gruba ya da numaraya mesaj olarak gider. ${gruplar.length} grup bulundu.',
                      style: TextStyle(color: r.metin, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Baslik('Olaylar'),
            for (final e in _rotalar!.entries)
              Kutu(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                child: Column(
                  children: [
                    anahtar(
                      metin(e.value['label']),
                      e.value['enabled'] == true,
                      (x) => setState(() => e.value['enabled'] = x),
                      alt: e.key,
                      ikon: Simgeler.broadcast,
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: _hedef(e.value, secenekler)),
                  ],
                ),
              ),
            const Baslik('Test'),
            Kutu(
              child: Column(
                children: [
                  alan('Hedef', _test, ipucu: '905xxxxxxxxx ya da group:1203…', alt: 'Numara (ülke koduyla) veya "group:<grup kimliği>"'),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () => kaydet(() => Panel.whatsappTest(_test.text.trim())),
                      icon: const Icon(Simgeler.send, size: 16),
                      label: const Text('Test mesajı gönder'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _hedef(Map<String, dynamic> rota, List<(String, String)> secenekler) {
    final t = metin(rota['target']);
    final grup = t.isEmpty || t.startsWith('group:');
    final bilinen = secenekler.any((s) => s.$1 == t);
    return Column(
      children: [
        if (grup && bilinen)
          secim<String>('Grup', t, secenekler, (x) => setState(() => rota['target'] = x ?? ''))
        else
          TextField(
            controller: TextEditingController(text: t),
            decoration: const InputDecoration(labelText: 'Numara ya da group:<kimlik>'),
            onChanged: (x) => rota['target'] = x.trim(),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => rota['target'] = grup && bilinen ? '905' : ''),
            child: Text(grup && bilinen ? 'Numara gir' : 'Grup seç'),
          ),
        ),
      ],
    );
  }
}
