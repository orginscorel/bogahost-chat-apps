import 'dart:async';

import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/simgeler.dart';
import '../ortak/yardimci.dart';
import '../veri/depo.dart';
import '../veri/modeller.dart';
import 'kabuk.dart';

class BildirimlerEkrani extends StatefulWidget {
  const BildirimlerEkrani({super.key});
  @override
  State<BildirimlerEkrani> createState() => _BildirimlerEkraniState();
}

class _BildirimlerEkraniState extends State<BildirimlerEkrani> {
  List<Bildirim>? _liste;
  String? _hata;
  Timer? _sayac;

  @override
  void initState() {
    super.initState();
    _yukle();
    _sayac = Timer.periodic(const Duration(seconds: 8), (_) => _yukle(sessiz: true));
  }

  @override
  void dispose() {
    _sayac?.cancel();
    super.dispose();
  }

  Future<void> _yukle({bool sessiz = false}) async {
    try {
      final v = await Depo.bildirimler();
      if (!mounted) return;
      setState(() {
        _liste = v.ogeler;
        _hata = null;
      });
    } catch (e) {
      if (mounted && !sessiz) setState(() => _hata = hataMetni(e));
    }
  }

  Future<void> _ac(Bildirim b) async {
    final vid = b.veritabaniId;
    if (vid != null && !b.okundu) await Depo.bildirimOkundu(vid).catchError((_) {});
    final sid = b.sohbetId;
    if (sid != null) {
      sohbetIstegi.value = sid;
    } else if (b.url.contains('/internal')) {
      bolumIstegi.value = Bolum.ekip;
    } else if (b.url.contains('/visitors')) {
      bolumIstegi.value = Bolum.ziyaretciler;
    }
    _yukle(sessiz: true);
  }

  IconData _ikon(Bildirim b) {
    if (b.id.startsWith('conv-')) return Simgeler.forum;
    if (b.id.startsWith('msg-')) return Simgeler.mail;
    if (b.url.contains('/internal')) return Simgeler.groups;
    if (b.url.contains('/visitors')) return Simgeler.visibility;
    return Simgeler.notifications;
  }

  String _sure(int sn) {
    if (sn < 60) return 'şimdi';
    if (sn < 3600) return '${sn ~/ 60} dk';
    if (sn < 86400) return '${sn ~/ 3600} sa';
    return '${sn ~/ 86400} gün';
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final l = _liste;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (l != null && l.any((b) => !b.okundu))
            TextButton(
              onPressed: () async {
                await islem(() => Depo.bildirimlerOkundu(), tamam: 'Hepsi okundu olarak işaretlendi');
                _yukle();
              },
              child: const Text('Hepsini okundu yap'),
            ),
          IconButton(tooltip: 'Yenile', onPressed: _yukle, icon: const Icon(Simgeler.refresh)),
        ],
      ),
      body: _hata != null
          ? Durum.hata(_hata!, tekrar: _yukle)
          : l == null
          ? const Durum.yukleniyor()
          : l.isEmpty
          ? Durum.bos('Bildirim yok.', ikon: Simgeler.notificationsNone)
          : RefreshIndicator(
              onRefresh: _yukle,
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: l.length,
                separatorBuilder: (_, _) => Divider(height: 1, indent: 68, color: r.kenar.withValues(alpha: .6)),
                itemBuilder: (_, i) {
                  final b = l[i];
                  return ListTile(
                    tileColor: b.okundu ? null : r.vurguYumusak.withValues(alpha: .5),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: (b.okundu ? r.soluk : r.vurgu).withValues(alpha: .13), borderRadius: BorderRadius.circular(12)),
                      child: Icon(_ikon(b), color: b.okundu ? r.soluk : r.vurgu, size: 20),
                    ),
                    title: Text(b.baslik, style: TextStyle(fontWeight: b.okundu ? FontWeight.w500 : FontWeight.w700, fontSize: 14)),
                    subtitle: Text(
                      b.govde,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: r.soluk, fontSize: 12.5),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_sure(b.yasSn), style: TextStyle(color: r.silik, fontSize: 11.5)),
                        if (!b.okundu) const Padding(padding: EdgeInsets.only(top: 4), child: Nokta(Marka.mor)),
                      ],
                    ),
                    onTap: () => _ac(b),
                  );
                },
              ),
            ),
    );
  }
}
