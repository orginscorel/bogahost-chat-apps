import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Mesai saatleri (site geneli): program açık/kapalı, elle çevrimiçi/çevrimdışı zorlama, gün bazlı saatler,
/// tatiller, çevrimdışı form metni ve otomatik yanıt, karşılama mesajları.
class MesaiEkrani extends StatefulWidget {
  const MesaiEkrani({super.key});
  @override
  State<MesaiEkrani> createState() => _MesaiEkraniState();
}

class _MesaiEkraniState extends State<MesaiEkrani> {
  static const _gunler = [
    ('mon', 'Pazartesi'),
    ('tue', 'Salı'),
    ('wed', 'Çarşamba'),
    ('thu', 'Perşembe'),
    ('fri', 'Cuma'),
    ('sat', 'Cumartesi'),
    ('sun', 'Pazar'),
  ];
  Map<String, dynamic>? _s;
  final _tatil = TextEditingController(),
      _cdMesaj = TextEditingController(),
      _cdYanit = TextEditingController(),
      _krsOnline = TextEditingController(),
      _krsOffline = TextEditingController(),
      _krsGecikme = TextEditingController(),
      _saatDilimi = TextEditingController();
  bool _mesgul = false;

  Future<Map<String, dynamic>> _yukle() async {
    final v = await Panel.mesai();
    if (_s == null) {
      final s = harita(harita(v['site'])['schedule']);
      _s = {
        'enabled': mantik(s['enabled']),
        'manual': metin(s['manual'], 'auto'),
        'greeting_enabled': mantik(s['greeting_enabled']),
        'days': {
          for (final (k, _) in _gunler)
            k: {
              'on': mantik(harita(harita(s['days'])[k])['on']),
              'from': metin(harita(harita(s['days'])[k])['from'], '09:00'),
              'to': metin(harita(harita(s['days'])[k])['to'], '18:00'),
            },
        },
      };
      _tatil.text = metinler(s['holidays']).join('\n');
      _cdMesaj.text = metin(s['offline_message']);
      _cdYanit.text = metin(s['offline_reply']);
      _krsOnline.text = metin(s['greeting_online']);
      _krsOffline.text = metin(s['greeting_offline']);
      _krsGecikme.text = '${tamsayi(s['greeting_delay'], 4)}';
      _saatDilimi.text = metin(s['timezone'], 'Europe/Istanbul');
    }
    return v;
  }

  Future<void> _kaydet() async {
    setState(() => _mesgul = true);
    final d = harita(_s!['days']);
    await kaydet(
      () => Panel.mesaiKaydet({
        'enabled': _s!['enabled'] == true ? 1 : 0,
        'timezone': _saatDilimi.text.trim(),
        'manual': _s!['manual'],
        'days': {
          for (final e in d.entries) e.key: {'on': harita(e.value)['on'] == true ? 1 : 0, 'from': harita(e.value)['from'], 'to': harita(e.value)['to']},
        },
        'holidays': _tatil.text,
        'offline_message': _cdMesaj.text,
        'offline_reply': _cdYanit.text,
        'greeting_enabled': _s!['greeting_enabled'] == true ? 1 : 0,
        'greeting_online': _krsOnline.text,
        'greeting_offline': _krsOffline.text,
        'greeting_delay': int.tryParse(_krsGecikme.text) ?? 4,
      }),
    );
    if (mounted) setState(() => _mesgul = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Mesai saatleri',
      yukle: _yukle,
      altBar: KaydetSeridi(mesgul: _mesgul, onKaydet: _kaydet),
      govde: (context, v, yenile) {
        final mesaiDisi = mantik(v['after_hours']);
        return ListView(
          children: [
            Kutu(
              renk: (mesaiDisi ? Marka.kehribar : Marka.zumrut).withValues(alpha: .08),
              child: Row(
                children: [
                  Icon(mesaiDisi ? Simgeler.clockCountdown : Simgeler.checkCircleOutline, color: mesaiDisi ? Marka.kehribar : Marka.zumrut),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mesaiDisi ? 'Şu an mesai dışı: widget çevrimdışı formu gösteriyor.' : 'Şu an mesai içi: widget canlı sohbet alıyor.',
                      style: TextStyle(color: r.metin, fontSize: 13),
                    ),
                  ),
                  Text(metin(v['now']), style: TextStyle(color: r.silik, fontSize: 11.5)),
                ],
              ),
            ),
            const Baslik('Program'),
            Kutu(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: [
                  anahtar(
                    'Mesai programı etkin',
                    _s!['enabled'] == true,
                    (x) => setState(() => _s!['enabled'] = x),
                    alt: 'Kapalıysa widget her zaman çevrimiçi sayılır',
                    ikon: Simgeler.schedule,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                    child: secim<String>('Elle zorlama', metin(_s!['manual'], 'auto'), const [
                      ('auto', 'Otomatik (programa göre)'),
                      ('online', 'Her zaman çevrimiçi'),
                      ('offline', 'Her zaman çevrimdışı'),
                    ], (x) => setState(() => _s!['manual'] = x ?? 'auto')),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: alan('Saat dilimi', _saatDilimi, ipucu: 'Europe/Istanbul'),
                  ),
                ],
              ),
            ),
            const Baslik('Günler'),
            Kutu(
              child: Column(
                children: [
                  for (final (k, ad) in _gunler) _gunSatiri(context, k, ad),
                  const SizedBox(height: 10),
                  alan('Tatil günleri', _tatil, satir: 3, ipucu: '2026-01-01\n2026-04-23', alt: 'Her satıra bir tarih (YYYY-AA-GG); o gün çevrimdışı sayılır'),
                ],
              ),
            ),
            const Baslik('Mesai dışı'),
            Kutu(
              child: Column(
                children: [
                  alan('Çevrimdışı form başlığı', _cdMesaj, satir: 2, ipucu: 'Mesai saatleri dışındayız'),
                  alan('Mesaj bırakılınca otomatik yanıt', _cdYanit, satir: 5, alt: 'Ziyaretçiye "Teşekkürler" ekranında gösterilir'),
                ],
              ),
            ),
            const Baslik('Karşılama balonu'),
            Kutu(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: [
                  anahtar(
                    'Karşılama mesajı göster',
                    _s!['greeting_enabled'] == true,
                    (x) => setState(() => _s!['greeting_enabled'] = x),
                    ikon: Simgeler.chatDots,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        alan('Mesai içi metin', _krsOnline, satir: 2),
                        alan('Mesai dışı metin', _krsOffline, satir: 2),
                        alan('Gecikme (sn)', _krsGecikme, tur: TextInputType.number),
                      ],
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

  Widget _gunSatiri(BuildContext context, String k, String ad) {
    final g = harita(_s!['days'])[k] as Map<String, dynamic>;
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
