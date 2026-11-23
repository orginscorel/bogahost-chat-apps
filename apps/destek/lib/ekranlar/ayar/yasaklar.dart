import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/parcalar.dart';
import '../../ortak/simgeler.dart';
import '../../veri/json.dart';
import '../../veri/panel.dart';
import 'ortak.dart';

const yasakTurleri = [('ip', 'IP adresi'), ('ip_range', 'IP aralığı (CIDR)'), ('visitor', 'Ziyaretçi no'), ('email', 'E-posta'), ('fingerprint', 'Parmak izi')];
const yasakSureleri = [('1h', '1 saat'), ('1d', '1 gün'), ('1w', '1 hafta'), ('1m', '1 ay'), ('perm', 'Kalıcı')];

/// Yasak ekleme diyaloğu (ziyaretçi detayından da çağrılır).
Future<bool> yasakEkleDiyalog(BuildContext context, {String tur = 'ip', String deger = '', String? not}) async {
  final d = TextEditingController(text: deger), neden = TextEditingController(), notlar = TextEditingController(text: not);
  String t = tur, sure = 'perm';
  return formDiyalog(
    context,
    'Yasak ekle',
    tamam: 'Yasakla',
    alanlar: [
      StatefulBuilder(
        builder: (_, set) => Column(
          children: [
            secim<String>('Tür', t, yasakTurleri, (x) => set(() => t = x ?? 'ip')),
            alan(
              'Değer',
              d,
              ipucu: t == 'ip_range'
                  ? '1.2.3.0/24'
                  : t == 'email'
                  ? 'ad@alan.com'
                  : '',
            ),
            secim<String>('Süre', sure, yasakSureleri, (x) => set(() => sure = x ?? 'perm')),
          ],
        ),
      ),
      alan('Neden', neden, ipucu: 'Ziyaretçiye gösterilir'),
      alan('Not', notlar, satir: 2, ipucu: 'Yalnız ekip görür'),
    ],
    kaydetF: () => Panel.yasakEkle({'type': t, 'value': d.text.trim(), 'reason': neden.text.trim(), 'notes': notlar.text.trim(), 'duration': sure}),
  );
}

/// Yasaklılar — web düzeni: özet sayaçlar, arama + tür süzgeci + durum; geniş ekranda tablo
/// (Tür · Değer · Sebep · Durum · Ekleyen · Tarih · isabet), telefonda kartlar.
class YasaklarEkrani extends StatefulWidget {
  const YasaklarEkrani({super.key});
  @override
  State<YasaklarEkrani> createState() => _YasaklarEkraniState();
}

class _YasaklarEkraniState extends State<YasaklarEkrani> {
  final _q = TextEditingController();
  String _tur = 'hepsi', _durum = 'aktif';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  static String turAdi(String t) => yasakTurleri.firstWhere((x) => x.$1 == t, orElse: () => ('', t)).$2;

