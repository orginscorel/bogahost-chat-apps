import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import '../veri/tercihler.dart';
import 'ayarlar.dart';
import 'bildirimler.dart';
import 'ekip.dart';
import 'gorusme.dart';
import 'ozet.dart';
import 'sohbetler.dart';
import 'ziyaretciler.dart';

enum Bolum { ozet, sohbetler, ziyaretciler, ekip, bildirimler, ayarlar }

/// Kabuktan bağımsız yerlerden (bildirim dokunması) bölüm / sohbet açma istekleri.
final bolumIstegi = ValueNotifier<Bolum?>(null);
final sohbetIstegi = ValueNotifier<int?>(null);

/// Rozetler: sohbetler (okunmamış/bekleyen), ekip (iç sohbet), bildirimler.
final rozetler = ValueNotifier<Map<Bolum, int>>({});

/// Son özet (müsaitlik, acil durum bandı).
final sonOzet = ValueNotifier<Ozet?>(null);

/// Ana kabuk: geniş ekranda yan ray, telefonda alt gezinme. Arka planda 5 sn'de bir özet + bildirim
/// akışını yoklar; yeni ziyaretçi mesajı / sohbet gelirse uygulama açıkken sesli bant gösterir.
class Kabuk extends StatefulWidget {
  const Kabuk({super.key});
  @override
  State<Kabuk> createState() => _KabukState();
}

