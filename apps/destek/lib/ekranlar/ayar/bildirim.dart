import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/simgeler.dart';
import '../../oturum.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import '../../veri/tercihler.dart';
import 'ortak.dart';

/// Bildirimler: bu cihaz (ses, anlık bildirim izni, test) + sunucu geneli (hangi olaylar anlık bildirim
/// gönderir, panel tercihleri, sohbet eşikleri). Sunucu bölümü settings.manage ister.
class BildirimAyarEkrani extends StatefulWidget {
  const BildirimAyarEkrani({super.key});
  @override
  State<BildirimAyarEkrani> createState() => _BildirimAyarEkraniState();
}

class _BildirimAyarEkraniState extends State<BildirimAyarEkrani> {
  bool? _pushVar;
  bool _mesgul = false;
  Map<String, bool>? _prefs;
  Set<String>? _olaylar;
  final _bekleme = TextEditingController(),
      _yanitsiz = TextEditingController(),
      _sla = TextEditingController(),
      _yukleme = TextEditingController(),
      _ipSinir = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Push.destekli) Push.anahtar().then((t) => mounted ? setState(() => _pushVar = t != null) : null);
  }

  Future<Map<String, dynamic>> _yukle() async {
    if (!Uyg.yetki('settings.manage')) return {};
    final v = await Panel.bildirimAyar();
    _prefs ??= harita(v['prefs']).map((k, x) => MapEntry(k, mantik(x)));
    _olaylar ??= harita(v['pushEventPrefs']).entries.where((e) => mantik(e.value)).map((e) => e.key).toSet();
    if (_bekleme.text.isEmpty) {
      _bekleme.text = '${tamsayi(v['pendingTimeout'], 5)}';
      _yanitsiz.text = '${tamsayi(v['unansweredMinutes'], 3)}';
      _sla.text = '${tamsayi(v['slaMinutes'])}';
      _yukleme.text = '${tamsayi(v['uploadMaxMb'], 10)}';
      _ipSinir.text = '${tamsayi(v['maxChatsPerIp'], 8)}';
    }
    return v;
  }

  Future<void> _kaydet() async {
    setState(() => _mesgul = true);
    await kaydet(
      () => Panel.bildirimAyarKaydet({
        for (final e in (_prefs ?? {}).entries) e.key: e.value ? 1 : 0,
        'events': (_olaylar ?? {}).toList(),
        'pending_timeout_minutes': int.tryParse(_bekleme.text) ?? 5,
        'unanswered_minutes': int.tryParse(_yanitsiz.text) ?? 3,
        'sla_minutes': int.tryParse(_sla.text) ?? 0,
        'upload_max_mb': int.tryParse(_yukleme.text) ?? 10,
        'max_chats_per_ip': int.tryParse(_ipSinir.text) ?? 8,
      }),
    );
    if (mounted) setState(() => _mesgul = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final yonetici = Uyg.yetki('settings.manage');
    return AyarSayfa(
      baslik: 'Bildirimler',
      yukle: _yukle,
      altBar: yonetici ? KaydetSeridi(mesgul: _mesgul, onKaydet: _kaydet) : null,
      govde: (context, v, yenile) {
        final olaylar = harita(v['pushEvents']);
        return ListView(
          children: [
            const Baslik('Bu cihaz'),
            Kutu(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: sesAcik,
                    builder: (_, s, _) =>
                        anahtar('Uygulama açıkken ses', s, sesKaydet, alt: 'Yeni sohbet ve ziyaretçi mesajında sistem sesi', ikon: Simgeler.speaker),
                  ),
                  if (Push.destekli)
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Icon(_pushVar == true ? Simgeler.bellRinging : Simgeler.bellSlash, color: _pushVar == true ? Marka.zumrut : Marka.kehribar),
                      title: const Text('Anlık bildirimler (APNs)'),
                      subtitle: Text(
                        _pushVar == null
                            ? 'Denetleniyor…'
                            : _pushVar!
                            ? 'Bu cihaz kayıtlı; uygulama kapalıyken de bildirim gelir.'
                            : 'İzin verilmemiş. Sistem ayarlarından bildirimi açın, sonra yeniden deneyin.',
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
                          : TextButton.icon(
                              onPressed: () => kaydet(Panel.pushTest),
                              icon: const Icon(Simgeler.send, size: 16),
                              label: const Text('Test gönder'),
                            ),
                    )
                  else
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Simgeler.notificationsNone),
                      title: const Text('Anlık bildirimler'),
                      subtitle: Text('Bu platformda bildirimler uygulama açıkken canlı akışla gelir (6 sn).', style: TextStyle(color: r.silik, fontSize: 12)),
                    ),
                ],
              ),
            ),
            if (!yonetici)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Sunucu geneli bildirim ayarları için "Genel ayarları yönet" yetkisi gerekir.', style: TextStyle(color: r.silik, fontSize: 12.5)),
              )
            else ...[
              const Baslik('Anlık bildirim gönderilecek olaylar'),
              Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: Text(
                        'Seçili olaylar telefona/Mac\'e anlık bildirim ve WhatsApp yönlendirmesi olarak gider. Rahatsız etme kipindeki personele gönderilmez.',
                        style: TextStyle(color: r.soluk, fontSize: 12.5),
                      ),
                    ),
                    for (final e in olaylar.entries)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _olaylar!.contains(e.key),
                        title: Text(metin(e.value, e.key), style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(e.key, style: TextStyle(color: r.silik, fontSize: 11)),
                        onChanged: (x) => setState(() => x == true ? _olaylar!.add(e.key) : _olaylar!.remove(e.key)),
                      ),
                  ],
                ),
              ),
              const Baslik('Web paneli tercihleri'),
              Kutu(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    anahtar('Masaüstü bildirimi', _prefs!['desktop'] ?? false, (x) => setState(() => _prefs!['desktop'] = x), ikon: Simgeler.computer),
                    anahtar('Ses', _prefs!['sound'] ?? false, (x) => setState(() => _prefs!['sound'] = x), ikon: Simgeler.speaker),
                    anahtar('E-posta', _prefs!['email'] ?? false, (x) => setState(() => _prefs!['email'] = x), ikon: Simgeler.mailOutline),
                    anahtar(
                      'Yalnız sekme gizliyken',
                      _prefs!['only_hidden'] ?? false,
                      (x) => setState(() => _prefs!['only_hidden'] = x),
                      alt: 'Panel öndeyken masaüstü bildirimi gösterme',
                      ikon: Simgeler.visibilityOff,
                    ),
                  ],
                ),
              ),
              const Baslik('Sohbet eşikleri'),
              Kutu(
                child: Column(
                  children: [
                    alan('Bekleyen sohbet uyarısı (dk)', _bekleme, tur: TextInputType.number, alt: 'Bu süre yanıt almayan bekleyen sohbet için uyarı'),
                    alan('Yanıtsız sohbet hatırlatması (dk)', _yanitsiz, tur: TextInputType.number, alt: '1-10 dakika'),
                    alan('SLA hedefi (dk)', _sla, tur: TextInputType.number, alt: '0 = kapalı'),
                    alan('Dosya yükleme sınırı (MB)', _yukleme, tur: TextInputType.number),
                    alan('IP başına en çok sohbet', _ipSinir, tur: TextInputType.number, alt: '0 = sınırsız'),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
