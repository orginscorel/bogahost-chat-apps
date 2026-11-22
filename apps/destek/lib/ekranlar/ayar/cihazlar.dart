import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Cihazlar ve oturumlar: web oturumları, tarayıcı bildirim cihazları, uygulama cihazları (APNs) ve
/// uygulama oturumları (Bearer jetonları). Uzaktan çıkış.
class CihazlarEkrani extends StatelessWidget {
  const CihazlarEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Cihazlar ve oturumlar',
      yukle: Panel.cihazlar,
      govde: (context, v, yenile) {
        final oturumlar = haritalar(v['sessions']);
        final webCihaz = haritalar(v['devices']);
        final uygCihaz = haritalar(v['app_devices']);
        final uygOturum = haritalar(v['app_tokens']);
        Widget satir({
          required IconData ikon,
          required String baslik,
          required String alt,
          bool suan = false,
          Future<void> Function()? sil,
          String silIpucu = 'Oturumu kapat',
        }) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Kutu(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            child: Row(
              children: [
                Icon(ikon, color: suan ? Marka.zumrut : r.soluk, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              baslik,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 13.5),
                            ),
                          ),
                          if (suan)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Rozet('Bu cihaz', renk: Marka.zumrut),
                            ),
                        ],
                      ),
                      Text(alt, style: TextStyle(color: r.silik, fontSize: 12)),
                    ],
                  ),
                ),
                if (sil != null && !suan) IconButton(tooltip: silIpucu, icon: const Icon(Simgeler.logout, size: 19), onPressed: sil),
              ],
            ),
          ),
        );
        Future<void> silIste(String ne, Object id, String ad) async {
          if (await onayla(context, '$ad sonlandırılsın mı?', evet: 'Sonlandır', tehlikeli: true)) {
            if (await kaydet(() => Panel.cihazSil(ne, id))) yenile();
          }
        }

        return ListView(
          children: [
            Baslik(
              'Uygulama oturumları (${uygOturum.length})',
              sag: TextButton(
                onPressed: () async {
                  if (await onayla(context, 'Süresi dolmuş web oturumları temizlensin mi?', evet: 'Temizle')) {
                    if (await kaydet(Panel.oturumTemizle)) yenile();
                  }
                },
                child: const Text('Eskileri temizle'),
              ),
            ),
            if (uygOturum.isEmpty) Text('Uygulama oturumu yok.', style: TextStyle(color: r.silik)),
            for (final x in uygOturum)
              satir(
                ikon: metin(x['platform']) == 'ios'
                    ? Simgeler.deviceMobile
                    : metin(x['platform']) == 'android'
                    ? Simgeler.smartphone
                    : metin(x['platform']) == 'windows'
                    ? Simgeler.computer
                    : Simgeler.laptop,
                baslik: '${metin(x['user'])} · ${metin(x['device'], metin(x['platform']))}',
                alt: 'v${metin(x['app_version'])} · ${metin(x['ip'])} · son ${metin(x['last'])} · bitiş ${metin(x['expires'])}',
                suan: mantik(x['current']),
                sil: () => silIste('app', x['id'], 'Uygulama oturumu'),
              ),
            Baslik('Anlık bildirim cihazları — uygulama (${uygCihaz.length})'),
            if (uygCihaz.isEmpty)
              Text('Kayıtlı uygulama cihazı yok. Telefonda giriş yapıp bildirim izni verin.', style: TextStyle(color: r.silik, fontSize: 12.5)),
            for (final x in uygCihaz)
              satir(
                ikon: Simgeler.bellRinging,
                baslik: '${metin(x['user'])} · ${metin(x['device'])}',
                alt:
                    '${metin(x['platform'])}${mantik(x['sandbox']) ? ' (sandbox)' : ''} · v${metin(x['app_version'])} · ${metin(x['at'])} · son ${metin(x['last'])}',
              ),
            Baslik('Web oturumları (${oturumlar.length})'),
            for (final x in oturumlar)
              satir(
                ikon: metin(x['device']) == 'mobile' ? Simgeler.deviceMobile : Simgeler.browser,
                baslik: '${metin(x['user'])} · ${metin(x['browser'])} / ${metin(x['os'])}',
                alt: '${metin(x['ip'])} · ${tamsayi(x['count'])} oturum · son ${metin(x['last'])}',
                suan: mantik(x['current']),
                sil: () => silIste('session', x['id'], 'Web oturumu'),
              ),
            Baslik('Tarayıcı bildirim cihazları (${webCihaz.length})'),
            for (final x in webCihaz)
              satir(
                ikon: Simgeler.notifications,
                baslik: '${metin(x['user'])} · ${metin(x['browser'])} / ${metin(x['os'])}',
                alt: '${metin(x['device'])} · ${metin(x['at'])} · son ${metin(x['last'])}',
                sil: () => silIste('push', x['id'], 'Bildirim kaydı'),
                silIpucu: 'Kaydı sil',
              ),
          ],
        );
      },
    );
  }
}
