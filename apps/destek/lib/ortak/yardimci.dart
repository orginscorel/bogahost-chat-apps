import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../oturum.dart';
import '../veri/depo.dart';
import 'simgeler.dart';

/// Sohbet durumu rengi.
Color durumRengi(String durum) => switch (durum) {
  'open' => Marka.zumrut,
  'pending' => Marka.kehribar,
  'offline' => const Color(0xFF64748B),
  'closed' => const Color(0xFF94A3B8),
  'missed' => Marka.gul,
  _ => Marka.mor,
};

/// Müsaitlik → renk / ad.
Color musaitlikRengi(String m) => switch (m) {
  'online' => Marka.zumrut,
  'away' => Marka.kehribar,
  'dnd' => Marka.gul,
  _ => const Color(0xFF94A3B8),
};
String musaitlikAdi(String m) => switch (m) {
  'online' => 'Çevrimiçi',
  'away' => 'Uzakta',
  'dnd' => 'Rahatsız etme',
  'offline' => 'Çevrimdışı',
  _ => m,
};

/// Ülke kodundan bayrak emojisi.
String bayrak(String? kod) {
  if (kod == null || kod.length != 2) return '';
  final k = kod.toUpperCase();
  return String.fromCharCodes([0x1F1E6 + k.codeUnitAt(0) - 65, 0x1F1E6 + k.codeUnitAt(1) - 65]);
}

/// Adres kısaltma: https://bogahost.com/clientarea.php?x → bogahost.com/clientarea.php
String kisaUrl(String? u, {int en = 48}) {
  if (u == null || u.isEmpty) return '';
  var s = u.replaceFirst(RegExp(r'^https?://(www\.)?'), '');
  final q = s.indexOf('?');
  if (q > 0) s = s.substring(0, q);
  return s.length > en ? '${s.substring(0, en - 1)}…' : s;
}

/// Küçük nokta (canlılık).
class Nokta extends StatelessWidget {
  const Nokta(this.renk, {super.key, this.boyut = 9, this.halka});
  final Color renk;
  final double boyut;
  final Color? halka;
  @override
  Widget build(BuildContext context) => Container(
    width: boyut,
    height: boyut,
    decoration: BoxDecoration(
      color: renk,
      shape: BoxShape.circle,
      border: halka == null ? null : Border.all(color: halka!, width: 2),
    ),
  );
}

/// Sayı rozeti (sekme, liste).
class Sayac extends StatelessWidget {
  const Sayac(this.n, {super.key, this.renk = Marka.gul});
  final int n;
  final Color renk;
  @override
  Widget build(BuildContext context) => n <= 0
      ? const SizedBox.shrink()
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          constraints: const BoxConstraints(minWidth: 20),
          decoration: BoxDecoration(color: renk, borderRadius: BorderRadius.circular(99)),
          child: Text(
            n > 99 ? '99+' : '$n',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        );
}

/// Bağlantıyı dış tarayıcıda açar.
Future<void> disAc(String url) async {
  final u = Uri.tryParse(url);
  if (u == null) return;
  if (!await launchUrl(u, mode: LaunchMode.externalApplication)) bildir('Bağlantı açılamadı', mesaj: url, tur: MesajTur.uyari);
}

/// Eki indirip sistem görüntüleyicisinde açar.
Future<void> ekAc(String url, String ad) async {
  final f = await islem(() => Depo.ekIndir(url, ad));
  if (f == null) return;
  final r = await OpenFilex.open(f.path);
  if (r.type != ResultType.done) bildir('Dosya açılamadı', mesaj: r.message, tur: MesajTur.uyari);
}

Future<void> panoyaKopyala(String s, {String? ad}) async {
  await Clipboard.setData(ClipboardData(text: s));
  bildir('${ad ?? 'Metin'} kopyalandı', tur: MesajTur.basari);
}

/// Yetkili olmayan ekranlar için kilit gövdesi.
class Yetkisiz extends StatelessWidget {
  const Yetkisiz(this.ne, {super.key});
  final String ne;
  @override
  Widget build(BuildContext context) => Durum.bos('$ne için yetkiniz yok. Yöneticinizden rol/yetki isteyin.', ikon: Simgeler.lockOutline);
}

/// Sunucu avatarı varsa onu, yoksa baş harf avatarını çizer.
class KisiAvatar extends StatelessWidget {
  const KisiAvatar(this.ad, {super.key, this.url, this.boyut = 40});
  final String ad;
  final String? url;
  final double boyut;
  @override
  Widget build(BuildContext context) {
    final u = Uyg.tamAdres(url);
    if (u.isEmpty) return Avatar(ad, boyut: boyut);
    return ClipOval(
      child: Image.network(
        u,
        width: boyut,
        height: boyut,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Avatar(ad, boyut: boyut),
      ),
    );
  }
}