  static String ekleyen(Map<String, dynamic> x) =>
      metinYa(x['created_by_name']) ??
      metinYa(harita(x['creator'])['name']) ??
      metinYa(harita(x['user'])['name']) ??
      metinYa(harita(x['created_by_user'])['name']) ??
      (x['created_by'] == null ? '—' : 'Personel #${x['created_by']}');

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Yasaklılar',
      yukle: Panel.yasaklar,
      govde: (context, v, yenile) {
        final aktif = [
          for (final x in haritalar(v['active'])) {...x, '_aktif': true},
        ];
        final dolmus = [
          for (final x in haritalar(v['expired'])) {...x, '_aktif': false},
        ];
        final hepsi = [...aktif, ...dolmus];
        final q = _q.text.trim().toLowerCase();
        final liste = [
          for (final x in hepsi)
            if ((_durum == 'hepsi' || (_durum == 'aktif') == (x['_aktif'] == true)) &&
                (_tur == 'hepsi' || metin(x['type']) == _tur) &&
                (q.isEmpty || [x['value'], x['reason'], x['notes'], ekleyen(x)].any((f) => '${f ?? ''}'.toLowerCase().contains(q))))
              x,
        ];
        final isabet = hepsi.fold<int>(0, (a, b) => a + tamsayi(b['hits']));
        final hafta = hepsi.where((x) => (tarihOku(x['created_at'])?.isAfter(DateTime.now().subtract(const Duration(days: 7))) ?? false)).length;
        final turler = {for (final x in hepsi) metin(x['type'])};
        return LayoutBuilder(
          builder: (_, k) {
            final tablo = k.maxWidth >= 900;
            return ListView(
              children: [
                SayfaBasi(
                  'Yasaklılar',
                  alt: 'IP, IP aralığı, ziyaretçi, e-posta ve parmak izi engelleri. Engellenen ziyaretçi widget\'ı göremez.',
                  sag: [
                    FilledButton.icon(
                      onPressed: () async {
                        if (await yasakEkleDiyalog(context)) yenile();
                      },
                      icon: const Icon(Simgeler.add, size: 18),
                      label: const Text('Yasak ekle'),
                    ),
                  ],
                ),
                EsitIzgara(
                  enAz: 150,
                  yukseklik: 72,
                  children: [
                    KpiKart(
                      kucuk: true,
                      etiket: 'Etkin yasak',
                      deger: '${aktif.length}',
                      ikon: Simgeler.prohibit,
                      renk: Marka.gul,
                      onTap: () => setState(() => _durum = 'aktif'),
                    ),
                    KpiKart(
                      kucuk: true,
                      etiket: 'Süresi dolmuş',
                      deger: '${dolmus.length}',
                      ikon: Simgeler.history,
                      renk: Marka.grafitAcik,
                      onTap: () => setState(() => _durum = 'dolmus'),
                    ),
                    KpiKart(kucuk: true, etiket: 'Toplam isabet', deger: '$isabet', ikon: Simgeler.target, renk: Marka.kehribar),
                    KpiKart(kucuk: true, etiket: 'Bu hafta eklenen', deger: '$hafta', ikon: Simgeler.calendarToday, renk: Marka.mavi),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _q,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Değer, sebep, not ya da ekleyen…',
                          prefixIcon: const Icon(Simgeler.search, size: 18),
                          isDense: true,
                          suffixIcon: _q.text.isEmpty ? null : IconButton(icon: const Icon(Simgeler.close, size: 16), onPressed: () => setState(_q.clear)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'aktif', label: Text('Aktif')),
                        ButtonSegment(value: 'dolmus', label: Text('Dolmuş')),
                        ButtonSegment(value: 'hepsi', label: Text('Tümü')),
                      ],
                      selected: {_durum},
                      onSelectionChanged: (s) => setState(() => _durum = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(label: const Text('Tüm türler'), selected: _tur == 'hepsi', onSelected: (_) => setState(() => _tur = 'hepsi')),
                    for (final (t, ad) in yasakTurleri)
                      if (turler.contains(t)) ChoiceChip(label: Text(ad), selected: _tur == t, onSelected: (_) => setState(() => _tur = t)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('${liste.length} kayıt', style: TextStyle(color: r.silik, fontSize: 12)),
                const SizedBox(height: 6),
                if (liste.isEmpty)
                  Durum.bos(hepsi.isEmpty ? 'Henüz yasak yok.' : 'Süzgece uyan yasak yok.', ikon: Simgeler.prohibit)
                else if (tablo)
                  Kutu(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Column(
                        children: [
                          const TabloBasi([('TÜR', 2), ('DEĞER', 4), ('SEBEP', 4), ('DURUM', 2), ('EKLEYEN', 2), ('TARİH', 3), ('', 1)]),
                          for (final (i, x) in liste.indexed) ...[
                            if (i > 0) Divider(height: 1, color: r.kenar.withValues(alpha: .6)),
                            _tabloSatiri(x, r, yenile),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  for (final x in liste) _kart(x, r, yenile),
              ],
            );
          },
        );
      },
    );
  }

  Widget _durumHapi(Map<String, dynamic> x) {
    final aktif = x['_aktif'] == true;
    return Rozet(aktif ? 'Aktif' : 'Süresi doldu', renk: aktif ? Marka.zumrut : Marka.grafitAcik, ikon: aktif ? Simgeler.checkCircle : Simgeler.history);
  }

  Widget _isabet(Map<String, dynamic> x) {
    final n = tamsayi(x['hits']);
    return Rozet('$n isabet', renk: n > 0 ? Marka.kehribar : Marka.grafitAcik);
  }

  Future<void> _sil(BuildContext context, Map<String, dynamic> x, VoidCallback yenile) async {
    if (await onayla(context, 'Yasak kaldırılsın mı?', evet: 'Kaldır', tehlikeli: true)) {
      if (await kaydet(() => Panel.yasakSil(tamsayi(x['id'])))) yenile();
    }
  }

  Widget _tabloSatiri(Map<String, dynamic> x, Renkler r, VoidCallback yenile) {
    final soluk = TextStyle(color: r.silik, fontSize: 11.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Rozet(turAdi(metin(x['type'])), renk: Marka.mavi),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  metin(x['value']),
                  style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontFamily: 'monospace', fontSize: 13),
                ),
                if (metinYa(x['notes']) != null) Text(metin(x['notes']), maxLines: 1, overflow: TextOverflow.ellipsis, style: soluk),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                metin(x['reason'], '—'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: r.soluk, fontSize: 12.5),
              ),
            ),
          ),
          Expanded(flex: 2, child: Wrap(spacing: 4, runSpacing: 4, children: [_durumHapi(x), _isabet(x)])),
          Expanded(
            flex: 2,
            child: Text(
              ekleyen(x),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: r.metin, fontSize: 12.5),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kisaZaman(tarihOku(x['created_at'])), style: TextStyle(color: r.metin, fontSize: 12.5)),
                Text(x['expires_at'] == null ? 'Kalıcı' : 'Bitiş: ${tamZaman(tarihOku(x['expires_at']))}', style: soluk),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              tooltip: 'Kaldır',
              visualDensity: VisualDensity.compact,
              icon: Icon(Simgeler.deleteOutline, size: 19, color: r.soluk),
              onPressed: () => _sil(context, x, yenile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kart(Map<String, dynamic> x, Renkler r, VoidCallback yenile) {
    final aktif = x['_aktif'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Kutu(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: (aktif ? Marka.gul : Marka.grafitAcik).withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
              child: Icon(Simgeler.prohibit, color: aktif ? Marka.gul : Marka.grafitAcik, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Rozet(turAdi(metin(x['type'])), renk: Marka.mavi),
                      SelectableText(
                        metin(x['value']),
                        style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontFamily: 'monospace'),
                      ),
                      _durumHapi(x),
                      _isabet(x),
                    ],
                  ),
                  if (metinYa(x['reason']) != null) Text(metin(x['reason']), style: TextStyle(color: r.soluk, fontSize: 12.5)),
                  if (metinYa(x['notes']) != null) Text(metin(x['notes']), style: TextStyle(color: r.silik, fontSize: 12)),
                  Text(
                    '${x['expires_at'] == null ? 'Kalıcı' : 'Bitiş: ${tamZaman(tarihOku(x['expires_at']))}'} · ${ekleyen(x)} · ${kisaZaman(tarihOku(x['created_at']))}',
                    style: TextStyle(color: r.silik, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            IconButton(tooltip: 'Kaldır', icon: const Icon(Simgeler.deleteOutline, size: 20), onPressed: () => _sil(context, x, yenile)),
          ],
        ),
      ),
    );
  }
}

/// Personel erişim engelleri: hesabı panelden geçici olarak kilitle.
class ErisimEngelEkrani extends StatelessWidget {
  const ErisimEngelEkrani({super.key});
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Erişim engelleri',
      yukle: Panel.erisimEngelleri,
      govde: (context, v, yenile) {
        final l = haritalar(v['blocks']);
        final kullanicilar = haritalar(v['users']);
        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Engelli personel panele ve uygulamaya giremez; sohbetleri yeniden dağıtılır.', style: TextStyle(color: r.soluk, fontSize: 12.5)),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    int? kim = kullanicilar.isEmpty ? null : tamsayi(kullanicilar.first['id']);
                    final neden = TextEditingController();
                    final ok = await formDiyalog(
                      context,
                      'Erişimi engelle',
                      tamam: 'Engelle',
                      alanlar: [
                        StatefulBuilder(
                          builder: (_, set) =>
                              secim<int>('Personel', kim, [for (final u in kullanicilar) (tamsayi(u['id']), metin(u['name']))], (x) => set(() => kim = x)),
                        ),
                        alan('Neden', neden),
                      ],
                      kaydetF: () => Panel.erisimEngelle(kim ?? 0, neden.text.trim()),
                    );
                    if (ok) yenile();
                  },
                  icon: const Icon(Simgeler.personOff, size: 18),
                  label: const Text('Engelle'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (l.isEmpty) Durum.bos('Engelli personel yok.', ikon: Simgeler.personOff),
            for (final x in l)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Kutu(
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  child: Row(
                    children: [
                      const Icon(Simgeler.personOff, color: Marka.gul),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metin(x['user_name'] ?? harita(x['user'])['name'] ?? x['user'], '#${x['user_id']}'),
                              style: TextStyle(fontWeight: FontWeight.w600, color: r.metin),
                            ),
                            Text(
                              '${metin(x['reason'], 'Neden belirtilmedi')} · ${kisaZaman(tarihOku(x['created_at']))}',
                              style: TextStyle(color: r.silik, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (await kaydet(() => Panel.erisimAc(tamsayi(x['id'])))) yenile();
                        },
                        child: const Text('Engeli kaldır'),
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
