import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Acil durum: arıza duyurusu (ağ/cihaz) + saldırı modu (widget kısıtlı, puanlama yerine "talebiniz iletildi").
class AcilDurumEkrani extends StatelessWidget {
  const AcilDurumEkrani({super.key});

  Future<void> _etkinlestir(BuildContext context, VoidCallback yenile) async {
    String tur = 'network';
    final baslik = TextEditingController(), not = TextEditingController(), konum = TextEditingController();
    await formDiyalog(
      context,
      'Arıza duyurusu başlat',
      tamam: 'Başlat',
      alanlar: [
        StatefulBuilder(
          builder: (_, set) => secim<String>('Tür', tur, const [
            ('network', 'Ağ / bağlantı arızası'),
            ('device', 'Cihaz / sunucu arızası'),
          ], (x) => set(() => tur = x ?? 'network')),
        ),
        alan('Başlık', baslik, ipucu: 'Planlı bakım / Ağ kesintisi'),
        alan('Açıklama', not, satir: 3, alt: 'Widget\'ta ziyaretçiye gösterilir'),
        alan('Konum', konum, ipucu: 'İstanbul DC-2'),
      ],
      kaydetF: () => Panel.acilEylem('activate', {'type': tur, 'title': baslik.text.trim(), 'note': not.text.trim(), 'location': konum.text.trim()}),
    );
    yenile();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Acil durum',
      yukle: Panel.acil,
      govde: (context, v, yenile) {
        final durum = harita(v['state']);
        final saldiri = harita(v['attack']);
        final ist = harita(v['attackStats']);
        final acik = mantik(durum['active']);
        final saldiriAcik = mantik(saldiri['active']);
        String zaman(Object? ts) => ts == null ? '—' : tamZaman(DateTime.fromMillisecondsSinceEpoch(tamsayi(ts) * 1000));
        return ListView(
          children: [
            const Baslik('Arıza duyurusu'),
            Kutu(
              renk: acik ? Marka.gul.withValues(alpha: .08) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Simgeler.siren, color: acik ? Marka.gul : r.silik, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acik ? 'Duyuru ETKİN' : 'Duyuru kapalı',
                              style: TextStyle(fontWeight: FontWeight.w700, color: acik ? Marka.gul : r.metin),
                            ),
                            Text(
                              acik
                                  ? '${metin(durum['title'], metin(durum['type']))} · ${metin(durum['note'])}'
                                  : 'Ziyaretçilere widget üstünde arıza bandı göstermek için başlatın.',
                              style: TextStyle(color: r.soluk, fontSize: 12.5),
                            ),
                            if (acik && metinYa(durum['location']) != null) Text(metin(durum['location']), style: TextStyle(color: r.silik, fontSize: 12)),
                            if (acik && durum['since'] != null) Text('Başlangıç: ${zaman(durum['since'])}', style: TextStyle(color: r.silik, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: acik
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              if (await onayla(context, 'Duyuru kaldırılsın mı?', evet: 'Kaldır')) {
                                if (await kaydet(() => Panel.acilEylem('deactivate'))) yenile();
                              }
                            },
                            icon: const Icon(Simgeler.checkCircleOutline, size: 18),
                            label: const Text('Sorun giderildi, kaldır'),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Marka.gul),
                            onPressed: () => _etkinlestir(context, yenile),
                            icon: const Icon(Simgeler.siren, size: 18),
                            label: const Text('Duyuru başlat'),
                          ),
                  ),
                ],
              ),
            ),
            const Baslik('Saldırı modu'),
            Kutu(
              renk: saldiriAcik ? Marka.kehribar.withValues(alpha: .1) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Simgeler.shield, color: saldiriAcik ? Marka.kehribar : r.silik, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              saldiriAcik ? 'Saldırı modu ETKİN' : 'Saldırı modu kapalı',
                              style: TextStyle(fontWeight: FontWeight.w700, color: saldiriAcik ? Marka.kehribar : r.metin),
                            ),
                            Text(
                              'Spam/bot saldırısında widget kısıtlanır: sohbet başlatma sınırlı, puanlama yerine "talebiniz iletildi" ekranı, destek talebi yönlendirmesi.',
                              style: TextStyle(color: r.soluk, fontSize: 12.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Son başlangıç: ${zaman(saldiri['last_started_at'])} · Bitiş: ${zaman(saldiri['ended_at'])}',
                              style: TextStyle(color: r.silik, fontSize: 12),
                            ),
                            Text(
                              'Son saldırıda: ${tamsayi(ist['chats'])} sohbet · ${tamsayi(ist['tickets'])} talep',
                              style: TextStyle(color: r.silik, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: saldiriAcik
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              if (await kaydet(() => Panel.acilEylem('attack-off'))) yenile();
                            },
                            icon: const Icon(Simgeler.checkCircleOutline, size: 18),
                            label: const Text('Saldırı modunu kapat'),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: () async {
                              if (await onayla(
                                context,
                                'Saldırı modu açılsın mı?',
                                mesaj: 'Widget kısıtlı çalışır; gerçek müşteriler destek talebine yönlendirilir.',
                                evet: 'Aç',
                              )) {
                                if (await kaydet(() => Panel.acilEylem('attack-on'))) yenile();
                              }
                            },
                            icon: const Icon(Simgeler.shield, size: 18),
                            label: const Text('Saldırı modunu aç'),
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
}
