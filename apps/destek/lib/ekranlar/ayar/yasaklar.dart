import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

const yasakTurleri = [('ip', 'IP adresi'), ('ip_range', 'IP aralığı (CIDR)'), ('visitor', 'Ziyaretçi no'), ('email', 'E-posta'), ('fingerprint', 'Parmak izi')];
const yasakSureleri = [('1h', '1 saat'), ('1d', '1 gün'), ('1w', '1 hafta'), ('1m', '1 ay'), ('perm', 'Kalıcı')];

/// Yasak ekleme diyaloğu (ziyaretçi detayından da çağrılır).
Future<bool> yasakEkleDiyalog(BuildContext context, {String tur = 'ip', String deger = '', String? not}) async {
  final d = TextEditingController(text: deger), neden = TextEditingController(), notlar = TextEditingController(text: not);
  String t = tur, sure = 'perm';
  return formDiyalog(
    context,
    'Yasak ekle',
    tamam: 'Yasakla',
    alanlar: [
      StatefulBuilder(
        builder: (_, set) => Column(
          children: [
            secim<String>('Tür', t, yasakTurleri, (x) => set(() => t = x ?? 'ip')),
            alan(
              'Değer',
              d,
              ipucu: t == 'ip_range'
                  ? '1.2.3.0/24'
                  : t == 'email'
                  ? 'ad@alan.com'
                  : '',
            ),
            secim<String>('Süre', sure, yasakSureleri, (x) => set(() => sure = x ?? 'perm')),
          ],
        ),
      ),
      alan('Neden', neden, ipucu: 'Ziyaretçiye gösterilir'),
      alan('Not', notlar, satir: 2, ipucu: 'Yalnız ekip görür'),
    ],
    kaydetF: () => Panel.yasakEkle({'type': t, 'value': d.text.trim(), 'reason': neden.text.trim(), 'notes': notlar.text.trim(), 'duration': sure}),
  );
}

/// Yasaklar (ziyaretçi engelleri) + personel erişim engelleri.
class YasaklarEkrani extends StatelessWidget {
  const YasaklarEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Yasaklar',
      yukle: Panel.yasaklar,
      govde: (context, v, yenile) {
        final aktif = haritalar(v['active']);
        final suresiDolan = haritalar(v['expired']);
        Widget satir(Map<String, dynamic> x, {bool dolmus = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Kutu(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (dolmus ? const Color(0xFF94A3B8) : Marka.gul).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Simgeler.prohibit, color: dolmus ? const Color(0xFF94A3B8) : Marka.gul, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Rozet(yasakTurleri.firstWhere((t) => t.$1 == metin(x['type']), orElse: () => ('', metin(x['type']))).$2, renk: Marka.mavi),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              metin(x['value']),
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                      if (metinYa(x['reason']) != null) Text(metin(x['reason']), style: TextStyle(color: r.soluk, fontSize: 12.5)),
                      if (metinYa(x['notes']) != null) Text(metin(x['notes']), style: TextStyle(color: r.silik, fontSize: 12)),
                      Text(
                        '${x['expires_at'] == null ? 'Kalıcı' : 'Bitiş: ${tamZaman(tarihOku(x['expires_at']))}'} · ${tamsayi(x['hits'])} isabet · ${kisaZaman(tarihOku(x['created_at']))}',
                        style: TextStyle(color: r.silik, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Kaldır',
                  icon: const Icon(Simgeler.deleteOutline, size: 20),
                  onPressed: () async {
                    if (await onayla(context, 'Yasak kaldırılsın mı?', evet: 'Kaldır', tehlikeli: true)) {
                      if (await kaydet(() => Panel.yasakSil(tamsayi(x['id'])))) yenile();
                    }
                  },
                ),
              ],
            ),
          ),
        );
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${aktif.length} etkin · ${suresiDolan.length} süresi dolmuş', style: TextStyle(color: r.soluk, fontSize: 13)),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (await yasakEkleDiyalog(context)) yenile();
                  },
                  icon: const Icon(Simgeler.add, size: 18),
                  label: const Text('Yasak ekle'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (aktif.isEmpty) Durum.bos('Etkin yasak yok.', ikon: Simgeler.prohibit),
            for (final x in aktif) satir(x),
            if (suresiDolan.isNotEmpty) ...[const Baslik('Süresi dolanlar'), for (final x in suresiDolan) satir(x, dolmus: true)],
          ],
        );
      },
    );
  }
}

/// Personel erişim engelleri: hesabı panelden geçici olarak kilitle.
class ErisimEngelEkrani extends StatelessWidget {
  const ErisimEngelEkrani({super.key});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Erişim engelleri',
      yukle: Panel.erisimEngelleri,
      govde: (context, v, yenile) {
        final l = haritalar(v['blocks']);
        final kullanicilar = haritalar(v['users']);
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Engelli personel panele ve uygulamaya giremez; sohbetleri yeniden dağıtılır.', style: TextStyle(color: r.soluk, fontSize: 12.5)),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    int? kim = kullanicilar.isEmpty ? null : tamsayi(kullanicilar.first['id']);
                    final neden = TextEditingController();
                    final ok = await formDiyalog(
                      context,
                      'Erişimi engelle',
                      tamam: 'Engelle',
                      alanlar: [
                        StatefulBuilder(
                          builder: (_, set) =>
                              secim<int>('Personel', kim, [for (final u in kullanicilar) (tamsayi(u['id']), metin(u['name']))], (x) => set(() => kim = x)),
                        ),
                        alan('Neden', neden),
                      ],
                      kaydetF: () => Panel.erisimEngelle(kim ?? 0, neden.text.trim()),
                    );
                    if (ok) yenile();
                  },
                  icon: const Icon(Simgeler.personOff, size: 18),
                  label: const Text('Engelle'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (l.isEmpty) Durum.bos('Engelli personel yok.', ikon: Simgeler.personOff),
            for (final x in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Kutu(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Row(
                    children: [
                      const Icon(Simgeler.personOff, color: Marka.gul),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metin(x['user_name'] ?? harita(x['user'])['name'] ?? x['user'], '#${x['user_id']}'),
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                            ),
                            Text(
                              '${metin(x['reason'], 'Neden belirtilmedi')} · ${kisaZaman(tarihOku(x['created_at']))}',
                              style: TextStyle(color: r.silik, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (await kaydet(() => Panel.erisimAc(tamsayi(x['id'])))) yenile();
                        },
                        child: const Text('Engeli kaldır'),
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
