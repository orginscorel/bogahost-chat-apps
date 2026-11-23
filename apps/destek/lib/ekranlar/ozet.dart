import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/parcalar.dart';
import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/json.dart';
import '../veri/modeller.dart';
import '../veri/panel.dart';
import 'kabuk.dart';

/// Genel Bakış — web panelindeki pano düzeni: uyarılar, eşit boyda 6 KPI, kısayollar, 7 günlük trend,
/// müşteri memnuniyeti, bekleyen kuyruğu, temsilci performansı, departman dağılımı, son sohbetler, ekip.
/// 15 sn'de bir sessizce yenilenir.
class OzetEkrani extends StatefulWidget {
  const OzetEkrani({super.key});
  @override
  State<OzetEkrani> createState() => _OzetEkraniState();
}

class _OzetEkraniState extends State<OzetEkrani> {
  Map<String, dynamic>? _v;
  List<Uye>? _ekip;
  String? _hata;
  Timer? _sayac;
  DateTime? _son;

  static const _aylar = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
  static const _gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

  @override
  void initState() {
    super.initState();
    _yukle();
    _sayac = Timer.periodic(const Duration(seconds: 15), (_) => _yukle(sessiz: true));
  }

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  Future<void> _yukle({bool sessiz = false}) async {
    try {
      final v = await Panel.pano();
      List<Uye>? e;
      try {
        e = await Depo.ekip();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _v = v;
        if (e != null) _ekip = e;
        _hata = null;
        _son = DateTime.now();
      });
    } catch (e) {
      if (mounted && !sessiz) setState(() => _hata = hataMetni(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final v = _v;
    final simdi = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genel Bakış'),
        actions: [
          IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh)),
          ...kabukEylemleri(context),
        ],
      ),
      body: _hata != null
          ? Durum.hata(_hata!, tekrar: _yukle)
          : v == null
          ? const Durum.yukleniyor()
          : RefreshIndicator(
              onRefresh: _yukle,
              child: LayoutBuilder(
                builder: (_, k) {
                  final w = k.maxWidth;
                  final genis = w >= 760;
                  final sutun3 = w >= 1120 ? 3 : (w >= 760 ? 2 : 1);
                  final s = harita(v['stats']);
                  final uyari = harita(s['offline_alert']);
                  final puanlar = haritalar(v['ratingDist']);
                  return ListView(
                    padding: EdgeInsets.fromLTRB(genis ? 20 : 16, 4, genis ? 20 : 16, 32),
                    children: [
                      SayfaBasi(
                        'Genel Bakış',
                        alt:
                            '${simdi.day} ${_aylar[simdi.month - 1]} ${simdi.year}, ${_gunler[simdi.weekday - 1]}'
                            '${_son == null ? '' : ' · güncellendi ${_son!.hour.toString().padLeft(2, '0')}:${_son!.minute.toString().padLeft(2, '0')}:${_son!.second.toString().padLeft(2, '0')}'}',
                        sag: [
                          if (Uyg.yetki('chats.view'))
                            FilledButton.icon(
                              onPressed: () => bolumIstegi.value = Bolum.sohbetler,
                              icon: const Icon(Simgeler.forum, size: 18),
                              label: const Text('Sohbetlere git'),
                            ),
                        ],
                      ),
                      _uyarilar(s, uyari, r),
                      const SizedBox(height: 14),
                      EsitIzgara(
                        enAz: 150,
                        yukseklik: 126,
                        children: [
                          KpiKart(
                            etiket: 'Şu an sitede',
                            deger: '${tamsayi(s['online'])}',
                            alt: 'çevrimiçi ziyaretçi',
                            ikon: Simgeler.visibility,
                            renk: Marka.zumrut,
                            canli: true,
                            onTap: Uyg.yetki('visitors.view') ? () => bolumIstegi.value = Bolum.ziyaretciler : null,
                          ),
                          KpiKart(
                            etiket: 'Bugünkü ziyaretçi',
                            deger: '${tamsayi(s['today_visitors'])}',
                            alt: 'tekil oturum',
                            ikon: Simgeler.peopleAlt,
                            renk: Marka.mavi,
                          ),
                          KpiKart(
                            etiket: 'Aktif sohbet',
                            deger: '${tamsayi(s['active_chats'])}',
                            alt: 'şu an açık',
                            ikon: Simgeler.forum,
                            renk: r.vurgu,
                            onTap: () => bolumIstegi.value = Bolum.sohbetler,
                          ),
                          KpiKart(
                            etiket: 'Bekleyen',
                            deger: '${tamsayi(s['pending'])}',
                            alt: tamsayi(s['pending']) > 0 ? 'yanıt bekliyor' : 'kuyruk boş',
                            ikon: Simgeler.pending,
                            renk: Marka.kehribar,
                            onTap: () => bolumIstegi.value = Bolum.sohbetler,
                          ),
                          KpiKart(etiket: 'Bugün', deger: '${tamsayi(s['today'])}', alt: 'yeni sohbet', ikon: Simgeler.today, renk: Marka.lavanta),
                          KpiKart(
                            etiket: 'Memnuniyet',
                            deger: tamsayi(s['rated']) == 0 ? '–' : ondalik(s['avg_rating']).toStringAsFixed(1),
                            alt: '${tamsayi(s['rated'])} değerlendirme',
                            ikon: Simgeler.star,
                            renk: Marka.kehribar,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EsitIzgara(
                        enAz: 150,
                        yukseklik: 58,
                        children: [
                          if (Uyg.yetki('chats.view')) _kisayol('Aktif Sohbetler', Simgeler.forum, r.vurgu, Bolum.sohbetler),
                          if (Uyg.yetki('visitors.view')) _kisayol('Canlı Ziyaretçiler', Simgeler.visibility, Marka.zumrut, Bolum.ziyaretciler),
                          if (Uyg.yetki('reports.view')) _kisayol('Raporlar', Simgeler.chartBar, Marka.mavi, Bolum.raporlar),
                          if (Uyg.yetki('chats.view')) _kisayol('Geçmiş', Simgeler.history, Marka.lavanta, Bolum.gecmis),
                          if (Uyg.yetki('canned.manage')) _kisayol('Hazır Cevaplar', Simgeler.chatText, Marka.kehribar, Bolum.hazir),
                          if (Uyg.yetki('bans.manage')) _kisayol('Yasaklılar', Simgeler.prohibit, Marka.gul, Bolum.yasaklar),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _satir(genis, [(3, _trend(haritalar(v['last7']), s, r)), (2, _memnuniyet(puanlar, ondalik(s['avg_rating']), tamsayi(s['rated']), r))]),
                      const SizedBox(height: 16),
                      _izgara(sutun3, [
                        _kuyruk(haritalar(v['queue']), r),
                        _liderler(haritalar(v['leaderboard']), r),
                        _bolumler(haritalar(v['departments']), r),
                      ]),
                      const SizedBox(height: 16),
                      _satir(genis, [(3, _sonSohbetler(haritalar(v['recent']), r)), (2, _ekipKarti(r))]),
                    ],
                  );
                },
              ),
            ),
    );
  }

  /// Geniş: oranlı yan yana; dar: alt alta.
  Widget _satir(bool genis, List<(int, Widget)> l) => genis
      ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, (f, w)) in l.indexed) ...[if (i > 0) const SizedBox(width: 16), Expanded(flex: f, child: w)],
          ],
        )
      : Column(
          children: [
            for (final (i, (_, w)) in l.indexed) ...[if (i > 0) const SizedBox(height: 16), w],
          ],
        );

  Widget _izgara(int sutun, List<Widget> l) {
    final satirlar = <List<Widget>>[];
    for (var i = 0; i < l.length; i += sutun) {
      satirlar.add(l.sublist(i, (i + sutun).clamp(0, l.length)));
    }
    return Column(
      children: [
        for (final (si, s) in satirlar.indexed) ...[
          if (si > 0) const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, w) in s.indexed) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: w)],
              for (var i = s.length; i < sutun; i++) ...[const SizedBox(width: 16), const Expanded(child: SizedBox())],
            ],
          ),
        ],
      ],
    );
  }

  // ---- Uyarılar ------------------------------------------------------------------------------------

  Widget _uyarilar(Map<String, dynamic> s, Map<String, dynamic> u, Renkler r) {
    final o = sonOzet.value;
    final ben = Uyg.ben.value?.musaitlik ?? metin(s['me_availability'], 'online');
    final l = <_Uyari>[
      if (mantik(s['attack']))
        _Uyari(
          Marka.gul,
          Simgeler.siren,
          'Saldırı modu etkin',
          'Widget kısıtlı çalışıyor; yeni ziyaretçi sohbetleri sınırlandı.',
          Uyg.yetki('settings.manage') ? () => bolumIstegi.value = Bolum.acil : null,
        ),
      if (mantik(harita(s['emergency'])['active']))
        _Uyari(
          Marka.gul,
          Simgeler.campaign,
          'Acil durum duyurusu yayında',
          'Ziyaretçiler widget içinde ${metinYa(harita(s['emergency'])['type']) ?? 'arıza'} bildirimini görüyor.',
          Uyg.yetki('settings.manage') ? () => bolumIstegi.value = Bolum.acil : null,
        ),
      if (mantik(s['after_hours']) || (o?.mesaiDisi ?? false))
        _Uyari(
          Marka.kehribar,
          Simgeler.clock,
          'Mesai saatleri dışındasınız',
          'Widget çevrimdışı modda; ziyaretçi mesajları çevrimdışı kutusuna düşer.',
          Uyg.yetki('settings.manage') ? () => bolumIstegi.value = Bolum.mesai : null,
        ),
      if (tamsayi(s['pending']) > 0)
        _Uyari(
          Marka.kehribar,
          Simgeler.pending,
          '${tamsayi(s['pending'])} sohbet yanıt bekliyor',
          'Kuyruktaki ziyaretçiler ilk yanıtı bekliyor.',
          () => bolumIstegi.value = Bolum.sohbetler,
        ),
      if (tamsayi(u['count']) > 0)
        _Uyari(
          Marka.mavi,
          Simgeler.mailOutline,
          '${tamsayi(u['count'])} çevrimdışı mesaj yanıtsız',
          'En eskisi ${yasYaz(tamsayi(u['oldest_age_s']))} önce bırakıldı.',
          () => bolumIstegi.value = Bolum.sohbetler,
        ),
      if (tamsayi(u['missed_count']) > 0)
        _Uyari(
          Marka.gul,
          Simgeler.phoneX,
          '${tamsayi(u['missed_count'])} kaçan sohbet',
          'Ziyaretçi yanıt alamadan ayrıldı; en eskisi ${yasYaz(tamsayi(u['missed_oldest_age_s']))} önce.',
          () => bolumIstegi.value = Bolum.sohbetler,
        ),
      if (ben == 'dnd')
        _Uyari(
          Marka.mor,
          Simgeler.doNotDisturbOn,
          'Rahatsız Etme modundasınız',
          'Yeni sohbet dağıtımı ve sesli bildirimler kapalı.',
          () => musaitlikDegistir('online'),
          eylem: 'Çevrimiçi ol',
        ),
      if (ben == 'offline')
        _Uyari(
          Marka.grafit,
          Simgeler.visibilityOff,
          'Çevrimdışı görünüyorsunuz',
          'Size sohbet atanmaz; ziyaretçiler sizi listede görmez.',
          () => musaitlikDegistir('online'),
          eylem: 'Çevrimiçi ol',
        ),
    ];
    if (l.isEmpty) {
      return Kutu(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        renk: Marka.zumrut.withValues(alpha: .07),
        child: Row(
          children: [
            const Icon(Simgeler.checkCircle, color: Marka.zumrut, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Her şey yolunda — bekleyen sohbet ya da yanıtsız mesaj yok.',
                style: TextStyle(color: r.metin, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return Kutu(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, x) in l.indexed) ...[
            if (i > 0) Divider(height: 1, color: r.kenar.withValues(alpha: .7)),
            InkWell(
              onTap: x.onTap,
              borderRadius: BorderRadius.vertical(top: Radius.circular(i == 0 ? 18 : 0), bottom: Radius.circular(i == l.length - 1 ? 18 : 0)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: x.renk.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
                      child: Icon(x.ikon, color: x.renk, size: 19),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            x.baslik,
                            style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 13.5),
                          ),
                          Text(x.alt, style: TextStyle(color: r.soluk, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (x.onTap != null)
                      x.eylem != null ? TextButton(onPressed: x.onTap, child: Text(x.eylem!)) : Icon(Simgeler.chevronRight, color: r.silik, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kisayol(String ad, IconData ikon, Color renk, Bolum b) => HoverKutu(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    onTap: () => bolumIstegi.value = b,
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: renk.withValues(alpha: .13), borderRadius: BorderRadius.circular(10)),
          child: Icon(ikon, color: renk, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Builder(
            builder: (c) => Text(
              ad,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.r.metin, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ],
    ),
  );

  // ---- Trend & memnuniyet ---------------------------------------------------------------------------

  Widget _trend(List<Map<String, dynamic>> l, Map<String, dynamic> s, Renkler r) {
    final toplam = l.fold<int>(0, (a, b) => a + tamsayi(b['count']));
    final bugun = l.isEmpty ? 0 : tamsayi(l.last['count']);
    final dun = l.length < 2 ? 0 : tamsayi(l[l.length - 2]['count']);
    return Kutu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KartBasi(
            'Sohbet Trendi',
            not: '· Son 7 gün',
            sag: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$toplam sohbet', style: TextStyle(color: r.soluk, fontSize: 12.5)),
                const SizedBox(width: 10),
                if (l.length >= 2)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(bugun >= dun ? Simgeler.trendingUp : Simgeler.trendingDown, size: 15, color: bugun >= dun ? Marka.zumrut : Marka.gul),
                      const SizedBox(width: 3),
                      Text(
                        '${bugun >= dun ? '+' : ''}${bugun - dun} düne göre',
                        style: TextStyle(color: bugun >= dun ? Marka.zumrut : Marka.gul, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 210,
            child: l.isEmpty
                ? const BosKucuk('Henüz veri yok.', ikon: Simgeler.showChart)
                : TrendGrafigi(degerler: [for (final x in l) tamsayi(x['count'])], etiketler: [for (final x in l) metin(x['label'])]),
          ),
        ],
      ),
    );
  }

  Widget _memnuniyet(List<Map<String, dynamic>> l, double ort, int n, Renkler r) {
    final iyi = l.where((x) => tamsayi(x['star']) >= 4).fold<int>(0, (a, b) => a + tamsayi(b['count']));
    final kotu = l.where((x) => tamsayi(x['star']) <= 2).fold<int>(0, (a, b) => a + tamsayi(b['count']));
    final enCok = l.fold<int>(1, (a, b) => tamsayi(b['count']) > a ? tamsayi(b['count']) : a);
    return Kutu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KartBasi('Müşteri Memnuniyeti', not: n == 0 ? null : '· $n oy'),
          Row(
            children: [
              MemnuniyetHalkasi(n == 0 ? 0 : ort, boyut: 124),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _oy('👍', 'Memnun', iyi, Marka.zumrut, r),
                    const SizedBox(height: 8),
                    _oy('👎', 'Memnun değil', kotu, Marka.gul, r),
                    const SizedBox(height: 8),
                    Text(
                      n == 0 ? 'Henüz değerlendirme yok.' : '${n == 0 ? 0 : (iyi * 100 / n).round()}% olumlu',
                      style: TextStyle(color: r.silik, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final x in l)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    child: Text('${tamsayi(x['star'])}★', style: TextStyle(color: r.soluk, fontSize: 12)),
                  ),
                  Expanded(
                    child: IlerlemeCubugu(
                      tamsayi(x['count']) / enCok,
                      yukseklik: 7,
                      renk: tamsayi(x['star']) >= 4
                          ? Marka.zumrut
                          : tamsayi(x['star']) == 3
                          ? Marka.kehribar
                          : Marka.gul,
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Text(' ${tamsayi(x['count'])}', style: TextStyle(color: r.silik, fontSize: 11.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _oy(String emoji, String ad, int n, Color renk, Renkler r) => Row(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(ad, style: TextStyle(color: r.soluk, fontSize: 12.5)),
      ),
      Text(
        '$n',
        style: TextStyle(color: renk, fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ],
  );

  // ---- Kuyruk / liderler / bölümler -----------------------------------------------------------------

  Widget _kuyruk(List<Map<String, dynamic>> q, Renkler r) => Kutu(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KartBasi(
          'Bekleyen Kuyruğu',
          rozet: q.isEmpty ? null : Rozet('${q.length}', renk: Marka.kehribar),
          sag: Baglanti('Tümü →', onTap: () => bolumIstegi.value = Bolum.sohbetler),
        ),
        if (q.isEmpty)
          const BosKucuk('Bekleyen sohbet yok.')
        else
          for (final (i, x) in q.take(6).indexed) ...[
            if (i > 0) Divider(height: 1, color: r.kenar.withValues(alpha: .6)),
            InkWell(
              onTap: () => sohbetIstegi.value = tamsayi(x['id']),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Avatar(metin(x['visitor'], 'Z'), boyut: 34, tohum: '${x['id']}'),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metin(x['visitor'], 'Ziyaretçi'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 13),
                          ),
                          Text(
                            metin(x['preview'], 'Mesaj yok'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: r.soluk, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          metin(x['wait']),
                          style: const TextStyle(color: Marka.kehribar, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Yanıtla →',
                          style: TextStyle(color: r.vurgu, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
      ],
    ),
  );

  Widget _liderler(List<Map<String, dynamic>> l, Renkler r) {
    final enCok = l.fold<int>(1, (a, b) => tamsayi(b['chats']) > a ? tamsayi(b['chats']) : a);
    return Kutu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KartBasi('Temsilci Performansı', not: '· bu ay'),
          if (l.isEmpty)
            const BosKucuk('Henüz veri yok.', ikon: Simgeler.usersThree)
          else
            for (final (i, x) in l.take(6).indexed)
              SiraSatiri(
                sira: i + 1,
                ad: metin(x['name']),
                oran: tamsayi(x['chats']) / enCok,
                avatar: KisiAvatar(metin(x['name']), url: metinYa(x['avatar']), boyut: 26),
                sag: '${tamsayi(x['chats'])} sohbet · ★ ${ondalik(x['avg']).toStringAsFixed(1)}',
                renk: i == 0 ? Marka.kehribar : null,
              ),
        ],
      ),
    );
  }

  Widget _bolumler(List<Map<String, dynamic>> l, Renkler r) {
    final toplam = l.fold<int>(0, (a, b) => a + tamsayi(b['count']));
    return Kutu(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KartBasi('Departman Dağılımı', not: toplam == 0 ? null : '· $toplam sohbet'),
          if (l.isEmpty)
            const BosKucuk('Departman yok.', ikon: Simgeler.accountTree)
          else
            for (final x in l)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Nokta(_renk(metin(x['color'])), boyut: 10),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            metin(x['name']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: r.metin, fontWeight: FontWeight.w500, fontSize: 13.5),
                          ),
                        ),
                        Text(
                          '${tamsayi(x['count'])}',
                          style: TextStyle(color: r.metin, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(toplam == 0 ? '' : '  %${(tamsayi(x['count']) * 100 / toplam).round()}', style: TextStyle(color: r.silik, fontSize: 11.5)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    IlerlemeCubugu(toplam == 0 ? 0 : tamsayi(x['count']) / toplam, renk: _renk(metin(x['color']))),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // ---- Son sohbetler / ekip --------------------------------------------------------------------------

  Widget _sonSohbetler(List<Map<String, dynamic>> l, Renkler r) => Kutu(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KartBasi('Son Sohbetler', sag: Baglanti('Tümü →', onTap: () => bolumIstegi.value = Bolum.sohbetler)),
        if (l.isEmpty)
          const BosKucuk('Henüz sohbet yok.', ikon: Simgeler.forum)
        else
          for (final (i, x) in l.indexed) ...[
            if (i > 0) Divider(height: 1, color: r.kenar.withValues(alpha: .6)),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Avatar(metin(x['visitor'], 'Z'), boyut: 34, tohum: '${x['id']}'),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      metin(x['visitor'], 'Ziyaretçi'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                  Rozet(_durumAd(metin(x['status'])), renk: durumRengi(metin(x['status']))),
                ],
              ),
              subtitle: Text(
                '${metin(x['preview'], '—')} · ${metin(x['time'])}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: r.silik, fontSize: 12),
              ),
              trailing: x['rating'] == null ? null : Text('★ ${x['rating']}', style: const TextStyle(color: Marka.kehribar, fontSize: 12.5)),
              onTap: () => sohbetIstegi.value = tamsayi(x['id']),
            ),
          ],
      ],
    ),
  );

  String _durumAd(String s) => switch (s) {
    'open' => 'Açık',
    'pending' => 'Bekliyor',
    'closed' => 'Kapalı',
    'offline' => 'Çevrimdışı',
    _ => s,
  };

  Widget _ekipKarti(Renkler r) {
    final e = _ekip ?? const <Uye>[];
    final online = e.where((u) => u.cevrimici).length;
    return Kutu(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KartBasi(
            'Ekip',
            rozet: e.isEmpty ? null : Rozet('$online / ${e.length} çevrimiçi', renk: online > 0 ? Marka.zumrut : Marka.grafit),
            sag: Uyg.yetki('internal.use') ? Baglanti('Ekip sohbeti →', onTap: () => bolumIstegi.value = Bolum.ekip) : null,
          ),
          if (e.isEmpty)
            const BosKucuk('Ekip bilgisi yok.', ikon: Simgeler.usersThree)
          else
            for (final (i, u) in e.indexed) ...[
              if (i > 0) Divider(height: 1, color: r.kenar.withValues(alpha: .6)),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    KisiAvatar(u.ad, url: u.avatar, boyut: 34),
                    Positioned(right: -1, bottom: -1, child: Nokta(u.cevrimici ? musaitlikRengi(u.musaitlik) : Marka.grafitAcik, boyut: 11, halka: r.kart)),
                  ],
                ),
                title: Text(u.ad, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5)),
                subtitle: Text(
                  u.cevrimici ? musaitlikAdi(u.musaitlik) : (u.sonGorulme == null ? 'Hiç görülmedi' : 'Son: ${goreliZaman(u.sonGorulme)}'),
                  style: TextStyle(color: r.silik, fontSize: 12),
                ),
                trailing: u.rol == null ? null : Rozet(u.rol!, renk: u.rol == 'super_admin' || u.rol == 'admin' ? Marka.mor : Marka.mavi),
              ),
            ],
        ],
      ),
    );
  }
}

class _Uyari {
  const _Uyari(this.renk, this.ikon, this.baslik, this.alt, this.onTap, {this.eylem});
  final Color renk;
  final IconData ikon;
  final String baslik, alt;
  final VoidCallback? onTap;
  final String? eylem;
}

Color _renk(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return Marka.mor;
  return Color(int.parse('FF$h', radix: 16));
}
