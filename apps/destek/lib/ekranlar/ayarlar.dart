import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../oturum.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import '../veri/tercihler.dart';

class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key});
  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
  bool? _pushVar;

  @override
  void initState() {
    super.initState();
    if (Push.destekli) Push.anahtar().then((t) => mounted ? setState(() => _pushVar = t != null) : null);
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
    final platform = Platform.isIOS
        ? 'iOS'
        : Platform.isMacOS
        ? 'macOS'
        : Platform.isAndroid
        ? 'Android'
        : Platform.isWindows
        ? 'Windows'
        : Platform.operatingSystem;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ValueListenableBuilder<Temsilci?>(
        valueListenable: Uyg.ben,
        builder: (_, t, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (t != null)
              Kutu(
                child: Row(
                  children: [
                    KisiAvatar(t.ad, url: t.avatar, boyut: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.ad, style: gosterim(18, renk: r.metin)),
                          Text(t.eposta, style: TextStyle(color: r.soluk, fontSize: 13)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            children: [
                              Rozet(t.rolAdi, renk: t.yonetici ? Marka.mor : Marka.mavi),
                              if (t.bolum != null) Rozet(t.bolum!, renk: Marka.lavanta),
                              if (t.totp) const Rozet('2FA', renk: Marka.zumrut, ikon: Simgeler.verifiedUser),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const Baslik('Müsaitlik'),
            Kutu(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: RadioGroup<String>(
                groupValue: t?.musaitlik,
                onChanged: (v) => v == null ? null : _musaitlik(v),
                child: Column(
                  children: [
                    for (final m in ['online', 'away', 'dnd'])
                      RadioListTile<String>(
                        value: m,
                        title: Text(musaitlikAdi(m)),
                        subtitle: Text(switch (m) {
                          'online' => 'Yeni sohbetler size yönlendirilir',
                          'away' => 'Çevrimiçi görünür, yeni sohbet almaz',
                          _ => 'Bildirim ve yeni sohbet almaz',
                        }, style: TextStyle(color: r.silik, fontSize: 12)),
                        secondary: Nokta(musaitlikRengi(m), boyut: 12),
                        dense: true,
                      ),
                  ],
                ),
              ),
            ),
            const Baslik('Görünüm ve bildirim'),
            Kutu(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: temaKipi,
                    builder: (_, kip, _) => ListTile(
                      leading: const Icon(Simgeler.palette),
                      title: const Text('Tema'),
                      trailing: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
                          ButtonSegment(value: ThemeMode.light, icon: Icon(Simgeler.lightMode, size: 16)),
                          ButtonSegment(value: ThemeMode.dark, icon: Icon(Simgeler.darkMode, size: 16)),
                        ],
                        selected: {kip},
                        onSelectionChanged: (s) => temaKaydet(s.first),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: sesAcik,
                    builder: (_, v, _) => SwitchListTile(
                      value: v,
                      onChanged: sesKaydet,
                      secondary: const Icon(Simgeler.notificationsActive),
                      title: const Text('Uygulama açıkken ses'),
                      subtitle: Text('Yeni sohbet ve ziyaretçi mesajında sistem sesi', style: TextStyle(color: r.silik, fontSize: 12)),
                    ),
                  ),
                  if (Push.destekli)
                    ListTile(
                      leading: Icon(
                        _pushVar == true ? Simgeler.notificationsActive : Simgeler.notificationsOff,
                        color: _pushVar == true ? Marka.zumrut : Marka.kehribar,
                      ),
                      title: const Text('Anlık bildirimler (APNs)'),
                      subtitle: Text(
                        _pushVar == null
                            ? 'Denetleniyor…'
                            : _pushVar!
                            ? 'Bu cihaz kayıtlı; uygulama kapalıyken de bildirim gelir.'
                            : 'İzin verilmemiş. Sistem ayarlarından bildirimi açın.',
                        style: TextStyle(color: r.silik, fontSize: 12),
                      ),
                      trailing: _pushVar == false
                          ? TextButton(
                              onPressed: () async {
                                await Push.izin();
                                final ok = await Push.kaydet(Uyg.api, yol: Uyg.pushYolu, konu: Uyg.pushKonu);
                                if (mounted) setState(() => _pushVar = ok);
                              },
                              child: const Text('Yeniden dene'),
                            )
                          : null,
                    )
                  else
                    ListTile(
                      leading: const Icon(Simgeler.notificationsNone),
                      title: const Text('Anlık bildirimler'),
                      subtitle: Text('$platform üzerinde bildirimler uygulama açıkken canlı akışla gelir.', style: TextStyle(color: r.silik, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const Baslik('Hesap'),
            Kutu(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Simgeler.openInNew),
                    title: const Text('Web paneli'),
                    subtitle: Text(Uyg.api.sunucu.replaceFirst('https://', ''), style: TextStyle(color: r.silik, fontSize: 12)),
                    onTap: () => disAc('${Uyg.api.sunucu}/admin'),
                  ),
                  ListTile(
                    leading: const Icon(Simgeler.logout, color: Marka.gul),
                    title: const Text('Çıkış yap', style: TextStyle(color: Marka.gul)),
                    subtitle: Text('Bu cihazın oturumu ve bildirim kaydı silinir', style: TextStyle(color: r.silik, fontSize: 12)),
                    onTap: () async {
                      if (await onayla(context, 'Çıkış yapılsın mı?', evet: 'Çıkış yap', tehlikeli: true)) await Uyg.cikis();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const BogaIsaret(boyut: 36, isaret: AcilisIsaret.destek),
                  const SizedBox(height: 8),
                  Text('Bogahost Destek ${Uyg.api.surum} · $platform', style: TextStyle(color: r.silik, fontSize: 12)),
                  if (Uyg.sunucuSurumu.isNotEmpty) Text('Sunucu ${Uyg.sunucuSurumu}', style: TextStyle(color: r.silik, fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
