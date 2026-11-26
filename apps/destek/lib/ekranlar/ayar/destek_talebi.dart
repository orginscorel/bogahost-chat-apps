import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/parcalar.dart';
import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

/// Yanıtsız kalan WHMCS destek taleplerine Butoi adıyla otomatik karşılama: ayarlar, departman şablonları,
/// kuru çalıştırma ve gönderilenler. Web paneliyle (/admin/ai/ticket) aynı servis. settings.manage ister.
class DestekTalebiEkrani extends StatelessWidget {
  const DestekTalebiEkrani({super.key});
  @override
  Widget build(BuildContext context) => AyarSayfa(
    baslik: 'Destek talebi karşılama',
    yukle: Panel.aiTicket,
    govde: (context, v, yenile) => _Govde(key: ValueKey(v), v: v, yenile: yenile),
  );
}

class _Govde extends StatefulWidget {
  const _Govde({super.key, required this.v, required this.yenile});
  final Map<String, dynamic> v;
  final VoidCallback yenile;
  @override
  State<_Govde> createState() => _GovdeState();
}

class _GovdeState extends State<_Govde> {
  Map<String, dynamic>? _v;
  bool _mesgul = false, _kuruBusy = false;
  Map<String, dynamic>? _kuru;
  List<Map<String, dynamic>> _gecmis = const [];

  // form durumu
  bool _etkin = false, _personelVarsaYazma = true;
  String _durum = 'In Progress';
  final _bekleme = TextEditingController(), _enEski = TextEditingController(), _ad = TextEditingController(), _hesap = TextEditingController();
  final _mesaj = TextEditingController(), _imza = TextEditingController();
  final _deptMesaj = <int, TextEditingController>{};
  final _deptEtkin = <int, bool>{};

  @override
  void initState() {
    super.initState();
    _doldur(widget.v);
    _gecmisYukle();
  }

