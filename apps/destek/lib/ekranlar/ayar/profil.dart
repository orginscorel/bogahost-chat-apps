import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../ortak/simgeler.dart';
import '../../ortak/yardimci.dart';
import '../../oturum.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Hesap: ad, takma ad, e-posta, parola, avatar; yetki listesi; iki adımlı doğrulama.
class ProfilEkrani extends StatefulWidget {
  const ProfilEkrani({super.key});
  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  final _ad = TextEditingController(),
      _takma = TextEditingController(),
      _eposta = TextEditingController(),
      _p1 = TextEditingController(),
      _p2 = TextEditingController();
  bool _dolduruldu = false, _mesgul = false;

  Future<Map<String, dynamic>> _yukle() async {
    final v = await Panel.profil();
    if (!_dolduruldu) {
      final u = harita(v['user']);
      _ad.text = metin(u['name']);
      _takma.text = metin(u['alias']);
      _eposta.text = metin(u['email']);
      _dolduruldu = true;
    }
    return v;
  }

  Future<void> _kaydet(VoidCallback yenile) async {
    if (_p1.text.isNotEmpty && _p1.text != _p2.text) {
      bildir('Parolalar eşleşmiyor', tur: MesajTur.hata);
      return;
    }
    setState(() => _mesgul = true);
    final ok = await kaydet(
      () => Panel.profilKaydet({
        'name': _ad.text.trim(),
        'alias': _takma.text.trim(),
        'email': _eposta.text.trim(),
        if (_p1.text.isNotEmpty) 'password': _p1.text,
        if (_p1.text.isNotEmpty) 'password_confirmation': _p2.text,
      }),
    );
    if (mounted) setState(() => _mesgul = false);
    if (ok) {
      _p1.clear();
      _p2.clear();
      await Uyg.yukle();
      yenile();
    }
  }

