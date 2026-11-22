import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../ortak/yardimci.dart';
import '../../oturum.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Tetikleyiciler (otomasyon): koşul → eylem kuralları; aç/kapa, sil. Düzenleme web panelinde.
class TetikleyicilerEkrani extends StatelessWidget {
  const TetikleyicilerEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Tetikleyiciler',
      yukle: Panel.tetikleyiciler,
      eylemler: [
        IconButton(tooltip: 'Web panelinde düzenle', icon: const Icon(Simgeler.openInNew), onPressed: () => disAc('${Uyg.api.sunucu}/admin/triggers')),
      ],
      govde: (context, v, yenile) {
        final l = haritalar(v['triggers']);
        final olaylar = harita(v['events']);
        final eylemler = harita(v['actions']);
        final puan = harita(v['scoring']);
        return ListView(
          children: [
            Kutu(
              renk: Marka.mor.withValues(alpha: .06),
              child: Row(
                children: [
                  const Icon(Simgeler.bolt, color: Marka.mor, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${l.length} kural. Koşul sağlanınca otomatik mesaj, davet, etiket ya da bildirim gönderilir. Yeni kural ve koşul düzenleme web panelinden yapılır.',
                      style: TextStyle(color: r.metin, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (l.isEmpty) Durum.bos('Tetikleyici yok.', ikon: Simgeler.bolt),
            for (final t in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Kutu(
                  padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metin(t['name'], 'Kural #${t['id']}'),
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                Rozet(metin(olaylar[metin(t['event'])], metin(t['event'])), renk: Marka.mavi, ikon: Simgeler.target),
                                Rozet(metin(eylemler[metin(t['action'])], metin(t['action'])), renk: Marka.zumrut, ikon: Simgeler.arrowForward),
                                if (tamsayi(t['fire_count']) > 0) Rozet('${tamsayi(t['fire_count'])} kez', renk: Marka.lavanta),
                              ],
                            ),
                            if (t['conditions'] is Map && (t['conditions'] as Map).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  (t['conditions'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: r.silik, fontSize: 11.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Switch(
                        value: mantik(t['is_active'], true),
                        onChanged: (_) async {
                          if (await kaydet(() => Panel.tetikleyiciAcKapa(tamsayi(t['id'])))) yenile();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Simgeler.deleteOutline, color: Marka.gul, size: 20),
                        onPressed: () async {
                          if (await onayla(context, 'Tetikleyici silinsin mi?', evet: 'Sil', tehlikeli: true)) {
                            if (await kaydet(() => Panel.tetikleyiciSil(tamsayi(t['id'])))) yenile();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (puan.isNotEmpty) ...[
              const Baslik('Ziyaretçi puanlama'),
              Kutu(child: Column(children: [for (final e in puan.entries) bilgi(context, e.key, '${e.value}')])),
            ],
          ],
        );
      },
    );
  }
}
