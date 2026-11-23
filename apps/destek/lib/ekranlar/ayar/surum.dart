import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../oturum.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import '../../veri/surum_notlari.dart';
import 'ortak.dart';

/// Sürüm notları — web panelindeki changelog düzeni: "Sistem sürümü" ve "Native sürümü" rozetleri, dikey zaman
/// çizelgesi; her kartta kaynak rozeti (Sistem / Native), sürüm, "En güncel", tarih, başlık ve tür etiketli maddeler.
class SurumEkrani extends StatelessWidget {
  const SurumEkrani({super.key});

  static String get platform => Platform.isIOS
      ? 'iOS'
      : Platform.isMacOS
      ? 'macOS'
      : Platform.isAndroid
      ? 'Android'
      : Platform.isWindows
      ? 'Windows'
      : Platform.operatingSystem;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Sürüm Notları',
      yukle: Panel.surum,
      govde: (context, v, yenile) {
        final sistem = [
          for (final s in haritalar(v['changelog'])) {...s, '_kaynak': 'Sistem'},
        ];
        final yerel = [
          for (final s in uygulamaNotlari) {...s, '_kaynak': 'Native'},
        ];
        final hepsi = [...yerel, ...sistem]..sort((a, b) => _tarih(b['date']).compareTo(_tarih(a['date'])));
        final sunucuSurum = metin(v['version'], Uyg.sunucuSurumu);
        return LayoutBuilder(
          builder: (_, k) {
            final genis = k.maxWidth >= 760;
            return ListView(
              children: [
                Kutu(
                  child: Flex(
                    direction: genis ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: genis ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BogahostLogoGorunumu(genislik: 56, yalnizAmblem: true),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Bogahost Chat', style: gosterim(18, renk: r.metin)),
                              Text('$platform uygulaması · ${Uyg.api.sunucu.replaceFirst('https://', '')}', style: TextStyle(color: r.soluk, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      if (genis) const Spacer() else const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _rozetBuyuk('Sistem sürümü', 'v$sunucuSurum', Marka.mavi, r),
                          _rozetBuyuk('Native sürümü', 'v${Uyg.api.surum}', Marka.mor, r),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                for (final (i, s) in hepsi.indexed)
                  _ZamanOgesi(s, ilk: i == 0, son: i == hepsi.length - 1, enGuncel: hepsi.indexWhere((x) => x['_kaynak'] == s['_kaynak']) == i),
              ],
            );
          },
        );
      },
    );
  }

  Widget _rozetBuyuk(String etiket, String deger, Color renk, Renkler r) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: renk.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: renk.withValues(alpha: .3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(etiket.startsWith('Sistem') ? Simgeler.dns : Simgeler.deviceMobile, size: 16, color: renk),
        const SizedBox(width: 8),
        Text('$etiket · ', style: TextStyle(color: r.soluk, fontSize: 12.5)),
        Text(
          deger,
          style: TextStyle(color: renk, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  static DateTime _tarih(Object? v) {
    final s = '$v'.trim();
    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;
    final m = RegExp(r'^(\d{1,2})[./](\d{1,2})[./](\d{4})').firstMatch(s);
    if (m != null) return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
    return DateTime(2000);
  }
}

class _ZamanOgesi extends StatelessWidget {
  const _ZamanOgesi(this.s, {required this.ilk, required this.son, required this.enGuncel});
  final Map<String, dynamic> s;
  final bool ilk, son, enGuncel;

  static IconData ikon(String t) => switch (t) {
    'new' || 'added' || 'feature' => Simgeler.sparkle,
    'improved' || 'improvement' || 'changed' => Simgeler.trendingUp,
    'fixed' || 'fix' => Simgeler.build,
    'security' => Simgeler.shieldCheck,
    'removed' => Simgeler.remove,
    _ => Simgeler.infoOutline,
  };
  static Color renk(String t) => switch (t) {
    'new' || 'added' || 'feature' => Marka.zumrut,
    'improved' || 'improvement' || 'changed' => Marka.mavi,
    'fixed' || 'fix' => Marka.kehribar,
    'security' => Marka.gul,
    'removed' => Marka.grafitAcik,
    _ => Marka.lavanta,
  };
  static String ad(String t) => switch (t) {
    'new' || 'added' || 'feature' => 'Yeni',
    'improved' || 'improvement' || 'changed' => 'İyileştirme',
    'fixed' || 'fix' => 'Düzeltme',
    'security' => 'Güvenlik',
    'removed' => 'Kaldırıldı',
    _ => t,
  };

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final yerel = s['_kaynak'] == 'Native';
    final kaynakRengi = yerel ? Marka.mor : Marka.mavi;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(width: 2, height: 22, color: ilk ? Colors.transparent : r.kenar),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: ilk ? r.vurgu : r.kart,
                    shape: BoxShape.circle,
                    border: Border.all(color: ilk ? r.vurgu : r.kenar, width: 2),
                  ),
                ),
                Expanded(child: Container(width: 2, color: son ? Colors.transparent : r.kenar)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Kutu(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Rozet(yerel ? 'Native' : 'Sistem', renk: kaynakRengi, ikon: yerel ? Simgeler.deviceMobile : Simgeler.dns),
                        Text(
                          'v${metin(s['version'])}',
                          style: TextStyle(fontWeight: FontWeight.w700, color: r.metin, fontSize: 15),
                        ),
                        if (enGuncel) const Rozet('En güncel', renk: Marka.zumrut),
                        Text(metin(s['date']), style: TextStyle(color: r.silik, fontSize: 11.5)),
                      ],
                    ),
                    if (metinYa(s['title']) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          metin(s['title']),
                          style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 13.5),
                        ),
                      ),
                    const SizedBox(height: 8),
                    for (final i in haritalar(s['items']))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 1),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: renk(metin(i['type'])).withValues(alpha: .13), borderRadius: BorderRadius.circular(6)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(ikon(metin(i['type'])), size: 12, color: renk(metin(i['type']))),
                                  const SizedBox(width: 4),
                                  Text(
                                    ad(metin(i['type'])),
                                    style: TextStyle(color: renk(metin(i['type'])), fontSize: 10.5, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(metin(i['text']), style: TextStyle(color: r.soluk, fontSize: 12.5, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
