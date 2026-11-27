import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ortak/parcalar.dart';
import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import '../veri/tercihler.dart';
import 'ayar/acil.dart';
import 'ayar/bildirim.dart';
import 'ayar/cihazlar.dart';
import 'ayar/denetim.dart';
import 'ayar/gecmis.dart';
import 'ayar/hazir.dart';
import 'ayar/mesai.dart';
import 'ayar/personel.dart';
import 'ayar/profil.dart';
import 'ayar/raporlar.dart';
import 'ayar/surum.dart';
import 'ayar/tetikleyiciler.dart';
import 'ayar/whatsapp.dart';
import 'ayar/widget_ayar.dart';
import 'ayar/yasaklar.dart';
import 'ayarlar.dart';
import 'bildirimler.dart';
import 'ekip.dart';
import 'gorusme.dart';
import 'ozet.dart';
import 'sohbetler.dart';
import 'ziyaretciler.dart';

/// Kabuktaki bölümler. İlk beşi telefonda alt gezinmede; geri kalanı yan menüde (geniş) ya da Menü sekmesinde.
enum Bolum {
  ozet,
  sohbetler,
  ziyaretciler,
  ekip,
  bildirimler,
  raporlar,
  gecmis,
  denetim,
  personel,
  roller,
  bolumler,
  yasaklar,
  hazir,
  tetikleyiciler,
  widgetAyar,
  mesai,
  whatsapp,
  acil,
  cihazlar,
  surum,
  ayarlar,
}

/// Kabuktan bağımsız yerlerden (bildirim dokunması) bölüm / sohbet açma istekleri.
final bolumIstegi = ValueNotifier<Bolum?>(null);
final sohbetIstegi = ValueNotifier<int?>(null);

/// Geçmiş sohbetler ekranına taşınacak arama metni (üst çubuktaki genel aramadan).
final gecmisSorgusu = ValueNotifier<String?>(null);

/// Rozetler: sohbetler (bekleyen), ziyaretçiler (çevrimiçi), ekip (iç sohbet), bildirimler (okunmamış).
final rozetler = ValueNotifier<Map<Bolum, int>>({});

/// Son özet (müsaitlik, acil durum bandı) ve son bildirim akışı (zil açılırı için).
final sonOzet = ValueNotifier<Ozet?>(null);
final sonBildirimler = ValueNotifier<List<Bildirim>>(const []);

class MenuOgesi {
  const MenuOgesi(this.bolum, this.ikon, this.ad, {this.yetki, this.kisa});
  final Bolum bolum;
  final IconData ikon;
  final String ad;
  final String? yetki;

  /// Telefon alt çubuğundaki kısa ad.
  final String? kisa;
}

class MenuGrubu {
  const MenuGrubu(this.ad, this.ogeler);
  final String ad;
  final List<MenuOgesi> ogeler;
}

/// Web panelindeki yan menü düzeni; yetkisi olmayanlar elenir.
List<MenuGrubu> menuGruplari() {
  const tum = [
    MenuGrubu('Günlük iş', [
      MenuOgesi(Bolum.ozet, Simgeler.spaceDashboard, 'Genel Bakış', kisa: 'Özet'),
      MenuOgesi(Bolum.sohbetler, Simgeler.forum, 'Aktif Sohbetler', yetki: 'chats.view', kisa: 'Sohbetler'),
      MenuOgesi(Bolum.ziyaretciler, Simgeler.visibility, 'Canlı Ziyaretçiler', yetki: 'visitors.view', kisa: 'Ziyaretçiler'),
      MenuOgesi(Bolum.ekip, Simgeler.groups, 'Ekip İçi Sohbet', yetki: 'internal.use', kisa: 'Ekip'),
      MenuOgesi(Bolum.bildirimler, Simgeler.notifications, 'Bildirimler'),
    ]),
    MenuGrubu('Analiz', [
      MenuOgesi(Bolum.raporlar, Simgeler.chartBar, 'İstatistikler & Raporlar', yetki: 'reports.view'),
      MenuOgesi(Bolum.gecmis, Simgeler.history, 'Geçmiş Sohbetler', yetki: 'chats.view'),
      MenuOgesi(Bolum.denetim, Simgeler.clipboardText, 'Denetim Kaydı', yetki: 'settings.manage'),
    ]),
    MenuGrubu('Yönetim', [
      MenuOgesi(Bolum.personel, Simgeler.usersThree, 'Personeller', yetki: 'agents.manage'),
      MenuOgesi(Bolum.roller, Simgeler.shieldCheck, 'Roller & Yetkiler', yetki: 'roles.manage'),
      MenuOgesi(Bolum.bolumler, Simgeler.accountTree, 'Departmanlar', yetki: 'departments.manage'),
      MenuOgesi(Bolum.yasaklar, Simgeler.prohibit, 'Yasaklılar', yetki: 'bans.manage'),
      MenuOgesi(Bolum.hazir, Simgeler.chatText, 'Hazır Cevaplar', yetki: 'canned.manage'),
      MenuOgesi(Bolum.tetikleyiciler, Simgeler.bolt, 'Tetikleyiciler', yetki: 'settings.manage'),
      MenuOgesi(Bolum.widgetAyar, Simgeler.paintBrush, 'Widget', yetki: 'widget.manage'),
      MenuOgesi(Bolum.mesai, Simgeler.clock, 'Mesai Saatleri', yetki: 'settings.manage'),
      MenuOgesi(Bolum.whatsapp, Simgeler.whatsapp, 'WhatsApp', yetki: 'settings.manage'),
      MenuOgesi(Bolum.acil, Simgeler.siren, 'Acil Durum & Saldırı', yetki: 'settings.manage'),
      MenuOgesi(Bolum.cihazlar, Simgeler.deviceMobile, 'Cihazlar & Oturumlar', yetki: 'settings.manage'),
    ]),
    MenuGrubu('Hesap & Yardım', [
      MenuOgesi(Bolum.ayarlar, Simgeler.settings, 'Ayarlar', kisa: 'Menü'),
      MenuOgesi(Bolum.surum, Simgeler.gitBranch, 'Sürüm Notları'),
    ]),
  ];
  return [
    for (final g in tum)
      if (g.ogeler.any(_gorunur)) MenuGrubu(g.ad, g.ogeler.where(_gorunur).toList()),
  ];
}

