import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Hazır yanıtlar: kısayol, başlık, metin, kategori.
class HazirYanitlarEkrani extends StatelessWidget {
  const HazirYanitlarEkrani({super.key});

  Future<void> _form(BuildContext context, VoidCallback yenile, {Map<String, dynamic>? h}) async {
    final kisayol = TextEditingController(text: metin(h?['shortcut'])),
        baslik = TextEditingController(text: metin(h?['title'])),
        govde = TextEditingController(text: metin(h?['body'])),
        kategori = TextEditingController(text: metin(h?['category']));
    await formDiyalog(
      context,
      h == null ? 'Hazır yanıt ekle' : 'Hazır yanıtı düzenle',
      alanlar: [
        alan('Kısayol', kisayol, ipucu: '/fiyat', alt: 'Sohbette "/" ile çağrılır'),
        alan('Başlık', baslik),
        alan('Metin', govde, satir: 5, alt: 'Değişkenler: {name}, {agent}, {email}'),
        alan('Kategori', kategori, ipucu: 'Satış, Teknik…'),
      ],
      kaydetF: () {
        final g = {'shortcut': kisayol.text.trim(), 'title': baslik.text.trim(), 'body': govde.text, 'category': kategori.text.trim()};
        return h == null ? Panel.hazirYanitEkle(g) : Panel.hazirYanitGuncelle(tamsayi(h['id']), g);
      },
    );
    yenile();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Hazır yanıtlar',
      yukle: Panel.hazirYanitlar,
      govde: (context, v, yenile) {
        final l = haritalar(v['items']);
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${l.length} hazır yanıt', style: TextStyle(color: r.soluk, fontSize: 13)),
                ),
                FilledButton.icon(onPressed: () => _form(context, yenile), icon: const Icon(Simgeler.add, size: 18), label: const Text('Ekle')),
              ],
            ),
            const SizedBox(height: 10),
            if (l.isEmpty) Durum.bos('Hazır yanıt yok.', ikon: Simgeler.bolt),
            for (final x in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Kutu(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  onTap: () => _form(context, yenile, h: x),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Rozet(metin(x['shortcut']), renk: Marka.mor, ikon: Simgeler.bolt),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    metin(x['title']),
                                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                                  ),
                                ),
                                if (metinYa(x['category']) != null) Rozet(metin(x['category']), renk: Marka.lavanta),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              metin(x['body']),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: r.soluk, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Simgeler.deleteOutline, color: Marka.gul, size: 20),
                        onPressed: () async {
                          if (await onayla(context, 'Hazır yanıt silinsin mi?', evet: 'Sil', tehlikeli: true)) {
                            if (await kaydet(() => Panel.hazirYanitSil(tamsayi(x['id'])))) yenile();
                          }
                        },
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
}
