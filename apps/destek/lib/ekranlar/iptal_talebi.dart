import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../ortak/parcalar.dart';
import '../ortak/simgeler.dart';
import '../veri/depo.dart';
import '../veri/json.dart';

/// Web panelindeki "Hizmetler & İptal Talebi" sayfası: ziyaretçiyle eşleşen WHMCS müşterisinin hizmetleri,
/// seçilen hizmet için GERÇEK iptal talebi (WHMCS tblcancelrequests) — çift onay (işlem + kimlik doğrulama).
class IptalTalebiEkrani extends StatefulWidget {
  const IptalTalebiEkrani({super.key, required this.sohbetId, required this.ad});
  final int sohbetId;
  final String ad;

  static Future<void> ac(BuildContext context, {required int sohbetId, required String ad}) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => IptalTalebiEkrani(sohbetId: sohbetId, ad: ad),
    ),
  );

  @override
  State<IptalTalebiEkrani> createState() => _IptalTalebiEkraniState();
}

class _IptalTalebiEkraniState extends State<IptalTalebiEkrani> {
  late Future<Map<String, dynamic>> _f = Depo.hizmetler(widget.sohbetId);
  void _yenile() => setState(() => _f = Depo.hizmetler(widget.sohbetId));

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hizmetler & iptal talebi · ${widget.ad}'),
        actions: [IconButton(tooltip: 'Yenile', onPressed: _yenile, icon: const Icon(Simgeler.refresh))],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _f,
        builder: (context, s) {
          if (s.hasError) return Durum.hata(hataMetni(s.error!), tekrar: _yenile);
          if (!s.hasData) return const Durum.yukleniyor();
          final v = s.data!;
          if (v['ok'] == false) return Durum.hata(metin(v['error'], 'WHMCS hizmetleri alınamadı.'), tekrar: _yenile);
          return ortala(_icerik(v, r), enCok: 1100);
        },
      ),
    );
  }

  Widget _icerik(Map<String, dynamic> v, Renkler r) {
    final eslesme = metin(v['match'], 'none');
    final musteri = v['client'] is Map ? harita(v['client']) : null;
    final para = metinYa(v['currency']) ?? '';
    final hizmetler = haritalar(v['services']);
    final ziy = v['visitor'] is Map ? harita(v['visitor']) : null;
    final musteriAdi = musteri == null ? null : [metinYa(musteri['firstname']), metinYa(musteri['lastname'])].whereType<String>().join(' ').trim();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Kutu(
          child: Row(
            children: [
              Icon(eslesme == 'none' ? Simgeler.reportProblem : Simgeler.idBadge, color: eslesme == 'none' ? Marka.kehribar : Marka.zumrut),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      musteri == null
                          ? 'Bu ziyaretçi bir WHMCS müşterisiyle eşleşmedi'
                          : 'WHMCS müşterisi #${musteri['id']}${musteriAdi != null && musteriAdi.isNotEmpty ? ' · $musteriAdi' : ''}',
                      style: TextStyle(color: r.metin, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (musteri != null && metinYa(musteri['companyname']) != null) metin(musteri['companyname']),
                        if (musteri != null && metinYa(musteri['email']) != null) metin(musteri['email']),
                        if (ziy != null && metinYa(ziy['email']) != null) 'ziyaretçi: ${metin(ziy['email'])}',
                        'eşleşme: ${_eslesmeAdi(eslesme)}',
                      ].join(' · '),
                      style: TextStyle(color: r.soluk, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Baslik('Hizmetler (${hizmetler.length})'),
        if (hizmetler.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Hizmet bulunamadı.',
              textAlign: TextAlign.center,
              style: TextStyle(color: r.silik),
            ),
          )
        else
          for (final h in hizmetler) _hizmet(h, para, r),
      ],
    );
  }

  static String _eslesmeAdi(String s) => switch (s) {
    'whmcs_id' => 'WHMCS kimliği',
    'email' => 'e-posta',
    'phone' => 'telefon',
    'none' => 'yok',
    final x => x,
  };

  Widget _hizmet(Map<String, dynamic> h, String para, Renkler r) {
    final durum = metin(h['status']);
    final grup = metinYa(h['groupname']);
    final ad = grup != null && grup.isNotEmpty ? '$grup · ${metin(h['name'], 'Hizmet')}' : metin(h['name'], 'Hizmet');
    final alan = metinYa(h['domain']);
    final tutar = metinYa(h['recurringamount']);
    final sonrakiOdeme = metinYa(h['nextduedate']);
    final donem = metinYa(h['billingcycle']);
    final iptalBekliyor = h['cancel_request'] != null && h['cancel_request'] != false;
    final aktif = h['cancellable'] == null ? const {'Active', 'Suspended', 'Pending'}.contains(durum) : mantik(h['cancellable']);
    final engel = metinYa(h['block_reason']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Kutu(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        ad,
                        style: TextStyle(color: r.metin, fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      Rozet(_durumAdi(durum), renk: _durumRengi(durum)),
                      if (iptalBekliyor) const Rozet('İptal talebi var', renk: Marka.kehribar),
                      if (!aktif && engel != null && engel.isNotEmpty) Rozet(engel, renk: const Color(0xFF94A3B8)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (alan != null && alan.isNotEmpty) alan,
                      if (tutar != null) '$tutar $para'.trim(),
                      ?donem,
                      if (sonrakiOdeme != null) 'sonraki ödeme $sonrakiOdeme',
                      '#${h['id']}',
                    ].join(' · '),
                    style: TextStyle(color: r.soluk, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(foregroundColor: Marka.gul),
              onPressed: aktif && !iptalBekliyor ? () => _iptalFormu(h, ad, alan) : null,
              icon: const Icon(Simgeler.cancel, size: 16),
              label: const Text('İptal talebi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _iptalFormu(Map<String, dynamic> h, String ad, String? alan) async {
    final sebep = TextEditingController();
    var tur = 'End of Billing Period';
    var onay = false, kimlik = false;
    final etiket = alan != null && alan.isNotEmpty ? '$ad · $alan' : ad;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) {
          final r = c.r;
          final gecerli = sebep.text.trim().length >= 3 && onay && kimlik;
          return AlertDialog(
            title: const Text('İptal talebi oluştur'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Marka.gul.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Marka.gul.withValues(alpha: .35)),
                      ),
                      child: Text(
                        'GERÇEK iptal talebi: WHMCS\'te kayıt oluşur, müşteriye e-posta gider. Hizmet: $etiket',
                        style: TextStyle(color: r.metin, fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sebep,
                      minLines: 2,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: const InputDecoration(labelText: 'İptal sebebi (müşterinin ifadesi)', counterText: ''),
                      onChanged: (_) => set(() {}),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: tur,
                      decoration: const InputDecoration(labelText: 'İptal zamanı'),
                      items: const [
                        DropdownMenuItem(value: 'End of Billing Period', child: Text('Dönem sonunda')),
                        DropdownMenuItem(value: 'Immediate', child: Text('Hemen')),
                      ],
                      onChanged: (v) => set(() => tur = v ?? tur),
                    ),
                    const SizedBox(height: 6),
                    CheckboxListTile(
                      value: onay,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Müşteri bu hizmetin iptalini açıkça istedi; işlemi onaylıyorum.'),
                      onChanged: (v) => set(() => onay = v ?? false),
                    ),
                    CheckboxListTile(
                      value: kimlik,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Müşterinin kimliğini doğruladım (hesap e-postası / telefon / güvenlik sorusu).'),
                      onChanged: (v) => set(() => kimlik = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Marka.gul, foregroundColor: Colors.white),
                onPressed: gecerli ? () => Navigator.pop(c, true) : null,
                child: const Text('İptal talebi oluştur'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    final v = await islem(
      () => Depo.iptalTalebi(widget.sohbetId, {
        'service_id': tamsayi(h['id']),
        'cancellationreason': sebep.text.trim(),
        'type': tur,
        'confirm': true,
        'identity_confirmed': true,
        'service_label': etiket,
      }),
    );
    if (v == null) return;
    if (v['ok'] == false) {
      bildir('İptal talebi oluşturulamadı', mesaj: metin(v['error'], 'Bilinmeyen hata'), tur: MesajTur.hata);
      return;
    }
    bildir('İptal talebi oluşturuldu', mesaj: metinYa(v['message']) ?? 'WHMCS #${v['id']}', tur: MesajTur.basari);
    _yenile();
  }

  static String _durumAdi(String s) => switch (s) {
    'Active' => 'Aktif',
    'Suspended' => 'Askıda',
    'Pending' => 'Bekliyor',
    'Cancelled' => 'İptal',
    'Terminated' => 'Sonlandı',
    'Fraud' => 'Sahte',
    final x => x,
  };

  static Color _durumRengi(String s) => switch (s) {
    'Active' => Marka.zumrut,
    'Suspended' => Marka.kehribar,
    'Pending' => Marka.mavi,
    _ => const Color(0xFF94A3B8),
  };
}