class _KabukState extends State<Kabuk> with WidgetsBindingObserver {
  Bolum _bolum = Bolum.sohbetler;
  Timer? _sayac;
  StreamSubscription<Map<String, dynamic>>? _push;
  final _gorulen = <String>{};
  bool _ilkAkis = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    bolumIstegi.addListener(_bolumIstek);
    sohbetIstegi.addListener(_sohbetIstek);
    _pushHazirla();
    _yenile();
    _sayac = Timer.periodic(const Duration(seconds: 6), (_) => _yenile());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    bolumIstegi.removeListener(_bolumIstek);
    sohbetIstegi.removeListener(_sohbetIstek);
    _sayac?.cancel();
    _push?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _yenile();
  }

  Future<void> _pushHazirla() async {
    if (!Push.destekli) return;
    Push.gosterilsinMi = (v) => true;
    _push = Push.acildi.listen(_bildirimAcildi);
    final ilk = await Push.baslangic();
    if (ilk != null) _bildirimAcildi(ilk);
    await Push.kaydet(Uyg.api, yol: Uyg.pushYolu, konu: Uyg.pushKonu);
  }

  void _bildirimAcildi(Map<String, dynamic> v) {
    final url = '${v['url'] ?? ''}';
    final m = RegExp(r'open=(\d+)').firstMatch(url);
    if (m != null) {
      sohbetIstegi.value = int.tryParse(m[1]!);
    } else if (url.contains('/internal')) {
      bolumIstegi.value = Bolum.ekip;
    } else {
      bolumIstegi.value = Bolum.bildirimler;
    }
  }

  void _bolumIstek() {
    final b = bolumIstegi.value;
    if (b == null || !mounted) return;
    bolumIstegi.value = null;
    setState(() => _bolum = b);
  }

  void _sohbetIstek() {
    final id = sohbetIstegi.value;
    if (id == null || !mounted) return;
    sohbetIstegi.value = null;
    setState(() => _bolum = Bolum.sohbetler);
    if (!context.genis) {
      Navigator.of(context).push(HizliRota(builder: (_) => GorusmeEkrani(sohbetId: id)));
    } else {
      secilenSohbet.value = id;
    }
  }

  Future<void> _yenile() async {
    try {
      final o = await Depo.ozet();
      sonOzet.value = o;
      final b = await Depo.bildirimler();
      final m = Map<Bolum, int>.from(rozetler.value);
      m[Bolum.sohbetler] = o.bekleyen;
      m[Bolum.ekip] = o.icOkunmamis;
      m[Bolum.bildirimler] = b.okunmamis;
      rozetler.value = m;
      if (b.engelli) {
        bildir('Erişiminiz kapatıldı', mesaj: 'Yönetici bu panele erişiminizi kapattı.', tur: MesajTur.hata);
      }
      // Yeni ziyaretçi olayı → uygulama açıkken bant + ses (ilk yüklemede sessiz)
      for (final x in b.ogeler) {
        if (_gorulen.add(x.id) && !_ilkAkis && x.yasSn < 90 && (x.id.startsWith('conv-') || x.id.startsWith('msg-'))) {
          if (sesAcik.value) SystemSound.play(SystemSoundType.alert);
          bildir(x.baslik, mesaj: x.govde, tur: MesajTur.bilgi);
        }
      }
      _ilkAkis = false;
      if (Push.destekli) Push.rozet(o.bekleyen + o.aktif);
      if (o.musaitlik != null && Uyg.ben.value != null && Uyg.ben.value!.musaitlik != o.musaitlik) {
        Uyg.ben.value = Temsilci.coz({..._temsilciHarita(Uyg.ben.value!), 'availability': o.musaitlik});
      }
    } catch (_) {}
  }

  Map<String, dynamic> _temsilciHarita(Temsilci t) => {
    'id': t.id,
    'display_name': t.ad,
    'email': t.eposta,
    'role': t.rol,
    'role_name': t.rolAdi,
    'permissions': t.yetkiler,
    'is_admin': t.yonetici,
    'availability': t.musaitlik,
    'avatar': t.avatar,
    'department': t.bolum,
    'totp_enabled': t.totp,
  };

  List<(Bolum, IconData, String)> get _bolumler => [
    (Bolum.ozet, Simgeler.spaceDashboard, 'Özet'),
    (Bolum.sohbetler, Simgeler.forum, 'Sohbetler'),
    if (Uyg.yetki('visitors.view')) (Bolum.ziyaretciler, Simgeler.visibility, 'Ziyaretçiler'),
    if (Uyg.yetki('internal.use')) (Bolum.ekip, Simgeler.groups, 'Ekip'),
    (Bolum.bildirimler, Simgeler.notifications, 'Bildirimler'),
    (Bolum.ayarlar, Simgeler.settings, 'Ayarlar'),
  ];

  Widget _govde() => switch (_bolum) {
    Bolum.ozet => const OzetEkrani(),
    Bolum.sohbetler => const SohbetlerEkrani(),
    Bolum.ziyaretciler => const ZiyaretcilerEkrani(),
    Bolum.ekip => const EkipEkrani(),
    Bolum.bildirimler => const BildirimlerEkrani(),
    Bolum.ayarlar => const AyarlarEkrani(),
  };

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final genis = context.genis;
    final bolumler = _bolumler;
    if (!bolumler.any((b) => b.$1 == _bolum)) _bolum = Bolum.sohbetler;
    final govde = Column(
      children: [
        ValueListenableBuilder<Ozet?>(
          valueListenable: sonOzet,
          builder: (_, o, _) => o != null && (o.acil || o.saldiri)
              ? Container(
                  width: double.infinity,
                  color: Marka.gul,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    o.saldiri ? 'Saldırı modu etkin — widget kısıtlı çalışıyor.' : 'Acil durum bildirimi etkin${o.acilTur == null ? '' : ' (${o.acilTur})'}.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: _govde()),
      ],
    );
    if (genis) {
      return Scaffold(
        body: Row(
          children: [
            ValueListenableBuilder<Map<Bolum, int>>(
              valueListenable: rozetler,
              builder: (_, roz, _) => Container(
                width: 92,
                decoration: BoxDecoration(
                  color: r.kart,
                  border: Border(right: BorderSide(color: r.kenar)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      const BogaIsaret(boyut: 40, isaret: AcilisIsaret.destek),
                      const SizedBox(height: 18),
                      for (final (b, ikon, ad) in bolumler) _rayOgesi(b, ikon, ad, roz[b] ?? 0, r),
                      const Spacer(),
                      ValueListenableBuilder<Temsilci?>(
                        valueListenable: Uyg.ben,
                        builder: (_, t, _) => t == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Tooltip(
                                  message: '${t.ad} · ${musaitlikAdi(t.musaitlik)}',
                                  child: Stack(
                                    children: [
                                      KisiAvatar(t.ad, url: t.avatar, boyut: 36),
                                      Positioned(right: 0, bottom: 0, child: Nokta(musaitlikRengi(t.musaitlik), boyut: 12, halka: r.kart)),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: govde),
          ],
        ),
      );
    }
    final alt = bolumler.take(5).toList();
    return Scaffold(
      body: govde,
      bottomNavigationBar: ValueListenableBuilder<Map<Bolum, int>>(
        valueListenable: rozetler,
        builder: (_, roz, _) => NavigationBar(
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: alt.indexWhere((b) => b.$1 == _bolum).clamp(0, alt.length - 1),
          onDestinationSelected: (i) => setState(() => _bolum = alt[i].$1),
          destinations: [
            for (final (b, ikon, ad) in alt)
              NavigationDestination(
                icon: Badge(isLabelVisible: (roz[b] ?? 0) > 0, label: Text('${roz[b] ?? 0}'), child: Icon(ikon)),
                label: ad,
              ),
          ],
        ),
      ),
    );
  }

  Widget _rayOgesi(Bolum b, IconData ikon, String ad, int rozet, Renkler r) {
    final secili = b == _bolum;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _bolum = b),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(color: secili ? r.vurguYumusak : null, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Badge(
                isLabelVisible: rozet > 0,
                label: Text('$rozet'),
                child: Icon(ikon, color: secili ? r.vurgu : r.soluk, size: 22),
              ),
              const SizedBox(height: 4),
              Text(
                ad,
                style: TextStyle(fontSize: 10.5, fontWeight: secili ? FontWeight.w600 : FontWeight.w500, color: secili ? r.metin : r.soluk),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
