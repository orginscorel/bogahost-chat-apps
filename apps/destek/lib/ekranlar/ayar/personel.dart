import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../ortak/yardimci.dart';
import '../../oturum.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Personel: liste, ekle/düzenle/sil, rol ve bölüm, aktiflik, özel yetkiler; erişim engelleri.
class PersonelEkrani extends StatelessWidget {
  const PersonelEkrani({super.key});

  Future<void> _form(BuildContext context, Map<String, dynamic> v, VoidCallback yenile, {Map<String, dynamic>? u}) async {
    final roller = haritalar(v['roles']);
    final bolumler = haritalar(v['departments']);
    final ad = TextEditingController(text: metin(u?['name'])),
        eposta = TextEditingController(text: metin(u?['email'])),
        takma = TextEditingController(text: metin(u?['alias'])),
        parola = TextEditingController();
    int? rol = tamsayiYa(u?['role_id']) ?? (roller.isEmpty ? null : tamsayi(roller.last['id']));
    int? bolum = tamsayiYa(u?['department_id']);
    bool aktif = u == null ? true : mantik(u['is_active'], true);
    await formDiyalog(
      context,
      u == null ? 'Personel ekle' : 'Personeli düzenle',
      alanlar: [
        alan('Ad Soyad', ad),
        alan('E-posta', eposta, tur: TextInputType.emailAddress),
        alan('Takma ad', takma, ipucu: 'Ziyaretçiye görünen ad'),
        alan(u == null ? 'Parola' : 'Yeni parola (boş = değişmez)', parola, gizli: true),
        StatefulBuilder(
          builder: (_, set) => Column(
            children: [
              secim<int>('Rol', rol, [for (final x in roller) (tamsayi(x['id']), metin(x['label'], metin(x['name'])))], (x) => set(() => rol = x)),
              secim<int?>('Bölüm', bolum, [(null, 'Bölüm yok'), for (final x in bolumler) (tamsayi(x['id']), metin(x['name']))], (x) => set(() => bolum = x)),
              if (u != null) anahtar('Aktif', aktif, (x) => set(() => aktif = x), alt: 'Pasif personel giriş yapamaz'),
            ],
          ),
        ),
      ],
      kaydetF: () {
        final g = {
          'name': ad.text.trim(),
          'email': eposta.text.trim(),
          'alias': takma.text.trim(),
          'role_id': rol,
          'department_id': bolum,
          if (parola.text.isNotEmpty) 'password': parola.text,
          'is_active': aktif ? 1 : 0,
        };
        return u == null ? Panel.personelEkle(g) : Panel.personelGuncelle(tamsayi(u['id']), g);
      },
    );
    yenile();
  }

