import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/json.dart';
import '../veri/modeller.dart';
import '../veri/panel.dart';
import 'kabuk.dart';

/// Pano — web panelindeki gösterge tablosunun karşılığı: anlık sayılar, son 7 gün, sıra, son sohbetler,
/// personel sıralaması, bölüm yükü, puan dağılımı ve çevrimdışı/kaçan uyarısı. 15 sn'de bir yenilenir.
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
      final e = await Depo.ekip();
      if (!mounted) return;
      setState(() {
        _v = v;
        _ekip = e;
        _hata = null;
      });
    } catch (e) {
      if (mounted && !sessiz) setState(() => _hata = hataMetni(e));
    }
  }

  Future<void> _musaitlik(String m) async {
    final v = await islem(() => Depo.musaitlik(m));
    if (v == null) return;
    final t = Uyg.ben.value!;
    Uyg.ben.value = Temsilci.coz({
      'id': t.id,
      'display_name': t.ad,
      'email': t.eposta,
      'role': t.rol,
      'role_name': t.rolAdi,
      'permissions': t.yetkiler,
      'is_admin': t.yonetici,
      'availability': v,
      'avatar': t.avatar,
      'department': t.bolum,
      'totp_enabled': t.totp,
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final v = _v;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pano'),
        actions: [IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh))],
      ),
      body: _hata != null
          ? Durum.hata(_hata!, tekrar: _yukle)
          : v == null
          ? const Durum.yukleniyor()
          : RefreshIndicator(
              onRefresh: _yukle,
              child: LayoutBuilder(
                builder: (_, k) {
                  final genis = k.maxWidth >= 760;
                  final s = harita(v['stats']);
                  final uyari = harita(s['offline_alert']);
                  final sol = <Widget>[
                    _sayilar(s, r),
                    if (tamsayi(uyari['count']) > 0 || tamsayi(uyari['missed_count']) > 0) _uyariKarti(uyari, r),
                    const Baslik('Son 7 gün'),
                    Kutu(child: SizedBox(height: 150, child: _Cubuklar(haritalar(v['last7']), r))),
                    if (haritalar(v['queue']).isNotEmpty) ...[const Baslik('Sırada bekleyenler'), _sira(haritalar(v['queue']), r)],
                    const Baslik('Son sohbetler'),
                    _sonSohbetler(haritalar(v['recent']), r),
                  ];
                  final sag = <Widget>[
                    ValueListenableBuilder<Temsilci?>(valueListenable: Uyg.ben, builder: (_, t, _) => t == null ? const SizedBox.shrink() : _benKarti(t, r)),
                    const Baslik('Personel sıralaması'),
                    _liderler(haritalar(v['leaderboard']), r),
                    const Baslik('Bölüm yükü'),
                    _bolumler(haritalar(v['departments']), r),
                    const Baslik('Puan dağılımı'),
                    _puanlar(haritalar(v['ratingDist']), ondalik(s['avg_rating']), tamsayi(s['rated']), r),
                    const Baslik('Ekip'),
                    _ekipKarti(r),
                  ];
                  if (!genis) {
                    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [...sol, ...sag]);
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sol),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 2,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sag),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _sayilar(Map<String, dynamic> s, Renkler r) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _kart('Aktif sohbet', '${tamsayi(s['active_chats'])}', Simgeler.forum, Marka.zumrut, r, onTap: () => bolumIstegi.value = Bolum.sohbetler),
        _kart('Bekleyen', '${tamsayi(s['pending'])}', Simgeler.pending, Marka.kehribar, r, onTap: () => bolumIstegi.value = Bolum.sohbetler),
        _kart('Çevrimiçi ziyaretçi', '${tamsayi(s['online'])}', Simgeler.visibility, Marka.mavi, r, onTap: () => bolumIstegi.value = Bolum.ziyaretciler),
        _kart('Bugün ziyaretçi', '${tamsayi(s['today_visitors'])}', Simgeler.peopleAlt, Marka.lavanta, r),
        _kart('Bugün sohbet', '${tamsayi(s['today'])}', Simgeler.today, Marka.mor, r),
        _kart('Çevrimdışı mesaj', '${tamsayi(s['offline_msgs'])}', Simgeler.mailOutline, const Color(0xFF64748B), r),
        _kart(
          'Ortalama puan',
          tamsayi(s['rated']) == 0 ? '–' : ondalik(s['avg_rating']).toStringAsFixed(1),
          Simgeler.star,
          Marka.kehribar,
          r,
          alt: '${tamsayi(s['rated'])} değerlendirme',
        ),
        _kart('Toplam sohbet', '${tamsayi(s['total'])}', Simgeler.history, const Color(0xFF0891B2), r),
      ],
    ),
  );

  Widget _uyariKarti(Map<String, dynamic> u, Renkler r) {
    String yas(int sn) => sn >= 86400
        ? '${sn ~/ 86400} gün'
        : sn >= 3600
        ? '${sn ~/ 3600} sa'
        : '${sn ~/ 60} dk';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Kutu(
        renk: Marka.kehribar.withValues(alpha: .08),
        onTap: () => bolumIstegi.value = Bolum.sohbetler,
        child: Row(
          children: [
            const Icon(Simgeler.warningAmber, color: Marka.kehribar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yanıt bekleyen mesajlar',
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                  ),
                  Text(
                    '${tamsayi(u['count'])} çevrimdışı mesaj (en eski ${yas(tamsayi(u['oldest_age_s']))}) · ${tamsayi(u['missed_count'])} kaçan sohbet (en eski ${yas(tamsayi(u['missed_oldest_age_s']))})',
                    style: TextStyle(color: r.soluk, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            Icon(Simgeler.chevronRight, color: r.silik),
          ],
        ),
      ),
    );
  }

  Widget _sira(List<Map<String, dynamic>> q, Renkler r) => Kutu(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (i, x) in q.indexed) ...[
          if (i > 0) const Divider(height: 1),
          ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: Marka.kehribar.withValues(alpha: .15),
              child: Text(
                '${i + 1}',
                style: const TextStyle(color: Marka.kehribar, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            title: Text(metin(x['visitor'], 'Ziyaretçi')),
            subtitle: Text(metin(x['wait'] ?? x['time'] ?? x['since']), style: TextStyle(color: r.silik, fontSize: 12)),
            trailing: const Icon(Simgeler.chevronRight),
            onTap: () => sohbetIstegi.value = tamsayi(x['id']),
          ),
        ],
      ],
    ),
  );

  Widget _sonSohbetler(List<Map<String, dynamic>> l, Renkler r) => l.isEmpty
      ? Kutu(
          child: Text('Henüz sohbet yok.', style: TextStyle(color: r.silik)),
        )
      : Kutu(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, x) in l.indexed) ...[
                if (i > 0) const Divider(height: 1),
                ListTile(
                  dense: true,
                  leading: Avatar(metin(x['visitor'], 'Z'), boyut: 34, tohum: '${x['id']}'),
                  title: Row(
                    children: [
                      Expanded(child: Text(metin(x['visitor'], 'Ziyaretçi'), maxLines: 1, overflow: TextOverflow.ellipsis)),
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

  Widget _liderler(List<Map<String, dynamic>> l, Renkler r) => Kutu(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: l.isEmpty
        ? Text('Veri yok.', style: TextStyle(color: r.silik))
        : Column(
            children: [
              for (final (i, x) in l.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${i + 1}.',
                          style: TextStyle(color: i == 0 ? Marka.kehribar : r.silik, fontWeight: FontWeight.w700),
                        ),
                      ),
                      KisiAvatar(metin(x['name']), url: metinYa(x['avatar']), boyut: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          metin(x['name']),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: r.metin, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text('${tamsayi(x['chats'])} sohbet', style: TextStyle(color: r.soluk, fontSize: 12.5)),
                      const SizedBox(width: 10),
                      Text(
                        '★ ${ondalik(x['avg']).toStringAsFixed(1)}',
                        style: const TextStyle(color: Marka.kehribar, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );

  Widget _bolumler(List<Map<String, dynamic>> l, Renkler r) {
    final toplam = l.fold<int>(0, (a, b) => a + tamsayi(b['count']));
    return Kutu(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: l.isEmpty
          ? Text('Bölüm yok.', style: TextStyle(color: r.silik))
          : Column(
              children: [
                for (final x in l)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
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
                                style: TextStyle(color: r.metin, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text('${tamsayi(x['count'])}', style: TextStyle(color: r.soluk, fontSize: 12.5)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: toplam == 0 ? 0 : tamsayi(x['count']) / toplam,
                            minHeight: 6,
                            color: _renk(metin(x['color'])),
                            backgroundColor: r.kenar,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _puanlar(List<Map<String, dynamic>> l, double ort, int n, Renkler r) {
    final enCok = l.fold<int>(1, (a, b) => tamsayi(b['count']) > a ? tamsayi(b['count']) : a);
    return Kutu(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Column(
            children: [
              Text(n == 0 ? '–' : ort.toStringAsFixed(1), style: gosterim(34, renk: r.metin)),
              Text('$n oy', style: TextStyle(color: r.silik, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: tamsayi(x['count']) / enCok,
                              minHeight: 7,
                              color: tamsayi(x['star']) >= 4
                                  ? Marka.zumrut
                                  : tamsayi(x['star']) == 3
                                  ? Marka.kehribar
                                  : Marka.gul,
                              backgroundColor: r.kenar,
                            ),
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
          ),
        ],
      ),
    );
  }

  Widget _ekipKarti(Renkler r) {
    final e = _ekip;
    if (e == null) return const SizedBox.shrink();
    return Kutu(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, u) in e.indexed) ...[
            if (i > 0) const Divider(height: 1),
            ListTile(
              dense: true,
              leading: Stack(
                children: [
                  KisiAvatar(u.ad, url: u.avatar, boyut: 34),
                  Positioned(right: 0, bottom: 0, child: Nokta(u.cevrimici ? musaitlikRengi(u.musaitlik) : const Color(0xFF94A3B8), boyut: 10, halka: r.kart)),
                ],
              ),
              title: Text(u.ad, style: const TextStyle(fontWeight: FontWeight.w500)),
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

  Widget _benKarti(Temsilci t, Renkler r) => Kutu(
    child: Row(
      children: [
        Stack(
          children: [
            KisiAvatar(t.ad, url: t.avatar, boyut: 52),
            Positioned(right: 0, bottom: 0, child: Nokta(musaitlikRengi(t.musaitlik), boyut: 14, halka: r.kart)),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.ad, style: gosterim(18, renk: r.metin)),
              Text('${t.rolAdi}${t.bolum == null ? '' : ' · ${t.bolum}'}', style: TextStyle(color: r.silik, fontSize: 12.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final m in ['online', 'away', 'dnd', 'offline'])
                    ChoiceChip(
                      label: Text(musaitlikAdi(m)),
                      selected: t.musaitlik == m,
                      avatar: Nokta(musaitlikRengi(m)),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => _musaitlik(m),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _kart(String ad, String deger, IconData ikon, Color renk, Renkler r, {String? alt, VoidCallback? onTap}) => SizedBox(
    width: 160,
    child: Kutu(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: renk.withValues(alpha: .13), borderRadius: BorderRadius.circular(10)),
                child: Icon(ikon, color: renk, size: 18),
              ),
              const Spacer(),
              Text(deger, style: gosterim(24, renk: r.metin)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ad,
            style: TextStyle(color: r.soluk, fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
          if (alt != null) Text(alt, style: TextStyle(color: r.silik, fontSize: 11)),
        ],
      ),
    ),
  );
}

Color _renk(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return Marka.mor;
  return Color(int.parse('FF$h', radix: 16));
}

/// Son 7 gün sohbet sayısı — basit çubuk grafik.
class _Cubuklar extends StatelessWidget {
  const _Cubuklar(this.l, this.r);
  final List<Map<String, dynamic>> l;
  final Renkler r;
  @override
  Widget build(BuildContext context) {
    final enCok = l.fold<int>(1, (a, b) => tamsayi(b['count']) > a ? tamsayi(b['count']) : a);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, x) in l.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${tamsayi(x['count'])}',
                    style: TextStyle(color: r.soluk, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: tamsayi(x['count']) / enCok),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Container(
                      height: 8 + 86 * v,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [i == l.length - 1 ? Marka.yesil : Marka.morAcik, i == l.length - 1 ? Marka.yesilKoyu : Marka.mor],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(metin(x['label']), style: TextStyle(color: r.silik, fontSize: 11)),
                  Text(metin(x['date']), style: TextStyle(color: r.silik, fontSize: 9.5)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
