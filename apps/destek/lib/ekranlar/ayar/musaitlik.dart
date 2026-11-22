import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../ortak/yardimci.dart';
import '../../oturum.dart';
import '../../veri/depo.dart';
import '../../veri/json.dart';
import '../../veri/modeller.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Müsaitlik: kip (çevrimiçi / uzakta / rahatsız etme / çevrimdışı), kişisel çalışma saatleri,
/// otomatik "uzakta"; ekip müsaitlik görünümü.
class MusaitlikEkrani extends StatefulWidget {
  const MusaitlikEkrani({super.key});
  @override
  State<MusaitlikEkrani> createState() => _MusaitlikEkraniState();
}

class _MusaitlikEkraniState extends State<MusaitlikEkrani> {
  static const _gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  Map<String, Map<String, dynamic>>? _saatler;
  final _otoUzak = TextEditingController();
  bool _mesgul = false;

  Future<Map<String, dynamic>> _yukle() async {
    final v = await Panel.musaitlik();
    if (_saatler == null) {
      final me = harita(v['me']);
      final wh = harita(me['working_hours']);
      _saatler = {
        for (var i = 1; i <= 7; i++)
          '$i': {
            'on': mantik(harita(wh['$i'])['on'], wh.isEmpty),
            'from': metin(harita(wh['$i'])['from'], '09:00'),
            'to': metin(harita(wh['$i'])['to'], '18:00'),
          },
      };
      _otoUzak.text = '${tamsayi(me['auto_away_minutes'])}';
    }
    return v;
  }

  Future<void> _kipDegistir(String m) async {
    final v = await islem(() => Depo.musaitlik(m));
    if (v == null) return;
    final t = Uyg.ben.value!;
    Uyg.ben.value = Temsilci.coz({
      'id': t.id,
      'display_name': t.ad,
      'email': t.eposta,
      'role': t.rol,
      'role_name': t.rolAdi,
      'permissions': t.yetkiler,
      'is_admin': t.yonetici,
      'availability': v,
      'avatar': t.avatar,
      'department': t.bolum,
      'totp_enabled': t.totp,
    });
    setState(() {});
  }

  Future<void> _kaydet() async {
    setState(() => _mesgul = true);
    await kaydet(
      () => Panel.calismaSaatleri({
        'working_hours': {
          for (final e in _saatler!.entries) e.key: {'on': e.value['on'] == true ? 1 : 0, 'from': e.value['from'], 'to': e.value['to']},
        },
        'auto_away_minutes': int.tryParse(_otoUzak.text) ?? 0,
      }),
    );
    if (mounted) setState(() => _mesgul = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Müsaitlik',
      yukle: _yukle,
      altBar: KaydetSeridi(mesgul: _mesgul, onKaydet: _kaydet),
      govde: (context, v, yenile) {
        final ekip = haritalar(v['agents']);
        return ValueListenableBuilder<Temsilci?>(
          valueListenable: Uyg.ben,
          builder: (_, t, _) => ListView(
            children: [
              const Baslik('Durumum'),
              Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: RadioGroup<String>(
                  groupValue: t?.musaitlik,
                  onChanged: (x) => x == null ? null : _kipDegistir(x),
                  child: Column(
                    children: [
                      for (final (m, alt) in [
                        ('online', 'Yeni sohbetler size yönlendirilir, bildirimler gelir'),
                        ('away', 'Çevrimiçi görünürsünüz; yeni sohbet almazsınız'),
                        ('dnd', 'Rahatsız etme: yeni sohbet, ses ve anlık bildirim yok'),
                        ('offline', 'Ziyaretçiye çevrimdışı görünürsünüz; sohbet dağıtımına girmezsiniz'),
                      ])
                        RadioListTile<String>(
                          value: m,
                          dense: true,
                          title: Text(musaitlikAdi(m)),
                          subtitle: Text(alt, style: TextStyle(color: r.silik, fontSize: 12)),
                          secondary: Nokta(musaitlikRengi(m), boyut: 12),
                        ),
                    ],
                  ),
                ),
              ),
              const Baslik('Çalışma saatlerim'),
              Kutu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bu saatler dışında otomatik olarak "uzakta" sayılırsınız; sohbet dağıtımı buna göre yapılır.',
                      style: TextStyle(color: r.soluk, fontSize: 12.5),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 1; i <= 7; i++) _gunSatiri(context, '$i', _gunler[i - 1]),
                    const SizedBox(height: 10),
                    alan('Otomatik "uzakta" (dk)', _otoUzak, tur: TextInputType.number, alt: 'Bu kadar süre hareketsiz kalınca uzakta; 0 = kapalı'),
                  ],
                ),
              ),
              const Baslik('Ekip müsaitliği'),
              Kutu(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, u) in ekip.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        dense: true,
                        leading: Stack(
                          children: [
                            KisiAvatar(metin(u['alias'] ?? u['name'], metin(u['name'])), url: metinYa(u['avatar']), boyut: 34),
                            Positioned(right: 0, bottom: 0, child: Nokta(musaitlikRengi(metin(u['availability'], 'offline')), boyut: 10, halka: r.kart)),
                          ],
                        ),
                        title: Text(metin(u['name'])),
                        subtitle: Text(
                          '${musaitlikAdi(metin(u['availability'], 'offline'))}${u['last_seen_at'] == null ? '' : ' · ${goreliZaman(tarihOku(u['last_seen_at']))}'}',
                          style: TextStyle(color: r.silik, fontSize: 12),
                        ),
                        trailing: harita(u['working_hours']).isEmpty
                            ? null
                            : const Tooltip(message: 'Çalışma saatleri tanımlı', child: Icon(Simgeler.schedule, size: 18)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gunSatiri(BuildContext context, String k, String ad) {
    final g = _saatler![k]!;
    final acik = g['on'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Switch(value: acik, onChanged: (x) => setState(() => g['on'] = x)),
          const SizedBox(width: 6),
          SizedBox(
            width: 82,
            child: Text(
              ad,
              style: TextStyle(fontWeight: FontWeight.w500, color: acik ? null : context.r.silik),
            ),
          ),
          const Spacer(),
          saat(context, '', metin(g['from'], '09:00'), (x) => setState(() => g['from'] = x), etkin: acik),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('–')),
          saat(context, '', metin(g['to'], '18:00'), (x) => setState(() => g['to'] = x), etkin: acik),
        ],
      ),
    );
  }
}