bool _gorunur(MenuOgesi o) => o.yetki == null || Uyg.yetki(o.yetki!);

/// Bölümün ekranı (kabuk içinde ya da telefonda rota olarak).
Widget bolumEkrani(Bolum b) => switch (b) {
  Bolum.ozet => const OzetEkrani(),
  Bolum.sohbetler => const SohbetlerEkrani(),
  Bolum.ziyaretciler => const ZiyaretcilerEkrani(),
  Bolum.ekip => const EkipEkrani(),
  Bolum.bildirimler => const BildirimlerEkrani(),
  Bolum.raporlar => const RaporlarEkrani(),
  Bolum.gecmis => const GecmisEkrani(),
  Bolum.denetim => const DenetimEkrani(),
  Bolum.personel => const PersonelEkrani(),
  Bolum.roller => const RollerEkrani(),
  Bolum.bolumler => const BolumlerEkrani(),
  Bolum.yasaklar => const YasaklarEkrani(),
  Bolum.hazir => const HazirYanitlarEkrani(),
  Bolum.tetikleyiciler => const TetikleyicilerEkrani(),
  Bolum.widgetAyar => const WidgetAyarEkrani(),
  Bolum.mesai => const MesaiEkrani(),
  Bolum.whatsapp => const WhatsappEkrani(),
  Bolum.acil => const AcilDurumEkrani(),
  Bolum.cihazlar => const CihazlarEkrani(),
  Bolum.surum => const SurumEkrani(),
  Bolum.ayarlar => const AyarlarEkrani(),
};

/// Telefon alt çubuğundaki bölümler.
const altBolumler = [Bolum.ozet, Bolum.sohbetler, Bolum.ziyaretciler, Bolum.ekip, Bolum.ayarlar];