  @override
  void dispose() {
    for (final c in [_bekleme, _enEski, _ad, _hesap, _mesaj, _imza, ..._deptMesaj.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _doldur(Map<String, dynamic> v) {
    final c = harita(v['config']);
    final kurallar = {for (final d in haritalar(c['departments'])) tamsayi(d['id']): d};
    _v = v;
    _etkin = mantik(c['enabled']);
    _personelVarsaYazma = mantik(c['skip_when_agent_replied'], true);
    _durum = metin(c['status'], 'In Progress');
    _bekleme.text = '${tamsayi(c['delay'], 1)}';
    _enEski.text = '${tamsayi(c['max_age_hours'], 24)}';
    _ad.text = metin(c['bot_name'], 'Butoi');
    _hesap.text = metin(c['whmcs_admin']);
    _mesaj.text = metin(c['message']);
    _imza.text = metin(c['signature']);
    for (final d in haritalar(v['departments'])) {
      final id = tamsayi(d['id']);
      final k = kurallar[id];
      _deptEtkin[id] = k == null ? true : mantik(k['enabled'], true);
      (_deptMesaj[id] ??= TextEditingController()).text = k == null ? '' : metin(k['message']);
    }
  }

  Future<void> _gecmisYukle() async {
    final v = await islem(Panel.aiTicketGecmis);
    if (!mounted || v == null) return;
    setState(() {
      _gecmis = haritalar(v['rows']);
      if (_v != null && v['summary'] is Map) _v = {..._v!, 'summary': v['summary']};
    });
  }

  Future<void> _kaydet() async {
    setState(() => _mesgul = true);
    final ok = await kaydet(
      () => Panel.aiTicketKaydet({
        'enabled': _etkin,
        'delay': int.tryParse(_bekleme.text.trim()) ?? 1,
        'max_age_hours': int.tryParse(_enEski.text.trim()) ?? 24,
        'status': _durum,
        'bot_name': _ad.text.trim(),
        'whmcs_admin': _hesap.text.trim(),
        'message': _mesaj.text,
        'signature': _imza.text,
        'skip_when_agent_replied': _personelVarsaYazma,
        'departments': [
          for (final e in _deptEtkin.entries) {'id': e.key, 'enabled': e.value, 'message': _deptMesaj[e.key]?.text ?? ''},
        ],
      }),
    );
    if (!mounted) return;
    setState(() => _mesgul = false);
    if (ok) widget.yenile();
  }

  Future<void> _kuruCalistir() async {
    if (_kuruBusy) return;
    setState(() => _kuruBusy = true);
    final v = await islem(Panel.aiTicketKuru);
    if (!mounted) return;
    setState(() {
      _kuruBusy = false;
      _kuru = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final v = _v ?? widget.v;
    final o = harita(v['summary']);
    final depts = haritalar(v['departments']);
    final kuru = _kuru;
    // AyarSayfa gövdeyi kaydırmaz; sayfa ListView ile kayar (Column sabit kalıyordu, alt bölümlere ulaşılamıyordu)
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'WHMCS\'te "Açık" durumda kalan ve bekleme süresi dolan destek taleplerine, personel yanıtı yoksa Butoi adıyla departmanına göre şablon karşılama yanıtı yazılır; talep durumu güncellenir ve müşteri e-posta alır. Her talebe en fazla bir kez yazılır.',
            style: TextStyle(color: r.soluk, fontSize: 12.5),
          ),
        ),
        EsitIzgara(
          enAz: 150,
          yukseklik: 72,
          children: [
            KpiKart(kucuk: true, etiket: 'Toplam yanıt', deger: sayiYaz(tamsayi(o['total'])), ikon: Simgeler.receiptLong, renk: Marka.mor),
            KpiKart(
              kucuk: true,
              etiket: 'Son 30 gün',
              alt: tamsayi(o['err_30d']) > 0 ? '${tamsayi(o['err_30d'])} hata' : null,
              deger: sayiYaz(tamsayi(o['ok_30d'])),
              ikon: Simgeler.bolt,
              renk: Marka.zumrut,
            ),
            KpiKart(
              kucuk: true,
              etiket: 'Ortalama bekleme',
              deger: tamsayi(o['avg_wait']) > 0 ? '${(tamsayi(o['avg_wait']) / 60).round()} dk' : '–',
              ikon: Simgeler.timer,
              renk: Marka.mavi,
            ),
            KpiKart(kucuk: true, etiket: 'Son yanıt', deger: metin(o['last'], '–').replaceFirst(RegExp(r':\d\d$'), ''), ikon: Simgeler.history, renk: Marka.grafitAcik),
          ],
        ),
        const SizedBox(height: 12),
        Kutu(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              anahtar('Otomatik karşılama etkin', _etkin, (x) => setState(() => _etkin = x), alt: 'Kapalıyken hiçbir talebe yazılmaz', ikon: Simgeler.receiptLong),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: alan('Bekleme (dk)', _bekleme, tur: TextInputType.number, alt: 'Personel yanıtı gelmezse')),
                  const SizedBox(width: 10),
                  Expanded(child: alan('En eski talep (saat)', _enEski, tur: TextInputType.number, alt: 'Daha eskisine dokunulmaz')),
                ],
              ),
              secim('Yanıt sonrası durum', _durum, const [
                ('In Progress', 'İşlemde (In Progress)'),
                ('Answered', 'Yanıtlandı (Answered)'),
                ('On Hold', 'Beklemede (On Hold)'),
                ('', 'Değiştirme'),
              ], (x) => setState(() => _durum = x ?? 'In Progress')),
              alan('Görünen ad', _ad, ipucu: 'Butoi', alt: 'Talepte yanıtı yazan olarak görünür'),
              alan('WHMCS yanıt hesabı (Ad Soyad)', _hesap, ipucu: 'boş = ilk yönetici', alt: 'Yanıt bu hesap üzerinden kaydedilir; profil imzası eklenmez'),
              alan('Genel mesaj', _mesaj, satir: 5, alt: 'Yer tutucular: {isim_ek} müşteri adı, {isim}, {tid}, {konu}, {departman}. Departmanda özel metin yoksa bu kullanılır.'),
              alan('İmza (tüm yanıtların sonuna)', _imza, satir: 4),
              anahtar('Personel yanıtı varsa yazma', _personelVarsaYazma, (x) => setState(() => _personelVarsaYazma = x), ikon: Simgeler.shield),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text('Departmanlara göre', style: TextStyle(color: r.metin, fontWeight: FontWeight.w700, fontSize: 13.5)),
        ),
        if (depts.isEmpty) Durum.bos('Departmanlar alınamadı (WHMCS köprüsü).', ikon: Simgeler.cloudOff),
        for (final d in depts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Kutu(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  anahtar(metin(d['name']), _deptEtkin[tamsayi(d['id'])] ?? true, (x) => setState(() => _deptEtkin[tamsayi(d['id'])] = x), alt: '#${tamsayi(d['id'])}'),
                  if (_deptEtkin[tamsayi(d['id'])] ?? true)
                    alan('Özel mesaj', _deptMesaj[tamsayi(d['id'])] ??= TextEditingController(), satir: 4, ipucu: 'Boş = genel mesaj kullanılır'),
                ],
              ),
            ),
          ),
        Row(
          children: [
            FilledButton.icon(
              onPressed: _mesgul ? null : _kaydet,
              icon: _mesgul ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Simgeler.save, size: 18),
              label: const Text('Kaydet'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _kuruBusy ? null : _kuruCalistir,
              icon: _kuruBusy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Simgeler.science, size: 18),
              label: const Text('Kuru çalıştır'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Text('Kuru çalıştırma göndermez: kayıtlı ayarlarla açık talepleri değerlendirir ve hangisine ne yazılacağını gösterir.', style: TextStyle(color: r.silik, fontSize: 12)),
        ),
        if (kuru != null) ...[
          Text('Kontrol ${tamsayi(kuru['checked'])} · yazılacak ${tamsayi(kuru['replied'])} · atlanan ${tamsayi(kuru['skipped'])}', style: TextStyle(color: r.soluk, fontSize: 12.5)),
          const SizedBox(height: 6),
          if (haritalar(kuru['items']).isEmpty) Durum.bos('Şu an açık talep yok.', ikon: Simgeler.doneAll),
          for (final i in haritalar(kuru['items']))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Kutu(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('#${metin(i['tid'])}', style: TextStyle(color: r.metin, fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(metin(i['department']), style: TextStyle(color: r.soluk, fontSize: 12)),
                        metin(i['action']) == 'would_reply' ? const Rozet('Yazılacak', renk: Marka.zumrut) : const Rozet('Atla', renk: Marka.grafitAcik),
                      ],
                    ),
                    if (metinYa(i['subject']) != null) Text(metin(i['subject']), style: TextStyle(color: r.soluk, fontSize: 12.5)),
                    if (metinYa(i['reason']) != null) Text(metin(i['reason']), style: TextStyle(color: r.silik, fontSize: 12)),
                    if (metinYa(i['preview']) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SelectableText(metin(i['preview']), style: TextStyle(color: r.metin, fontSize: 12.5)),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Row(
            children: [
              Expanded(child: Text('Gönderilen yanıtlar', style: TextStyle(color: r.metin, fontWeight: FontWeight.w700, fontSize: 13.5))),
              TextButton.icon(onPressed: _gecmisYukle, icon: const Icon(Simgeler.refresh, size: 16), label: const Text('Yenile')),
            ],
          ),
        ),
        if (_gecmis.isEmpty) Durum.bos('Henüz gönderilmiş yanıt yok.', ikon: Simgeler.inbox),
        for (final x in _gecmis)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Kutu(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                            Text('#${metin(x['tid'])}', style: TextStyle(color: r.metin, fontWeight: FontWeight.w700, fontSize: 13)),
                            Text(metin(x['department']), style: TextStyle(color: r.soluk, fontSize: 12)),
                            if (!mantik(x['ok'], true)) const Rozet('Hata', renk: Marka.gul),
                          ],
                        ),
                        if (metinYa(x['subject']) != null) Text(metin(x['subject']), style: TextStyle(color: r.soluk, fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (metinYa(x['error']) != null) Text(metin(x['error']), style: const TextStyle(color: Marka.gul, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(tamZaman(tarihOku(x['created_at'])), style: TextStyle(color: r.silik, fontSize: 11.5)),
                      Text('${(tamsayi(x['wait_sec']) / 60).round()} dk sonra', style: TextStyle(color: r.silik, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
