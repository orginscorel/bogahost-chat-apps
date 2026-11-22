import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../oturum.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Sürüm ve değişiklik günlüğü: uygulama sürümü, sunucu sürümü, sunucudaki changelog.
class SurumEkrani extends StatelessWidget {
  const SurumEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final platform = Platform.isIOS
        ? 'iOS'
        : Platform.isMacOS
        ? 'macOS'
        : Platform.isAndroid
        ? 'Android'
        : Platform.isWindows
        ? 'Windows'
        : Platform.operatingSystem;
    return AyarSayfa(
      baslik: 'Sürüm',
      yukle: Panel.surum,
      govde: (context, v, yenile) {
        final gunluk = haritalar(v['changelog']);
        return ListView(
          children: [
            Kutu(
              child: Row(
                children: [
                  const BogahostLogoGorunumu(genislik: 56, yalnizAmblem: true),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bogahost Chat', style: gosterim(18, renk: r.metin)),
                        Text('Uygulama ${Uyg.api.surum} · $platform', style: TextStyle(color: r.soluk, fontSize: 13)),
                        Text(
                          'Sunucu ${metin(v['version'])} · ${Uyg.api.sunucu.replaceFirst('https://', '')}',
                          style: TextStyle(color: r.silik, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Baslik('Değişiklik günlüğü'),
            for (final s in gunluk)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Kutu(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Rozet('v${metin(s['version'])}', renk: Marka.mor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              metin(s['title']),
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                            ),
                          ),
                          Text(metin(s['date']), style: TextStyle(color: r.silik, fontSize: 11.5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final i in haritalar(s['items']))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(_ikon(metin(i['type'])), size: 15, color: _renk(metin(i['type']))),
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
          ],
        );
      },
    );
  }

  IconData _ikon(String t) => switch (t) {
    'new' || 'added' || 'feature' => Simgeler.sparkle,
    'fixed' || 'fix' => Simgeler.build,
    'security' => Simgeler.shieldCheck,
    'removed' => Simgeler.remove,
    _ => Simgeler.trendingUp,
  };
  Color _renk(String t) => switch (t) {
    'new' || 'added' || 'feature' => Marka.zumrut,
    'fixed' || 'fix' => Marka.kehribar,
    'security' => Marka.gul,
    _ => Marka.mavi,
  };
}
