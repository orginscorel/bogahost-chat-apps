import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'kabuk.dart';

/// Pano: anlık sayılar + hızlı müsaitlik + ekip durumu.
class OzetEkrani extends StatefulWidget {
  const OzetEkrani({super.key});
  @override
  State<OzetEkrani> createState() => _OzetEkraniState();
}

class _OzetEkraniState extends State<OzetEkrani> {
  List<Uye>? _ekip;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    try {
      final e = await Depo.ekip();
      if (!mounted) return;
      setState(() {
        _ekip = e;
        _hata = null;
      });
    } catch (e) {
      if (mounted) setState(() => _hata = hataMetni(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Özet'),
        actions: [IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh))],
      ),
      body: RefreshIndicator(
        onRefresh: _yukle,
        child: ValueListenableBuilder<Ozet?>(
          valueListenable: sonOzet,
          builder: (_, o, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              ValueListenableBuilder<Temsilci?>(valueListenable: Uyg.ben, builder: (_, t, _) => t == null ? const SizedBox.shrink() : _benKarti(t, r)),
              const SizedBox(height: 14),
              if (o == null)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _kart('Aktif sohbet', '${o.aktif}', Simgeler.forum, Marka.zumrut, r),
                    _kart('Bekleyen', '${o.bekleyen}', Simgeler.pending, Marka.kehribar, r),
                    _kart('Çevrimiçi ziyaretçi', '${o.cevrimici}', Simgeler.visibility, Marka.mavi, r),
                    _kart('Bugün ziyaretçi', '${o.bugunZiyaretci}', Simgeler.peopleAlt, Marka.lavanta, r),
                    _kart('Bugün sohbet', '${o.bugun}', Simgeler.today, Marka.mor, r),
                    _kart('Çevrimdışı mesaj', '${o.cevrimdisiMesaj}', Simgeler.mailOutline, const Color(0xFF64748B), r),
                    _kart(
                      'Ortalama puan',
                      o.puanlanan == 0 ? '–' : o.ortPuan.toStringAsFixed(1),
                      Simgeler.star,
                      Marka.kehribar,
                      r,
                      alt: '${o.puanlanan} değerlendirme',
                    ),
                    _kart('Toplam sohbet', '${o.toplam}', Simgeler.history, const Color(0xFF0891B2), r),
                  ],
                ),
                if (o.mesaiDisi) ...[
                  const SizedBox(height: 14),
                  Kutu(
                    renk: Marka.kehribar.withValues(alpha: .08),
                    child: Row(
                      children: [
                        const Icon(Simgeler.schedule, color: Marka.kehribar),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mesai dışı: widget çevrimdışı formu gösteriyor, gelen mesajlar "Çevrimdışı" listesine düşer.',
                            style: TextStyle(color: r.soluk, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const Baslik('Ekip'),
              if (_hata != null)
                Durum.hata(_hata!, tekrar: _yukle)
              else if (_ekip == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else
                Kutu(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, u) in _ekip!.indexed) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          leading: Stack(
                            children: [
                              KisiAvatar(u.ad, url: u.avatar, boyut: 38),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Nokta(u.cevrimici ? musaitlikRengi(u.musaitlik) : const Color(0xFF94A3B8), boyut: 11, halka: r.kart),
                              ),
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
                ),
            ],
          ),
        ),
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
                children: [
                  for (final m in ['online', 'away', 'dnd'])
                    ChoiceChip(label: Text(musaitlikAdi(m)), selected: t.musaitlik == m, avatar: Nokta(musaitlikRengi(m)), onSelected: (_) => _musaitlik(m)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

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

  Widget _kart(String ad, String deger, IconData ikon, Color renk, Renkler r, {String? alt}) => SizedBox(
    width: 168,
    child: Kutu(
      padding: const EdgeInsets.all(14),
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
