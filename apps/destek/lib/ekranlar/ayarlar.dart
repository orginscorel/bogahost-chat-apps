import 'dart:io';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

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
import 'ayar/musaitlik.dart';
import 'ayar/personel.dart';
import 'ayar/profil.dart';
import 'ayar/raporlar.dart';
import 'ayar/surum.dart';
import 'ayar/tetikleyiciler.dart';
import 'ayar/whatsapp.dart';
import 'ayar/widget_ayar.dart';
import 'ayar/yasaklar.dart';
import 'kabuk.dart';

/// Ayarlar merkezi: profil kartı, hızlı müsaitlik, bölümlere giden kartlar (yetkiye göre), tema, çıkış.
class AyarlarEkrani extends StatefulWidget {
  const AyarlarEkrani({super.key});
  @override
  State<AyarlarEkrani> createState() => _AyarlarEkraniState();
}

class _AyarlarEkraniState extends State<AyarlarEkrani> {
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

  void _git(Widget w) => yanPanelAc(context, w);

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
    final yonetim = <_Oge>[
      if (Uyg.yetki('settings.manage'))
        _Oge('Mesai saatleri', 'Çalışma günleri, tatiller, çevrimdışı metinleri', Simgeler.clock, Marka.indigo, () => _git(const MesaiEkrani())),
      if (Uyg.yetki('widget.manage'))
        _Oge('Widget', 'Görünüm, renk, konum, önizleme, arama', Simgeler.paintBrush, Marka.mor, () => _git(const WidgetAyarEkrani())),
      if (Uyg.yetki('settings.manage'))
        _Oge('WhatsApp bağlantısı', 'Olayları gruba ya da numaraya ilet', Simgeler.whatsapp, Marka.yesilKoyu, () => _git(const WhatsappEkrani())),
      if (Uyg.yetki('settings.manage'))
        _Oge('Tetikleyiciler', 'Otomasyon kuralları ve puanlama', Simgeler.bolt, Marka.kehribar, () => _git(const TetikleyicilerEkrani())),
      if (Uyg.yetki('canned.manage'))
        _Oge('Hazır yanıtlar', 'Kısayollu şablon mesajlar', Simgeler.chatText, Marka.mavi, () => _git(const HazirYanitlarEkrani())),
      if (Uyg.yetki('departments.manage'))
        _Oge('Bölümler', 'Departmanlar, otomatik yanıtlar', Simgeler.accountTree, Marka.lavanta, () => _git(const BolumlerEkrani())),
    ];
    final ekip = <_Oge>[
      if (Uyg.yetki('agents.manage')) _Oge('Personel', 'Hesaplar, roller, özel yetkiler', Simgeler.usersThree, Marka.mor, () => _git(const PersonelEkrani())),
      if (Uyg.yetki('roles.manage')) _Oge('Roller ve yetkiler', 'Yetki setleri', Simgeler.shieldCheck, Marka.indigo, () => _git(const RollerEkrani())),
      if (Uyg.yetki('agents.manage'))
        _Oge('Erişim engelleri', 'Personel hesabını geçici kilitle', Simgeler.personOff, Marka.gul, () => _git(const ErisimEngelEkrani())),
      if (Uyg.yetki('bans.manage')) _Oge('Yasaklar', 'IP, e-posta, ziyaretçi engelleri', Simgeler.prohibit, Marka.gul, () => _git(const YasaklarEkrani())),
      if (Uyg.yetki('settings.manage'))
        _Oge('Acil durum', 'Arıza duyurusu ve saldırı modu', Simgeler.siren, Marka.kehribar, () => _git(const AcilDurumEkrani())),
      if (Uyg.yetki('settings.manage'))
        _Oge('Cihazlar ve oturumlar', 'Web/uygulama oturumları, bildirim cihazları', Simgeler.deviceMobile, Marka.gok, () => _git(const CihazlarEkrani())),
    ];
    final kayit = <_Oge>[
      _Oge('Bildirimler', 'Bildirim merkezi: sohbet, mesaj, ekip', Simgeler.notifications, Marka.gul, () => bolumIstegi.value = Bolum.bildirimler),
      if (Uyg.yetki('chats.view')) _Oge('Geçmiş sohbetler', 'Arama, süzgeç, dışa aktarım', Simgeler.history, Marka.mavi, () => _git(const GecmisEkrani())),
      if (Uyg.yetki('reports.view'))
        _Oge('Raporlar', 'Günlük/aylık istatistik, SLA, personel', Simgeler.chartBar, Marka.zumrut, () => _git(const RaporlarEkrani())),
      if (Uyg.yetki('settings.manage')) _Oge('Denetim kaydı', 'Kim, ne, ne zaman', Simgeler.clipboardText, Marka.grafit, () => _git(const DenetimEkrani())),
      _Oge(
        'Sürüm ve değişiklikler',
        'Uygulama ${Uyg.api.surum}${Uyg.sunucuSurumu.isNotEmpty ? ' · sunucu ${Uyg.sunucuSurumu}' : ''}',
        Simgeler.gitBranch,
        Marka.indigo,
        () => _git(const SurumEkrani()),
      ),
    ];
    return Scaffold(
      appBar: ekranBasligi(context, 'Ayarlar'),
      body: ValueListenableBuilder<Temsilci?>(
        valueListenable: Uyg.ben,
        builder: (_, t, _) => ortala(
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              if (t != null)
                Kutu(
                  onTap: () => _git(const ProfilEkrani()),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          KisiAvatar(t.ad, url: t.avatar, boyut: 56),
                          Positioned(right: 0, bottom: 0, child: Nokta(musaitlikRengi(t.musaitlik), boyut: 14, halka: r.kart)),
                        ],
                      ),
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
                              runSpacing: 4,
                              children: [
                                Rozet(t.rolAdi, renk: t.yonetici ? Marka.mor : Marka.mavi),
                                if (t.bolum != null) Rozet(t.bolum!, renk: Marka.lavanta),
                                Rozet(t.totp ? '2FA açık' : '2FA kapalı', renk: t.totp ? Marka.zumrut : Marka.kehribar, ikon: Simgeler.verifiedUser),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Simgeler.chevronRight, color: r.silik),
                    ],
                  ),
                ),
              const Baslik('Durumum'),
              Kutu(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in ['online', 'away', 'dnd', 'offline'])
                      ChoiceChip(
                        selected: t?.musaitlik == m,
                        onSelected: (_) => _musaitlik(m),
                        avatar: Nokta(musaitlikRengi(m), boyut: 9),
                        label: Text(musaitlikAdi(m)),
                      ),
                  ],
                ),
              ),
              const Baslik('Hesabım'),
              Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    _satir('Profil ve güvenlik', 'Ad, takma ad, parola, 2FA, avatar', Simgeler.userCircle, Marka.mor, () => _git(const ProfilEkrani())),
                    _satir(
                      'Bildirimler',
                      'Push, ses, e-posta ve sohbet eşikleri',
                      Simgeler.bellRinging,
                      Marka.kehribar,
                      () => _git(const BildirimAyarEkrani()),
                    ),
                    _satir(
                      'Müsaitlik ve çalışma saatlerim',
                      'Rahatsız etme, otomatik uzakta',
                      Simgeler.calendarCheck,
                      Marka.zumrut,
                      () => _git(const MusaitlikEkrani()),
                    ),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: temaKipi,
                      builder: (_, kip, _) => ListTile(
                        leading: _ikon(Simgeler.palette, Marka.indigo),
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
                    ValueListenableBuilder<double>(
                      valueListenable: arayuzOlcegi,
                      builder: (_, v, _) => ListTile(
                        leading: _ikon(Simgeler.search, Marka.gok),
                        title: const Text('Görünüm boyutu'),
                        subtitle: Text('Büyük monitörde yazı ve düğmeler birlikte büyür', style: TextStyle(color: r.silik, fontSize: 12)),
                        trailing: SegmentedButton<double>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 0, label: Text('Oto')),
                            ButtonSegment(value: 1, label: Text('100')),
                            ButtonSegment(value: 1.2, label: Text('120')),
                            ButtonSegment(value: 1.4, label: Text('140')),
                          ],
                          selected: {
                            const [0.0, 1.0, 1.2, 1.4].contains(v) ? v : 0.0,
                          },
                          onSelectionChanged: (s) => olcekKaydet(s.first),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: sesAcik,
                      builder: (_, v, _) => SwitchListTile(
                        value: v,
                        onChanged: sesKaydet,
                        secondary: _ikon(v ? Simgeler.speaker : Simgeler.speakerOff, Marka.mavi),
                        title: const Text('Uygulama açıkken ses'),
                        subtitle: Text('Yeni sohbet ve mesajda bildirim sesi', style: TextStyle(color: r.silik, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
              if (yonetim.isNotEmpty) ...[const Baslik('Sohbet ve widget'), _izgara(yonetim, r)],
              if (ekip.isNotEmpty) ...[const Baslik('Ekip ve güvenlik'), _izgara(ekip, r)],
              const Baslik('Kayıtlar'),
              _izgara(kayit, r),
              const Baslik('Diğer'),
              Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    _satir('Web paneli', Uyg.api.sunucu.replaceFirst('https://', ''), Simgeler.openInNew, Marka.grafit, () => disAc('${Uyg.api.sunucu}/admin')),
                    ListTile(
                      leading: _ikon(Simgeler.logout, Marka.gul),
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
                    const BogahostLogoGorunumu(genislik: 44, yalnizAmblem: true),
                    const SizedBox(height: 8),
                    Text('Bogahost Chat ${Uyg.api.surum} · $platform', style: TextStyle(color: r.silik, fontSize: 12)),
                    if (Uyg.sunucuSurumu.isNotEmpty) Text('Sunucu ${Uyg.sunucuSurumu}', style: TextStyle(color: r.silik, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ikon(IconData i, Color c) => Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(color: c.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
    child: Icon(i, color: c, size: 20),
  );

  Widget _satir(String ad, String alt, IconData i, Color c, VoidCallback onTap) => ListTile(
    leading: _ikon(i, c),
    title: Text(ad),
    subtitle: Text(
      alt,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: context.r.silik, fontSize: 12),
    ),
    trailing: Icon(Simgeler.chevronRight, color: context.r.silik, size: 20),
    onTap: onTap,
  );

  Widget _izgara(List<_Oge> l, Renkler r) => LayoutBuilder(
    builder: (_, c) {
      final sutun = c.maxWidth >= 720
          ? 3
          : c.maxWidth >= 460
          ? 2
          : 1;
      final en = (c.maxWidth - (sutun - 1) * 10) / sutun;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final o in l)
            SizedBox(
              width: en,
              child: Kutu(
                padding: const EdgeInsets.all(12),
                onTap: o.ac,
                child: Row(
                  children: [
                    _ikon(o.ikon, o.renk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.ad,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 13.5),
                          ),
                          Text(
                            o.alt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: r.silik, fontSize: 11.5),
                          ),
                        ],
                      ),
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

class _Oge {
  const _Oge(this.ad, this.alt, this.ikon, this.renk, this.ac);
  final String ad, alt;
  final IconData ikon;
  final Color renk;
  final VoidCallback ac;
}