Map<String, dynamic> temsilciHarita(Temsilci t) => {
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

/// Müsaitlik değiştir (üst çubuk, pano, ayarlar — hepsi burayı kullanır).
Future<void> musaitlikDegistir(String m) async {
  final v = await islem(() => Depo.musaitlik(m));
  if (v == null) return;
  final t = Uyg.ben.value;
  if (t == null) return;
  Uyg.ben.value = Temsilci.coz({...temsilciHarita(t), 'availability': v});
  bildir('Durum: ${musaitlikAdi(v)}', tur: MesajTur.basari);
}

/// Bildirime dokunma: okundu işaretle, ilgili yere git.
Future<void> bildirimAc(Bildirim b) async {
  final vid = b.veritabaniId;
  if (vid != null && !b.okundu) await Depo.bildirimOkundu(vid).catchError((_) {});
  final sid = b.sohbetId;
  if (sid != null) {
    sohbetIstegi.value = sid;
  } else if (b.url.contains('/internal')) {
    bolumIstegi.value = Bolum.ekip;
  } else if (b.url.contains('/visitors')) {
    bolumIstegi.value = Bolum.ziyaretciler;
  } else {
    bolumIstegi.value = Bolum.bildirimler;
  }
}

/// Ekran AppBar'ına eklenen ortak eylemler. Geniş ekranda (kabuk içinde) üst çubuk zaten arama / durum / zil /
/// tema / profil taşır, ekranlar hiçbir şey eklemez; telefonda ve itilmiş rotalarda durum noktası + zil.
List<Widget> kabukEylemleri(BuildContext context) =>
    kabukGomulu(context) || context.genis ? const [] : const [MusaitlikDugmesi(kisa: true), SesDugmesi(), ZilDugmesi(), SizedBox(width: 4)];

/// Ekranın AppBar'ı: kabuk içinde gömülüyken yok (başlık üst çubukta); `alt` varsa yalnız o gösterilir.
PreferredSizeWidget? ekranBasligi(BuildContext context, String baslik, {List<Widget> eylemler = const [], PreferredSizeWidget? alt}) {
  if (kabukGomulu(context)) return alt == null ? null : AppBar(toolbarHeight: 0, bottom: alt);
  return AppBar(title: Text(baslik), actions: [...eylemler, ...kabukEylemleri(context)], bottom: alt);
}

/// Ana kabuk: geniş ekranda web paneli gibi koyu yan menü (74 px, üzerine gelince/sabitleyince 248 px),
/// telefonda alt gezinme + Menü. Arka planda 6 sn'de bir özet + bildirim akışını yoklar; yeni ziyaretçi
/// mesajı / sohbet gelirse uygulama açıkken sesli bant gösterir.
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
    _git(b);
  }

  /// Geniş ekranda her bölüm kabuk içinde açılır; telefonda alt çubukta olmayanlar rota olarak itilir.
  void _git(Bolum b) {
    if (context.genis || altBolumler.contains(b)) {
      setState(() => _bolum = b);
    } else {
      Navigator.of(context).push(HizliRota(builder: (_) => bolumEkrani(b)));
    }
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
      sonBildirimler.value = b.ogeler;
      final yeni = {...rozetler.value, Bolum.sohbetler: o.bekleyen, Bolum.ziyaretciler: o.cevrimici, Bolum.ekip: o.icOkunmamis, Bolum.bildirimler: b.okunmamis};
      // Değer değişmediyse dinleyiciler (yan menü, alt çubuk) boşuna yeniden çizilmesin.
      if (!mapEquals(yeni, rozetler.value)) rozetler.value = yeni;
      if (b.engelli) {
        bildir('Erişiminiz kapatıldı', mesaj: 'Yönetici bu panele erişiminizi kapattı.', tur: MesajTur.hata);
      }
      // Yeni ziyaretçi olayı → uygulama açıkken bant + ses (ilk yüklemede sessiz; Rahatsız Etme'de sessiz)
      final dnd = (Uyg.ben.value?.musaitlik ?? o.musaitlik) == 'dnd';
      for (final x in b.ogeler) {
        if (_gorulen.add(x.id) && !_ilkAkis && !dnd && x.yasSn < 90 && (x.id.startsWith('conv-') || x.id.startsWith('msg-'))) {
          if (sesAcik.value) SystemSound.play(SystemSoundType.alert);
          bildir(x.baslik, mesaj: x.govde, tur: MesajTur.bilgi);
        }
      }
      _ilkAkis = false;
      if (Push.destekli) Push.rozet(o.bekleyen + o.aktif);
      if (o.musaitlik != null && Uyg.ben.value != null && Uyg.ben.value!.musaitlik != o.musaitlik) {
        Uyg.ben.value = Temsilci.coz({...temsilciHarita(Uyg.ben.value!), 'availability': o.musaitlik});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final genis = context.genis;
    final gruplar = menuGruplari();
    final hepsi = [for (final g in gruplar) ...g.ogeler];
    if (!hepsi.any((o) => o.bolum == _bolum)) _bolum = Bolum.sohbetler;
    final govde = Column(
      children: [
        ValueListenableBuilder<Ozet?>(
          valueListenable: sonOzet,
          builder: (_, o, _) => o != null && (o.acil || o.saldiri)
              ? Material(
                  color: Marka.gul,
                  child: InkWell(
                    onTap: Uyg.yetki('settings.manage') ? () => _git(Bolum.acil) : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Simgeler.siren, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              o.saldiri
                                  ? 'Saldırı modu etkin — widget kısıtlı çalışıyor.'
                                  : 'Acil durum bildirimi etkin${o.acilTur == null ? '' : ' (${o.acilTur})'}.',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          if (Uyg.yetki('settings.manage'))
                            const Text(
                              'Yönet →',
                              style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: bolumEkrani(_bolum)),
      ],
    );
    if (genis) {
      final aktif = hepsi.firstWhere((o) => o.bolum == _bolum);
      return Scaffold(
        body: Row(
          children: [
            YanMenu(bolum: _bolum, gruplar: gruplar, onSec: _git),
            Expanded(
              child: Column(
                children: [
                  UstCubuk(baslik: aktif.ad, ikon: aktif.ikon),
                  Expanded(child: KabukIci(child: govde)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final alt = [for (final b in altBolumler) hepsi.where((o) => o.bolum == b).firstOrNull].whereType<MenuOgesi>().toList();
    final i = alt.indexWhere((o) => o.bolum == _bolum);
    return Scaffold(
      body: govde,
      bottomNavigationBar: ValueListenableBuilder<Map<Bolum, int>>(
        valueListenable: rozetler,
        builder: (_, roz, _) => NavigationBar(
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: i < 0 ? alt.length - 1 : i,
          onDestinationSelected: (i) => setState(() => _bolum = alt[i].bolum),
          destinations: [
            for (final o in alt)
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: _rozetSayisi(o.bolum, roz) > 0,
                  backgroundColor: _rozetRengi(o.bolum, context.r),
                  label: Text('${_rozetSayisi(o.bolum, roz)}'),
                  child: Icon(o.bolum == Bolum.ayarlar ? Simgeler.menu : o.ikon),
                ),
                label: o.kisa ?? o.ad,
              ),
          ],
        ),
      ),
    );
  }

  int _rozetSayisi(Bolum b, Map<Bolum, int> roz) => b == Bolum.ayarlar ? (roz[Bolum.bildirimler] ?? 0) : (roz[b] ?? 0);
}

Color _rozetRengi(Bolum b, Renkler r) => switch (b) {
  Bolum.ziyaretciler => Marka.zumrut,
  Bolum.ekip => Marka.mavi,
  Bolum.bildirimler || Bolum.ayarlar => Marka.gul,
  _ => r.vurgu,
};

// ---------------------------------------------------------------------------------------------------
// Yan menü (geniş ekran)
// ---------------------------------------------------------------------------------------------------

/// Koyu yan menü: 74 px daraltılmış; üzerine gelince ya da sabitlenince 248 px. Gruplu, rozetli, alt
/// kısmında sabitleme düğmesi, sürüm ve kullanıcı.
class YanMenu extends StatefulWidget {
  const YanMenu({super.key, required this.bolum, required this.gruplar, required this.onSec});
  final Bolum bolum;
  final List<MenuGrubu> gruplar;
  final ValueChanged<Bolum> onSec;
  @override
  State<YanMenu> createState() => _YanMenuState();
}

class _YanMenuState extends State<YanMenu> {
  bool _hover = false;
  // Uygulamanın ilk renk stili: tema kartı zemini + kenar (açık/koyu temaya uyar), vurgu mor.
  late Color _zemin, _kenar;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    _zemin = r.kart;
    _kenar = r.kenar;
    return ValueListenableBuilder<bool>(
      valueListenable: menuSabit,
      builder: (_, sabit, _) {
        final acik = sabit || _hover;
        return MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: acik ? 248 : 74,
            decoration: BoxDecoration(
              color: _zemin,
              border: Border(right: BorderSide(color: _kenar)),
            ),
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _logo(acik, r),
                  Expanded(
                    child: ValueListenableBuilder<Map<Bolum, int>>(
                      valueListenable: rozetler,
                      builder: (_, roz, _) => ValueListenableBuilder<Ozet?>(
                        valueListenable: sonOzet,
                        builder: (_, o, _) => ListView(
                          padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                          children: [
                            for (final (gi, g) in widget.gruplar.indexed) ...[
                              _grupBasligi(g.ad, acik, r, ilk: gi == 0),
                              for (final m in g.ogeler) _oge(m, acik, roz[m.bolum] ?? 0, m.bolum == Bolum.acil && o != null && (o.acil || o.saldiri), r),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  _alt(acik, sabit, r),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _logo(bool acik, Renkler r) => SizedBox(
    height: 64,
    child: Row(
      children: [
        const SizedBox(width: 17),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Marka.mor, Marka.indigo], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: BogaIsaret(boyut: 26, isaret: AcilisIsaret.destek)),
        ),
        if (acik) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bogahost',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(color: r.metin, fontWeight: FontWeight.w700, fontSize: 14.5),
                ),
                Text(
                  'Canlı Destek',
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(color: r.soluk, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _grupBasligi(String ad, bool acik, Renkler r, {bool ilk = false}) => acik
      ? Padding(
          padding: EdgeInsets.fromLTRB(22, ilk ? 6 : 16, 12, 6),
          child: Text(
            ad.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: TextStyle(color: r.silik, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .8),
          ),
        )
      : ilk
      ? const SizedBox(height: 6)
      : Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
          child: Divider(height: 1, color: _kenar),
        );

  Widget _oge(MenuOgesi m, bool acik, int rozet, bool uyari, Renkler r) {
    final secili = m.bolum == widget.bolum;
    final rozetRengi = _rozetRengi(m.bolum, r);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: _MenuSatiri(
        secili: secili,
        onTap: () => widget.onSec(m.bolum),
        tooltip: acik ? null : m.ad,
        child: Row(
          children: [
            SizedBox(
              width: 54,
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(secili ? simgeDolu(m.ikon) : m.ikon, size: 21, color: secili ? r.vurgu : r.soluk),
                    if (!acik && rozet > 0) Positioned(right: -10, top: -7, child: _rozet(rozet, rozetRengi, kucuk: true)),
                    if (uyari) Positioned(right: -4, top: -3, child: Nokta(Marka.gul, boyut: 8, halka: _zemin)),
                  ],
                ),
              ),
            ),
            if (acik) ...[
              Expanded(
                child: Text(
                  m.ad,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                  style: TextStyle(color: secili ? r.vurgu : r.metin, fontSize: 13.5, fontWeight: secili ? FontWeight.w600 : FontWeight.w500),
                ),
              ),
              if (rozet > 0) _rozet(rozet, rozetRengi),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rozet(int n, Color renk, {bool kucuk = false}) => Container(
    padding: EdgeInsets.symmetric(horizontal: kucuk ? 4 : 7, vertical: kucuk ? 1 : 2),
    decoration: BoxDecoration(
      color: renk,
      borderRadius: BorderRadius.circular(99),
      border: kucuk ? Border.all(color: _zemin, width: 1.5) : null,
    ),
    child: Text(
      n > 99 ? '99+' : '$n',
      style: TextStyle(color: Colors.white, fontSize: kucuk ? 9.5 : 11, fontWeight: FontWeight.w700, height: 1.2),
    ),
  );

  Widget _alt(bool acik, bool sabit, Renkler r) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Divider(height: 1, color: _kenar),
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
        child: _MenuSatiri(
          secili: false,
          onTap: () => menuSabitKaydet(!sabit),
          tooltip: acik ? null : (sabit ? 'Menüyü daralt' : 'Menüyü sabitle'),
          yukseklik: 36,
          child: Row(
            children: [
              SizedBox(width: 54, child: Icon(sabit ? Simgeler.chevronLeft : Simgeler.chevronRight, size: 18, color: r.soluk)),
              if (acik)
                Expanded(
                  child: Text(
                    sabit ? 'Menüyü daralt' : 'Menüyü sabit tut',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: TextStyle(color: r.soluk, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (acik)
        ValueListenableBuilder<Ozet?>(
          valueListenable: sonOzet,
          builder: (_, o, _) => InkWell(
            onTap: () => widget.onSec(Bolum.surum),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 12, 2),
              child: Text(
                'Panel v${o?.surum ?? Uyg.sunucuSurumu} · Uygulama ${Uyg.api.surum}',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: TextStyle(color: r.silik, fontSize: 10.5),
              ),
            ),
          ),
        ),
      ValueListenableBuilder<Temsilci?>(
        valueListenable: Uyg.ben,
        builder: (_, t, _) => t == null
            ? const SizedBox(height: 8)
            : Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                child: _MenuSatiri(
                  secili: false,
                  onTap: () => widget.onSec(Bolum.ayarlar),
                  tooltip: acik ? null : '${t.ad} · ${musaitlikAdi(t.musaitlik)}',
                  yukseklik: 52,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 54,
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              KisiAvatar(t.ad, url: t.avatar, boyut: 34),
                              Positioned(right: -1, bottom: -1, child: Nokta(musaitlikRengi(t.musaitlik), boyut: 11, halka: _zemin)),
                            ],
                          ),
                        ),
                      ),
                      if (acik) ...[
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.ad,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${t.rolAdi} · ${musaitlikAdi(t.musaitlik)}',
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                                style: TextStyle(color: r.soluk, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Çıkış',
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            if (await onayla(context, 'Oturum kapatılsın mı?', evet: 'Çıkış')) Uyg.cikis();
                          },
                          icon: Icon(Simgeler.logout, size: 18, color: r.soluk),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    ],
  );
}

/// Yan menü satırı: hover'da %6 beyaz, seçiliyse vurgu/22 + sol 3 px çubuk.
class _MenuSatiri extends StatefulWidget {
  const _MenuSatiri({required this.secili, required this.onTap, required this.child, this.tooltip, this.yukseklik = 44});
  final bool secili;
  final VoidCallback onTap;
  final Widget child;
  final String? tooltip;
  final double yukseklik;
  @override
  State<_MenuSatiri> createState() => _MenuSatiriState();
}

class _MenuSatiriState extends State<_MenuSatiri> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final govde = MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: widget.yukseklik,
          decoration: BoxDecoration(
            color: widget.secili ? r.vurguYumusak : (_h ? r.metin.withValues(alpha: .05) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              if (widget.secili)
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(color: r.vurgu, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              widget.child,
            ],
          ),
        ),
      ),
    );
    return widget.tooltip == null ? govde : Tooltip(message: widget.tooltip!, waitDuration: const Duration(milliseconds: 400), child: govde);
  }
}

// ---------------------------------------------------------------------------------------------------
// Üst çubuk (geniş ekran): sayfa başlığı · arama · durum · zil · tema · profil
// ---------------------------------------------------------------------------------------------------

class UstCubuk extends StatelessWidget {
  const UstCubuk({super.key, required this.baslik, required this.ikon});
  final String baslik;
  final IconData ikon;
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final dar = MediaQuery.sizeOf(context).width < 1180;
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: r.kart,
        border: Border(bottom: BorderSide(color: r.kenar)),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 20, color: r.vurgu),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              baslik,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gosterim(18, renk: r.metin, agirlik: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          if (dar) const AramaDugmesi() else const AramaHapi(),
          const SizedBox(width: 8),
          const MusaitlikDugmesi(),
          const SizedBox(width: 2),
          const SesDugmesi(),
          const ZilDugmesi(),
          const TemaDugmesi(),
          const SizedBox(width: 6),
          const ProfilDugmesi(),
        ],
      ),
    );
  }
}

/// Üst çubuktaki arama alanı görünümlü düğme.
class AramaHapi extends StatelessWidget {
  const AramaHapi({super.key});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showDialog(context: context, builder: (_) => const _AramaDiyalog()),
      child: Container(
        width: 260,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: r.ic,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: r.kenar),
        ),
        child: Row(
          children: [
            Icon(Simgeler.search, size: 18, color: r.silik),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ziyaretçi, e-posta, #sohbet ara…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: r.silik, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------------
// Üst çubuk düğmeleri
// ---------------------------------------------------------------------------------------------------

/// Sağ üstte açılır panel (zil, profil): şeffaf perde + sağa yaslı kart.
Future<T?> acilirPanel<T>(BuildContext context, Widget child, {double genislik = 380}) => showDialog<T>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .12),
  builder: (c) => SafeArea(
    child: Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 58, 12, 12),
        child: Material(
          color: c.r.kart,
          elevation: 10,
          shadowColor: Colors.black.withValues(alpha: .3),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: genislik, maxHeight: MediaQuery.sizeOf(c).height - 90),
            child: child,
          ),
        ),
      ),
    ),
  ),
);

/// Müsaitlik: çevrimiçi / uzakta / rahatsız etme / çevrimdışı.
class MusaitlikDugmesi extends StatelessWidget {
  const MusaitlikDugmesi({super.key, this.kisa = false});
  final bool kisa;

  static const aciklama = {
    'online': 'Yeni sohbetler size dağıtılır',
    'away': 'Uzakta — dağıtımda en sona alınırsınız',
    'dnd': 'Rahatsız Etme 🔕 — ses ve dağıtım kapalı',
    'offline': 'Çevrimdışı — sohbet almazsınız',
  };

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return ValueListenableBuilder<Temsilci?>(
      valueListenable: Uyg.ben,
      builder: (_, t, _) {
        final m = t?.musaitlik ?? 'online';
        return PopupMenuButton<String>(
          tooltip: 'Durum: ${musaitlikAdi(m)}',
          onSelected: musaitlikDegistir,
          position: PopupMenuPosition.under,
          itemBuilder: (_) => [
            for (final k in const ['online', 'away', 'dnd', 'offline'])
              PopupMenuItem(
                value: k,
                child: Row(
                  children: [
                    Nokta(musaitlikRengi(k), boyut: 10),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(musaitlikAdi(k), style: TextStyle(fontWeight: k == m ? FontWeight.w700 : FontWeight.w500, fontSize: 13.5)),
                          Text(aciklama[k]!, style: TextStyle(color: r.silik, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (k == m) Icon(Simgeler.check, size: 16, color: r.vurgu),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              height: 40,
              padding: EdgeInsets.fromLTRB(kisa ? 12 : 12, 0, kisa ? 12 : 8, 0),
              decoration: BoxDecoration(
                color: musaitlikRengi(m).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: musaitlikRengi(m).withValues(alpha: .35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Nokta(musaitlikRengi(m), boyut: 10),
                  if (!kisa) ...[
                    const SizedBox(width: 7),
                    Text(
                      musaitlikAdi(m),
                      style: TextStyle(color: r.metin, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    Icon(Simgeler.expandMore, size: 16, color: r.soluk),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Zil: okunmamış sayısı + açılır liste.
class ZilDugmesi extends StatelessWidget {
  const ZilDugmesi({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Map<Bolum, int>>(
    valueListenable: rozetler,
    builder: (_, roz, _) {
      final n = roz[Bolum.bildirimler] ?? 0;
      return IconButton(
        tooltip: n > 0 ? '$n okunmamış bildirim' : 'Bildirimler',
        onPressed: () => acilirPanel(context, const ZilPaneli()),
        icon: Badge(
          isLabelVisible: n > 0,
          backgroundColor: Marka.gul,
          label: Text(n > 99 ? '99+' : '$n'),
          child: Icon(n > 0 ? Simgeler.notificationsActive : Simgeler.notifications),
        ),
      );
    },
  );
}

class ZilPaneli extends StatelessWidget {
  const ZilPaneli({super.key});

  Color _renk(Bildirim b, Renkler r) => b.okundu
      ? r.silik
      : b.id.startsWith('conv-')
      ? Marka.gul
      : b.url.contains('/internal')
      ? Marka.mavi
      : r.vurgu;

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return ValueListenableBuilder<List<Bildirim>>(
      valueListenable: sonBildirimler,
      builder: (_, l, _) {
        final okunmamis = l.where((b) => !b.okundu).length;
        final o = sonOzet.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
              child: Row(
                children: [
                  Text(
                    'Bildirimler',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: r.metin),
                  ),
                  const SizedBox(width: 8),
                  if (okunmamis > 0) Rozet('$okunmamis yeni', renk: Marka.gul),
                  const Spacer(),
                  if (okunmamis > 0)
                    TextButton(
                      onPressed: () async {
                        await islem(() => Depo.bildirimlerOkundu(), tamam: 'Hepsi okundu');
                        sonBildirimler.value = [
                          for (final b in l) Bildirim.coz({'id': b.id, 'title': b.baslik, 'body': b.govde, 'url': b.url, 'read': true, 'age_s': b.yasSn}),
                        ];
                        rozetler.value = {...rozetler.value, Bolum.bildirimler: 0};
                      },
                      child: const Text('Tümünü okundu'),
                    ),
                ],
              ),
            ),
            if (o != null && o.bekleyen > 0)
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  bolumIstegi.value = Bolum.sohbetler;
                },
                child: Container(
                  color: Marka.kehribar.withValues(alpha: .12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  child: Row(
                    children: [
                      const Icon(Simgeler.pending, size: 16, color: Marka.kehribar),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${o.bekleyen} sohbet yanıt bekliyor',
                          style: TextStyle(color: r.metin, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Simgeler.chevronRight, size: 16, color: r.silik),
                    ],
                  ),
                ),
              ),
            Flexible(
              child: l.isEmpty
                  ? const BosKucukMetin('Bildirim yok.')
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: l.length.clamp(0, 10),
                      separatorBuilder: (_, _) => Divider(height: 1, color: r.kenar.withValues(alpha: .6)),
                      itemBuilder: (_, i) {
                        final b = l[i];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            bildirimAc(b);
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(padding: const EdgeInsets.only(top: 5), child: Nokta(_renk(b, r), boyut: 9)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.baslik,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontWeight: b.okundu ? FontWeight.w500 : FontWeight.w700, fontSize: 13, color: r.metin),
                                      ),
                                      if (b.govde.isNotEmpty)
                                        Text(
                                          b.govde,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: r.soluk, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_yas(b.yasSn), style: TextStyle(color: r.silik, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: r.kenar),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    bolumIstegi.value = Bolum.bildirimler;
                  },
                  icon: const Icon(Simgeler.notifications, size: 16),
                  label: const Text('Tüm bildirimler'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    yanPanelAc(context, const BildirimAyarEkrani());
                  },
                  icon: const Icon(Simgeler.tune, size: 16),
                  label: const Text('Ayarlar'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _yas(int sn) => sn < 60
      ? 'şimdi'
      : sn < 3600
      ? '${sn ~/ 60} dk'
      : sn < 86400
      ? '${sn ~/ 3600} sa'
      : '${sn ~/ 86400} g';
}

class BosKucukMetin extends StatelessWidget {
  const BosKucukMetin(this.metin, {super.key});
  final String metin;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(
      child: Text(metin, style: TextStyle(color: context.r.silik, fontSize: 13)),
    ),
  );
}

/// Açık/koyu tema anahtarı.
/// Bildirim sesi: tek dokunuşla sessize al / aç (bu cihaza özel; Ayarlar'daki "Uygulama açıkken ses" ile aynı tercih).
class SesDugmesi extends StatelessWidget {
  const SesDugmesi({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: sesAcik,
    builder: (_, acik, _) => IconButton(
      tooltip: acik ? 'Sessize al' : 'Sessize alındı — sesi aç',
      onPressed: () {
        sesKaydet(!acik);
        bildir(acik ? 'Bildirim sesi kapatıldı' : 'Bildirim sesi açıldı', mesaj: acik ? 'Yalnız bu cihaz için; tekrar dokununca açılır.' : null, tur: MesajTur.bilgi);
      },
      icon: Icon(acik ? Simgeler.speaker : Simgeler.speakerOff, color: acik ? null : Marka.gul),
    ),
  );
}

class TemaDugmesi extends StatelessWidget {
  const TemaDugmesi({super.key});
  @override
  Widget build(BuildContext context) {
    final koyu = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: koyu ? 'Açık tema' : 'Koyu tema',
      onPressed: () => temaKaydet(koyu ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(koyu ? Simgeler.lightMode : Simgeler.darkMode),
    );
  }
}

/// Profil menüsü: ad, e-posta, rol; Profilim, Cihazlarım, Sürüm notları, Web paneli, Çıkış.
class ProfilDugmesi extends StatelessWidget {
  const ProfilDugmesi({super.key});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return ValueListenableBuilder<Temsilci?>(
      valueListenable: Uyg.ben,
      builder: (_, t, _) => t == null
          ? const SizedBox.shrink()
          : PopupMenuButton<String>(
              tooltip: t.ad,
              position: PopupMenuPosition.under,
              onSelected: (v) async {
                switch (v) {
                  case 'profil':
                    yanPanelAc(context, const ProfilEkrani());
                  case 'cihazlar':
                    bolumIstegi.value = Bolum.cihazlar;
                  case 'surum':
                    bolumIstegi.value = Bolum.surum;
                  case 'ayarlar':
                    bolumIstegi.value = Bolum.ayarlar;
                  case 'web':
                    disAc('${Uyg.api.sunucu}/admin');
                  case 'cikis':
                    if (await onayla(context, 'Oturum kapatılsın mı?', evet: 'Çıkış')) Uyg.cikis();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Row(
                    children: [
                      KisiAvatar(t.ad, url: t.avatar, boyut: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.ad,
                              style: TextStyle(fontWeight: FontWeight.w700, color: r.metin, fontSize: 13.5),
                            ),
                            Text(
                              t.eposta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: r.silik, fontSize: 11.5),
                            ),
                            Text('${t.rolAdi}${t.bolum == null ? '' : ' · ${t.bolum}'}', style: TextStyle(color: r.soluk, fontSize: 11.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'profil',
                  child: ListTile(dense: true, leading: Icon(Simgeler.userCircle), title: Text('Profilim')),
                ),
                if (Uyg.yetki('settings.manage'))
                  const PopupMenuItem(
                    value: 'cihazlar',
                    child: ListTile(dense: true, leading: Icon(Simgeler.deviceMobile), title: Text('Cihazlarım & Bildirimler')),
                  ),
                const PopupMenuItem(
                  value: 'ayarlar',
                  child: ListTile(dense: true, leading: Icon(Simgeler.settings), title: Text('Ayarlar')),
                ),
                const PopupMenuItem(
                  value: 'surum',
                  child: ListTile(dense: true, leading: Icon(Simgeler.gitBranch), title: Text('Sürüm Notları')),
                ),
                const PopupMenuItem(
                  value: 'web',
                  child: ListTile(dense: true, leading: Icon(Simgeler.openInNew), title: Text('Web paneli')),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'cikis',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Simgeler.logout, color: Marka.gul),
                    title: Text('Çıkış', style: TextStyle(color: Marka.gul)),
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    KisiAvatar(t.ad, url: t.avatar, boyut: 32),
                    Positioned(right: -1, bottom: -1, child: Nokta(musaitlikRengi(t.musaitlik), boyut: 11, halka: r.kart)),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Genel arama: sohbetler, hazır cevaplar; geçmişte ara kısayolu.
class AramaDugmesi extends StatelessWidget {
  const AramaDugmesi({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Ara (ziyaretçi, e-posta, #sohbet)',
    onPressed: () => showDialog(context: context, builder: (_) => const _AramaDiyalog()),
    icon: const Icon(Simgeler.search),
  );
}

class _AramaDiyalog extends StatefulWidget {
  const _AramaDiyalog();
  @override
  State<_AramaDiyalog> createState() => _AramaDiyalogState();
}

class _AramaDiyalogState extends State<_AramaDiyalog> {
  final _c = TextEditingController();
  Timer? _gecikme;
  List<Map<String, dynamic>> _gruplar = const [];
  bool _yukleniyor = false;

  @override
  void dispose() {
    _gecikme?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _degisti(String q) {
    _gecikme?.cancel();
    _gecikme = Timer(const Duration(milliseconds: 300), () async {
      if (q.trim().length < 2) {
        setState(() => _gruplar = const []);
        return;
      }
      setState(() => _yukleniyor = true);
      try {
        final g = await Depo.ara(q.trim());
        if (mounted) setState(() => _gruplar = g);
      } catch (_) {
      } finally {
        if (mounted) setState(() => _yukleniyor = false);
      }
    });
  }

  void _ac(Map<String, dynamic> x) {
    final url = '${x['url'] ?? ''}';
    Navigator.pop(context);
    final m = RegExp(r'open=(\d+)').firstMatch(url);
    if (m != null) {
      sohbetIstegi.value = int.tryParse(m[1]!);
    } else if (url.contains('/canned')) {
      bolumIstegi.value = Bolum.hazir;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: TextField(
                controller: _c,
                autofocus: true,
                onChanged: _degisti,
                onSubmitted: (q) {
                  if (q.trim().isEmpty) return;
                  Navigator.pop(context);
                  gecmisSorgusu.value = q.trim();
                  bolumIstegi.value = Bolum.gecmis;
                },
                decoration: InputDecoration(
                  hintText: 'Ziyaretçi adı, e-posta, #sohbet, hazır cevap…',
                  prefixIcon: const Icon(Simgeler.search, size: 18),
                  suffixIcon: _yukleniyor
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final g in _gruplar) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Text(
                        '${g['type']}'.toUpperCase(),
                        style: TextStyle(color: r.silik, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: .8),
                      ),
                    ),
                    for (final x in (g['items'] as List? ?? const []).whereType<Map>())
                      ListTile(
                        dense: true,
                        leading: Icon('${g['type']}'.startsWith('Sohbet') ? Simgeler.forum : Simgeler.chatText, size: 18, color: r.vurgu),
                        title: Text('${x['label'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${x['sub'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: r.silik, fontSize: 11.5),
                        ),
                        onTap: () => _ac(Map<String, dynamic>.from(x)),
                      ),
                  ],
                  if (_c.text.trim().length >= 2 && Uyg.yetki('chats.view'))
                    ListTile(
                      dense: true,
                      leading: Icon(Simgeler.history, size: 18, color: r.soluk),
                      title: Text('Geçmiş sohbetlerde ara: "${_c.text.trim()}"'),
                      subtitle: Text('Mesaj metni, ad, e-posta, telefon', style: TextStyle(color: r.silik, fontSize: 11.5)),
                      onTap: () {
                        Navigator.pop(context);
                        gecmisSorgusu.value = _c.text.trim();
                        bolumIstegi.value = Bolum.gecmis;
                      },
                    ),
                  if (_c.text.trim().length < 2)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Text('En az 2 karakter yazın. Enter: geçmiş sohbetlerde ara.', style: TextStyle(color: r.silik, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
