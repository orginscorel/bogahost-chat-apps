import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:destek/main.dart';
import 'package:destek/veri/tercihler.dart';

void main() {
  testWidgets('ölçek sarmalı: içerik küçültülmüş mantıksal boyutta yerleşir, taşma olmaz', (t) async {
    t.view.physicalSize = const Size(2560, 1440);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    arayuzOlcegi.value = 0; // otomatik: 2560 ≥ 2300 → 1.2
    final anahtar = GlobalKey();
    await t.pumpWidget(
      MaterialApp(
        builder: (_, c) => OlcekSarmal(child: c!),
        home: Scaffold(body: SizedBox.expand(key: anahtar)),
      ),
    );
    final boyut = t.getSize(find.byKey(anahtar));
    expect(boyut.width, closeTo(2560 / 1.2, .5));
    expect(boyut.height, closeTo(1440 / 1.2, .5));
    expect(MediaQuery.sizeOf(anahtar.currentContext!).width, closeTo(2560 / 1.2, .5));
    // Ekrana çizilen alan tam pencere: sağ alt köşe (2559,1439) içerikte
    final rb = anahtar.currentContext!.findRenderObject()! as RenderBox;
    final sagAlt = rb.localToGlobal(Offset(rb.size.width, rb.size.height));
    expect(sagAlt.dx, closeTo(2560, 1));
    expect(sagAlt.dy, closeTo(1440, 1));
    expect(t.takeException(), isNull);
  });
}