  Future<void> _yetkiler(BuildContext context, Map<String, dynamic> u, VoidCallback yenile) async {
    final v = await islem(() => Panel.yetkiler(tamsayi(u['id'])));
    if (v == null || !context.mounted) return;
    final roller = await islem(Panel.roller);
    if (roller == null || !context.mounted) return;
    final gruplar = harita(roller['groups']).map((k, x) => MapEntry(k, harita(x).map((a, b) => MapEntry(a, metin(b, a)))));
    final au = harita(v['agentUser']);
    final ozel = au['permissions'] is List;
    final secili = ozel ? metinler(au['permissions']).toSet() : metinler(harita(au['role_model'])['permissions']).toSet();
    bool rolKullan = !ozel;
    Set<String> s = secili;
    await formDiyalog(
      context,
      '${metin(u['name'])} · yetkiler',
      alanlar: [
        StatefulBuilder(
          builder: (_, set) => Column(
            children: [
              anahtar('Rolün yetkilerini kullan', rolKullan, (x) => set(() => rolKullan = x), alt: 'Kapatırsanız aşağıdaki özel liste geçerli olur'),
              if (!rolKullan) SecimListesi(gruplar: gruplar, secili: s, onChanged: (x) => s = x),
            ],
          ),
        ),
      ],
      kaydetF: () => Panel.yetkiKaydet(tamsayi(u['id']), {'use_role': rolKullan ? 1 : 0, 'permissions': s.toList()}),
    );
    yenile();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Personel',
      yukle: Panel.personel,
      govde: (context, v, yenile) {
        final l = haritalar(v['agents']);
        final roller = {for (final x in haritalar(v['roles'])) tamsayi(x['id']): metin(x['label'], metin(x['name']))};
        final bolumler = {for (final x in haritalar(v['departments'])) tamsayi(x['id']): metin(x['name'])};
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${l.length} personel', style: TextStyle(color: r.soluk, fontSize: 13)),
                ),
                FilledButton.icon(onPressed: () => _form(context, v, yenile), icon: const Icon(Simgeler.personAddAlt, size: 18), label: const Text('Ekle')),
              ],
            ),
            const SizedBox(height: 10),
            for (final u in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Kutu(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          KisiAvatar(metin(u['alias'] ?? u['name'], metin(u['name'])), url: metinYa(u['avatar']), boyut: 42),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Nokta(
                              mantik(u['is_active'], true) ? musaitlikRengi(metin(u['availability'], 'offline')) : Marka.gul,
                              boyut: 11,
                              halka: r.kart,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metin(u['name']),
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                            ),
                            Text(
                              metin(u['email']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: r.silik, fontSize: 12),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                Rozet(roller[tamsayiYa(u['role_id'])] ?? metin(u['role']), renk: metin(u['role']).contains('admin') ? Marka.mor : Marka.mavi),
                                if (bolumler[tamsayiYa(u['department_id'])] != null) Rozet(bolumler[tamsayiYa(u['department_id'])]!, renk: Marka.lavanta),
                                if (u['permissions'] is List) const Rozet('Özel yetki', renk: Marka.kehribar, ikon: Simgeler.tune),
                                if (!mantik(u['is_active'], true)) const Rozet('Pasif', renk: Marka.gul),
                                if (u['totp_enabled_at'] != null) const Rozet('2FA', renk: Marka.zumrut, ikon: Simgeler.verifiedUser),
                                if (metinYa(u['whmcs_role_name']) != null) Rozet('WHMCS', renk: const Color(0xFF64748B)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (x) async {
                          switch (x) {
                            case 'duzenle':
                              await _form(context, v, yenile, u: u);
                            case 'yetki':
                              await _yetkiler(context, u, yenile);
                            case 'sil':
                              if (tamsayi(u['id']) == Uyg.ben.value?.id) {
                                bildir('Kendi hesabınızı silemezsiniz', tur: MesajTur.uyari);
                                return;
                              }
                              if (await onayla(
                                context,
                                '${metin(u['name'])} silinsin mi?',
                                mesaj: 'Sohbet geçmişi kalır; hesap giriş yapamaz.',
                                evet: 'Sil',
                                tehlikeli: true,
                              )) {
                                if (await kaydet(() => Panel.personelSil(tamsayi(u['id'])))) yenile();
                              }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'duzenle',
                            child: ListTile(dense: true, leading: Icon(Simgeler.edit), title: Text('Düzenle')),
                          ),
                          PopupMenuItem(
                            value: 'yetki',
                            child: ListTile(dense: true, leading: Icon(Simgeler.lockKey), title: Text('Yetkiler')),
                          ),
                          PopupMenuItem(
                            value: 'sil',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Simgeler.deleteOutline, color: Marka.gul),
                              title: Text('Sil', style: TextStyle(color: Marka.gul)),
                            ),
                          ),
                        ],
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

/// Roller: etiket + yetki seti; sistem rolleri silinemez.
class RollerEkrani extends StatelessWidget {
  const RollerEkrani({super.key});

  Future<void> _form(BuildContext context, Map<String, dynamic> v, VoidCallback yenile, {Map<String, dynamic>? rol}) async {
    final gruplar = harita(v['groups']).map((k, x) => MapEntry(k, harita(x).map((a, b) => MapEntry(a, metin(b, a)))));
    final etiket = TextEditingController(text: metin(rol?['label']));
    Set<String> s = metinler(rol?['permissions']).toSet();
    await formDiyalog(
      context,
      rol == null ? 'Rol ekle' : 'Rolü düzenle',
      alanlar: [
        alan('Rol adı', etiket),
        SecimListesi(gruplar: gruplar, secili: s, onChanged: (x) => s = x),
      ],
      kaydetF: () {
        final g = {'label': etiket.text.trim(), 'permissions': s.toList()};
        return rol == null ? Panel.rolEkle(g) : Panel.rolGuncelle(tamsayi(rol['id']), g);
      },
    );
    yenile();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Roller ve yetkiler',
      yukle: Panel.roller,
      govde: (context, v, yenile) {
        final l = haritalar(v['roles']);
        final toplamYetki = harita(v['groups']).values.fold<int>(0, (a, b) => a + harita(b).length);
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${l.length} rol · $toplamYetki yetki', style: TextStyle(color: r.soluk, fontSize: 13)),
                ),
                FilledButton.icon(onPressed: () => _form(context, v, yenile), icon: const Icon(Simgeler.add, size: 18), label: const Text('Rol ekle')),
              ],
            ),
            const SizedBox(height: 10),
            for (final x in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Kutu(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  onTap: () => _form(context, v, yenile, rol: x),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (mantik(x['is_system']) ? Marka.mor : Marka.mavi).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          metin(x['name']) == 'super_admin' ? Simgeler.crown : Simgeler.shieldCheck,
                          color: mantik(x['is_system']) ? Marka.mor : Marka.mavi,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metin(x['label'], metin(x['name'])),
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                            ),
                            Text(
                              '${metin(x['name'])} · ${metinler(x['permissions']).length} yetki · ${tamsayi(x['users_count'])} kişi',
                              style: TextStyle(color: r.silik, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (mantik(x['is_system']))
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Rozet('Sistem', renk: Color(0xFF64748B)),
                        )
                      else
                        IconButton(
                          icon: const Icon(Simgeler.deleteOutline, color: Marka.gul, size: 20),
                          onPressed: () async {
                            if (await onayla(
                              context,
                              'Rol silinsin mi?',
                              mesaj: 'Bu roldeki kullanıcılar varsa silme reddedilir.',
                              evet: 'Sil',
                              tehlikeli: true,
                            )) {
                              if (await kaydet(() => Panel.rolSil(tamsayi(x['id'])))) yenile();
                            }
                          },
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

/// Bölümler (departmanlar): ad, renk, otomatik yanıt, çevrimdışı mesaj, aktiflik.
class BolumlerEkrani extends StatelessWidget {
  const BolumlerEkrani({super.key});

  Future<void> _form(BuildContext context, VoidCallback yenile, {Map<String, dynamic>? b}) async {
    final ad = TextEditingController(text: metin(b?['name'])),
        renk = TextEditingController(text: metin(b?['color'], '#5443d2')),
        oto = TextEditingController(text: metin(b?['auto_reply'])),
        cd = TextEditingController(text: metin(b?['offline_message']));
    bool aktif = b == null ? true : mantik(b['is_active'], true);
    await formDiyalog(
      context,
      b == null ? 'Bölüm ekle' : 'Bölümü düzenle',
      alanlar: [
        alan('Ad', ad),
        alan('Renk (hex)', renk),
        alan('Otomatik yanıt', oto, satir: 2, alt: 'Sohbet bu bölüme düşünce gönderilir'),
        alan('Çevrimdışı mesajı', cd, satir: 2),
        StatefulBuilder(builder: (_, set) => anahtar('Aktif', aktif, (x) => set(() => aktif = x))),
      ],
      kaydetF: () {
        final g = {
          'name': ad.text.trim(),
          'color': renk.text.trim(),
          'auto_reply': oto.text.trim(),
          'offline_message': cd.text.trim(),
          'is_active': aktif ? 1 : 0,
        };
        return b == null ? Panel.bolumEkle(g) : Panel.bolumGuncelle(tamsayi(b['id']), g);
      },
    );
    yenile();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Bölümler',
      yukle: Panel.bolumler,
      govde: (context, v, yenile) {
        final l = haritalar(v['departments']);
        return ListView(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(onPressed: () => _form(context, yenile), icon: const Icon(Simgeler.add, size: 18), label: const Text('Bölüm ekle')),
            ),
            const SizedBox(height: 10),
            if (l.isEmpty) Durum.bos('Bölüm yok.', ikon: Simgeler.accountTree),
            for (final x in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Kutu(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  onTap: () => _form(context, yenile, b: x),
                  child: Row(
                    children: [
                      Nokta(_renk(metin(x['color'])), boyut: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metin(x['name']),
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                            ),
                            Text(
                              '${tamsayi(x['conversations_count'])} sohbet${mantik(x['is_active'], true) ? '' : ' · pasif'}',
                              style: TextStyle(color: r.silik, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Simgeler.deleteOutline, color: Marka.gul, size: 20),
                        onPressed: () async {
                          if (await onayla(context, '${metin(x['name'])} silinsin mi?', evet: 'Sil', tehlikeli: true)) {
                            if (await kaydet(() => Panel.bolumSil(tamsayi(x['id'])))) yenile();
                          }
                        },
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

Color _renk(String hex) {
  final h = hex.replaceFirst('#', '');
  return h.length == 6 ? Color(int.tryParse('FF$h', radix: 16) ?? 0xFF5443D2) : Marka.mor;
}