  Future<void> _avatar(VoidCallback yenile) async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (x == null) return;
    if (await kaydet(() => Panel.avatarYukle(File(x.path)), tamam: 'Avatar güncellendi')) {
      await Uyg.yukle();
      yenile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Hesabım',
      yukle: _yukle,
      altBar: KaydetSeridi(mesgul: _mesgul, onKaydet: () => _kaydet(() => setState(() => _dolduruldu = false))),
      govde: (context, v, yenile) {
        final u = harita(v['user']);
        final yetkiler = metinler(v['permissions']);
        final katalog = harita(v['catalog']);
        return ListView(
          children: [
            Kutu(
              child: Row(
                children: [
                  Stack(
                    children: [
                      KisiAvatar(metin(u['display_name'], metin(u['name'])), url: metinYa(u['avatar']), boyut: 72),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: Marka.mor,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _avatar(yenile),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Simgeler.photoCamera, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(metin(u['display_name'], metin(u['name'])), style: gosterim(18, renk: r.metin)),
                        Text(metin(u['email']), style: TextStyle(color: r.soluk, fontSize: 13)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Rozet(metin(u['role_name'], metin(u['role'])), renk: mantik(u['is_admin']) ? Marka.mor : Marka.mavi),
                            if (metinYa(u['department']) != null) Rozet(metin(u['department']), renk: Marka.lavanta),
                            if (metinYa(v['whmcs_role']) != null) Rozet('WHMCS · ${metin(v['whmcs_role'])}', renk: Marka.zumrut),
                          ],
                        ),
                        if (metinYa(u['avatar']) != null)
                          TextButton(
                            onPressed: () async {
                              if (await kaydet(Panel.avatarSil, tamam: 'Avatar kaldırıldı')) {
                                await Uyg.yukle();
                                yenile();
                              }
                            },
                            child: const Text('Avatarı kaldır'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Baslik('Kimlik'),
            Kutu(
              child: Column(
                children: [
                  alan('Ad Soyad', _ad),
                  alan('Takma ad', _takma, ipucu: 'Ziyaretçiye görünen ad (boşsa tam ad)'),
                  alan('E-posta', _eposta, tur: TextInputType.emailAddress),
                ],
              ),
            ),
            const Baslik('Parola değiştir'),
            Kutu(
              child: Column(
                children: [
                  alan('Yeni parola', _p1, gizli: true, ipucu: 'En az 6 karakter; boş bırakılırsa değişmez'),
                  alan('Yeni parola (tekrar)', _p2, gizli: true),
                ],
              ),
            ),
            Baslik(
              'İki adımlı doğrulama',
              sag: Rozet(
                mantik(u['totp_enabled']) ? 'Açık' : 'Kapalı',
                renk: mantik(u['totp_enabled']) ? Marka.zumrut : Marka.kehribar,
                ikon: Simgeler.verifiedUser,
              ),
            ),
            Kutu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mantik(u['totp_enabled'])
                        ? 'Girişte parolaya ek olarak doğrulama uygulamasından 6 haneli kod istenir. Kapatmak için güncel kodu girin.'
                        : 'Google Authenticator, Authy veya 1Password gibi bir uygulamayla hesabınızı koruyun.',
                    style: TextStyle(color: r.soluk, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: mantik(u['totp_enabled'])
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              final kod = await metinSor(context, '2FA kapat', ipucu: '6 haneli kod', tamam: 'Kapat');
                              if (kod == null || kod.trim().isEmpty) return;
                              if (await kaydet(() => Panel.ikiAdimKapat(kod.trim()))) {
                                await Uyg.yukle();
                                yenile();
                              }
                            },
                            icon: const Icon(Simgeler.keyOff, size: 18),
                            label: const Text('Kapat'),
                          )
                        : FilledButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(HizliRota(builder: (_) => const IkiAdimKurulum()));
                              await Uyg.yukle();
                              yenile();
                            },
                            icon: const Icon(Simgeler.qrCode2, size: 18),
                            label: const Text('Kur'),
                          ),
                  ),
                ],
              ),
            ),
            const Baslik('Yetkilerim'),
            Kutu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mantik(v['custom_permissions']))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Bu hesaba role ek özel yetkiler tanımlı.', style: TextStyle(color: Marka.kehribar, fontSize: 12.5)),
                    ),
                  for (final g in katalog.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
                      child: Text(
                        metin(harita(g.value)['label'], g.key),
                        style: TextStyle(fontWeight: FontWeight.w600, color: r.soluk, fontSize: 12.5),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final a in harita(harita(g.value)['actions']).entries)
                          Rozet(
                            a.value is List ? metin((a.value as List).first) : metin(a.value),
                            renk: yetkiler.contains(a.key) ? Marka.zumrut : const Color(0xFF94A3B8),
                            ikon: yetkiler.contains(a.key) ? Simgeler.check : Simgeler.close,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Baslik('Bilgi'),
            Kutu(
              child: Column(
                children: [
                  bilgi(context, 'Kullanıcı no', '#${tamsayi(u['id'])}'),
                  bilgi(context, 'WHMCS yönetici', v['whmcs_admin_id'] == null ? null : '#${v['whmcs_admin_id']}'),
                  bilgi(context, 'Son görülme', tamZaman(tarihOku(v['last_seen_at']))),
                  bilgi(context, 'Kayıt', tamZaman(tarihOku(v['created_at']))),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 2FA kurulum: gizli anahtar + otpauth bağlantısı (kopyala / uygulamada aç) → kod doğrula.
class IkiAdimKurulum extends StatefulWidget {
  const IkiAdimKurulum({super.key});
  @override
  State<IkiAdimKurulum> createState() => _IkiAdimKurulumState();
}

class _IkiAdimKurulumState extends State<IkiAdimKurulum> {
  final _kod = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'İki adımlı doğrulama',
      yukle: Panel.ikiAdim,
      govde: (context, v, yenile) {
        final gizli = metin(v['secret']);
        final uri = metin(v['otpauth']);
        final grup = gizli.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m[0]} ').trim();
        return ListView(
          children: [
            Kutu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Doğrulama uygulamasına ekleyin',
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bu cihazda doğrulama uygulaması varsa bağlantıyla doğrudan ekleyin; yoksa anahtarı elle girin.',
                    style: TextStyle(color: r.soluk, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(grup, style: const TextStyle(fontFamily: 'monospace', fontSize: 17, letterSpacing: 1.2)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => kopyala(gizli, mesaj: 'Anahtar kopyalandı'),
                        icon: const Icon(Simgeler.copy, size: 16),
                        label: const Text('Anahtarı kopyala'),
                      ),
                      FilledButton.tonalIcon(onPressed: () => disAc(uri), icon: const Icon(Simgeler.openInNew, size: 16), label: const Text('Uygulamada aç')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Kutu(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. Üretilen kodu girin',
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _kod,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(labelText: '6 haneli kod', counterText: ''),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () async {
                        if (await kaydet(() => Panel.ikiAdimAc(gizli, _kod.text.trim()))) {
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Doğrula ve aç'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
