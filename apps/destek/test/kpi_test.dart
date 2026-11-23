import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:destek/ortak/parcalar.dart';
import 'package:destek/ortak/simgeler.dart';

void main() {
  for (final olcek in [1.0, 1.3, 1.6]) {
    testWidgets('KPI kartları yazı ölçeği $olcek ile taşmaz', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: temaKur(Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(olcek)),
            child: Scaffold(
              body: Column(
                children: [
                  EsitIzgara(
                    enAz: 150,
                    yukseklik: 132,
                    children: [
                      for (var i = 0; i < 3; i++)
                        KpiKart(
                          etiket: 'Bugünkü ziyaretçi sayısı',
                          deger: '1234567',
                          alt: 'tekil oturum · uzun açıklama',
                          ikon: Simgeler.peopleAlt,
                          renk: Marka.mavi,
                          canli: true,
                          egilim: 12.5,
                        ),
                    ],
                  ),
                  EsitIzgara(
                    enAz: 146,
                    yukseklik: 72,
                    children: [
                      for (var i = 0; i < 3; i++)
                        KpiKart(
                          kucuk: true,
                          etiket: 'Ortalama ilk yanıt süresi',
                          deger: '12 dk 34 sn',
                          alt: 'son 7 gün',
                          ikon: Simgeler.timer,
                          renk: Marka.mavi,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }
}
