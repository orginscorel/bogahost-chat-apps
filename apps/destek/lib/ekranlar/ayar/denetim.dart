import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Denetim kaydı: kim, ne, ne zaman, hangi IP'den; eylem ve kullanıcı süzgeci.
class DenetimEkrani extends StatefulWidget {
  const DenetimEkrani({super.key});
  @override
  State<DenetimEkrani> createState() => _DenetimEkraniState();
}

class _DenetimEkraniState extends State<DenetimEkrani> {
  String? _eylem;
  int? _kullanici;
  final _ip = TextEditingController();
  int _anahtar = 0;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      key: ValueKey(_anahtar),
      baslik: 'Denetim kaydı',
      yukle: () => Panel.denetim(q: {'action': ?_eylem, 'user': ?_kullanici, if (_ip.text.trim().isNotEmpty) 'ip': _ip.text.trim()}),
      govde: (context, v, yenile) {
        final l = haritalar(v['logs']);
        final eylemler = metinler(v['actions']);
        final kullanicilar = haritalar(v['users']);
        final ist = harita(v['stats']);
        return ListView(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _kart('Bugün', '${tamsayi(ist['today'])}', Marka.mor, r),
                _kart('Başarısız giriş (24s)', '${tamsayi(ist['failed_login_24h'])}', Marka.gul, r),
                _kart('Uyarı (24s)', '${tamsayi(ist['alerts_24h'])}', Marka.kehribar, r),
                _kart('Toplam', '${tamsayi(ist['total'])}', Marka.mavi, r),
              ],
            ),
            const SizedBox(height: 12),
            Kutu(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                children: [
                  secim<String?>('Eylem', _eylem, [(null, 'Tümü'), for (final a in eylemler) (a, a)], (x) {
                    _eylem = x;
                    setState(() => _anahtar++);
                  }),
                  secim<int?>('Kullanıcı', _kullanici, [(null, 'Tümü'), for (final u in kullanicilar) (tamsayi(u['id']), metin(u['name']))], (x) {
                    _kullanici = x;
                    setState(() => _anahtar++);
                  }),
                  TextField(
                    controller: _ip,
                    decoration: InputDecoration(
                      labelText: 'IP',
                      suffixIcon: IconButton(icon: const Icon(Simgeler.search, size: 18), onPressed: () => setState(() => _anahtar++)),
                    ),
                    onSubmitted: (_) => setState(() => _anahtar++),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (l.isEmpty) Durum.bos('Kayıt yok.', ikon: Simgeler.history),
            for (final x in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Kutu(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_ikon(metin(x['action'])), size: 20, color: _renk(metin(x['action']))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Rozet(metin(x['action']), renk: _renk(metin(x['action']))),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    metin(harita(x['user'])['name'], 'Sistem'),
                                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 13.5),
                                  ),
                                ),
                                Text(kisaZaman(tarihOku(x['created_at'])), style: TextStyle(color: r.silik, fontSize: 11.5)),
                              ],
                            ),
                            if (metinYa(x['subject_type']) != null)
                              Text('${metin(x['subject_type'])} #${x['subject_id'] ?? ''}', style: TextStyle(color: r.soluk, fontSize: 12)),
                            if (x['data'] is Map && (x['data'] as Map).isNotEmpty)
                              Text(
                                (x['data'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: r.silik, fontSize: 11.5),
                              ),
                            Text(
                              metin(x['ip']),
                              style: TextStyle(color: r.silik, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _kart(String ad, String deger, Color renk, Renkler r) => SizedBox(
    width: 150,
    child: Kutu(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(deger, style: gosterim(22, renk: renk)),
          Text(ad, style: TextStyle(color: r.soluk, fontSize: 12)),
        ],
      ),
    ),
  );

  IconData _ikon(String a) => a.contains('login')
      ? Simgeler.login
      : a.contains('ban')
      ? Simgeler.prohibit
      : a.contains('delete') || a.contains('remove')
      ? Simgeler.deleteOutline
      : a.contains('tfa') || a.contains('2fa')
      ? Simgeler.verifiedUser
      : a.contains('screen') || a.contains('cobrowse')
      ? Simgeler.monitor
      : Simgeler.history;
  Color _renk(String a) => a.contains('failed') || a.contains('delete') || a.contains('ban')
      ? Marka.gul
      : a.contains('login')
      ? Marka.zumrut
      : a.contains('screen') || a.contains('cobrowse')
      ? Marka.kehribar
      : Marka.mavi;
}
