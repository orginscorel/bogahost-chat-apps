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

/// Diğer ekranların kullandığı yardımcılar (tür adı).
abstract final class YasaklarEkraniYardim {
  static String turAdi(String t) => yasakTurleri.firstWhere((x) => x.$1 == t, orElse: () => ('', t)).$2;
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

  /// Sunucu demetleri (`groups`): sohbetten verilen çok vektörlü yasak tek satır (IP + ağ + cihaz + ziyaretçi + e-posta).
  /// Eski sunucuda `groups` yoksa her kayıt kendi demeti olur.
  static List<Map<String, dynamic>> demetler(Map<String, dynamic> v) {
    final g = haritalar(v['groups']);
    if (g.isNotEmpty) return g;
    return [
      for (final x in [...haritalar(v['active']), ...haritalar(v['expired'])])
        {
          ...x,
          'key': 'tek-${x['id']}',
          'count': 1,
          'types': [metin(x['type'])],
          'items': [
            {'id': x['id'], 'type': x['type'], 'label': turAdi(metin(x['type'])), 'value': x['value'], 'hits': x['hits']},
          ],
          'summary': '${turAdi(metin(x['type']))}: ${metin(x['value'])}',
          'active': x['expires_at'] == null || (tarihOku(x['expires_at'])?.isAfter(DateTime.now()) ?? true),
          'permanent': x['expires_at'] == null,
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return AyarSayfa(
      baslik: 'Yasaklılar',
      yukle: Panel.yasaklar,
      govde: (context, v, yenile) {
        final hepsi = demetler(v);
        final aktif = hepsi.where((x) => x['active'] == true).toList();
        final dolmus = hepsi.where((x) => x['active'] != true).toList();
        final q = _q.text.trim().toLowerCase();
        final liste = [
          for (final x in hepsi)
            if ((_durum == 'hepsi' || (_durum == 'aktif') == (x['active'] == true)) &&
                (_tur == 'hepsi' || (x['types'] as List?)?.contains(_tur) == true) &&
                (q.isEmpty || [x['who'], x['summary'], x['reason'], x['notes'], ekleyen(x)].any((f) => '${f ?? ''}'.toLowerCase().contains(q))))
              x,
        ];
        final isabet = hepsi.fold<int>(0, (a, b) => a + tamsayi(b['hits']));
        final hafta = hepsi.where((x) => (tarihOku(x['created_at'])?.isAfter(DateTime.now().subtract(const Duration(days: 7))) ?? false)).length;
        final turler = {
          for (final x in hepsi) ...[for (final t in (x['types'] as List? ?? const [])) '$t'],
        };
        return LayoutBuilder(
          builder: (_, k) {
            final tablo = k.maxWidth >= 900;
            return ListView(
              children: [
                SayfaBasi(
                  'Yasaklılar',
                  alt:
                      'Sohbetten verilen yasaklar demet halindedir: IP, ağ bloğu, cihaz, ziyaretçi ve e-posta tek satırda görünür, tek dokunuşla hepsi kalkar.',
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
                      etiket: 'Etkin yasaklı',
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
                LayoutBuilder(
                  builder: (_, k) {
                    final arama = TextField(
                      controller: _q,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Kişi, IP, e-posta, sebep ya da ekleyen…',
                        prefixIcon: const Icon(Simgeler.search, size: 18),
                        isDense: true,
                        suffixIcon: _q.text.isEmpty ? null : IconButton(icon: const Icon(Simgeler.close, size: 16), onPressed: () => setState(_q.clear)),
                      ),
                    );
                    final suzgec = SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'aktif', label: Text('Aktif')),
                        ButtonSegment(value: 'dolmus', label: Text('Dolmuş')),
                        ButtonSegment(value: 'hepsi', label: Text('Tümü')),
                      ],
                      selected: {_durum},
                      onSelectionChanged: (s) => setState(() => _durum = s.first),
                    );
                    // Telefonda arama kutusu ile süzgeç alt alta; yan yana sığmayınca ipucu ve segmentler kırılıyordu.
                    if (k.maxWidth < 520) {
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [arama, const SizedBox(height: 8), suzgec]);
                    }
                    return Row(children: [Expanded(child: arama), const SizedBox(width: 10), suzgec]);
                  },
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
                Text('${liste.length} yasaklı', style: TextStyle(color: r.silik, fontSize: 12)),
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
                          const TabloBasi(
                            [('KİM', 3), ('NEYLE YASAKLANDI', 6), ('SEBEP', 3), ('DURUM', 2), ('EKLEYEN', 2), ('TARİH', 3), ('', 0)],
                            genislikler: [null, null, null, null, null, null, 150],
                          ),
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
    final aktif = x['active'] == true;
    return Rozet(aktif ? 'Aktif' : 'Süresi doldu', renk: aktif ? Marka.zumrut : Marka.grafitAcik, ikon: aktif ? Simgeler.checkCircle : Simgeler.history);
  }

  Widget _isabet(Map<String, dynamic> x) {
    final n = tamsayi(x['hits']);
    return Rozet('$n isabet', renk: n > 0 ? Marka.kehribar : Marka.grafitAcik);
  }

  static IconData _turSimge(String t) => switch (t) {
    'ip' || 'ip_range' => Simgeler.public,
    'email' => Simgeler.mail,
    'visitor' => Simgeler.person,
    'fingerprint' => Simgeler.devices,
    _ => Simgeler.prohibit,
  };

  /// "Neyle yasaklandı": demetteki her kayıt tür + değer çipi.
  Widget _vektorler(Map<String, dynamic> x, Renkler r) {
    final items = haritalar(x['items']);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final it in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: r.vurguYumusak,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: r.kenar.withValues(alpha: .7)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_turSimge(metin(it['type'])), size: 13, color: r.soluk),
                const SizedBox(width: 4),
                Text('${metinYa(it['label']) ?? turAdi(metin(it['type']))}: ', style: TextStyle(color: r.soluk, fontSize: 11.5)),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: SelectableText(
                    metin(it['value']),
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _kim(Map<String, dynamic> x) => metinYa(x['who']) ?? 'Ziyaretçi';

  String _sure(Map<String, dynamic> x) => x['permanent'] == true || x['expires_at'] == null ? 'Kalıcı' : 'Bitiş: ${tamZaman(tarihOku(x['expires_at']))}';

  Future<void> _sil(BuildContext context, Map<String, dynamic> x, VoidCallback yenile) async {
    final n = tamsayi(x['count']);
    final ok = await onayla(
      context,
      n > 1 ? 'Tüm yasaklar kaldırılsın mı?' : 'Yasak kaldırılsın mı?',
      mesaj: n > 1 ? '${_kim(x)} için $n kayıt tek seferde kalkar:\n${metin(x['summary'])}' : metin(x['summary']),
      evet: n > 1 ? 'Hepsini kaldır' : 'Kaldır',
      tehlikeli: true,
    );
    if (ok && await kaydet(() => Panel.yasakSil(tamsayi(x['id'])), tamam: n > 1 ? '$n yasak kaldırıldı' : 'Yasak kaldırıldı')) yenile();
  }

  Widget _kaldirDugmesi(Map<String, dynamic> x, VoidCallback yenile) {
    final n = tamsayi(x['count']);
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: Marka.zumrut),
      onPressed: () => _sil(context, x, yenile),
      icon: const Icon(Simgeler.checkCircle, size: 16),
      label: Text(n > 1 ? 'Hepsini kaldır ($n)' : 'Kaldır', style: const TextStyle(fontSize: 12.5)),
    );
  }

  Widget _tabloSatiri(Map<String, dynamic> x, Renkler r, VoidCallback yenile) {
    final soluk = TextStyle(color: r.silik, fontSize: 11.5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _kim(x),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, color: r.metin, fontSize: 13),
                ),
                if (x['conversation_id'] != null) Text('Sohbet #${x['conversation_id']}', style: soluk),
                if (tamsayi(x['count']) > 1) Text('${x['count']} kayıt · birlikte kalkar', style: soluk),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(padding: const EdgeInsets.only(right: 8), child: _vektorler(x, r)),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metin(x['reason'], '—'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: r.soluk, fontSize: 12.5),
                  ),
                  if (metinYa(x['notes']) != null) Text(metin(x['notes']), maxLines: 1, overflow: TextOverflow.ellipsis, style: soluk),
                ],
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
                Text(_sure(x), style: soluk),
              ],
            ),
          ),
          SizedBox(
            width: 150,
            child: Align(alignment: Alignment.centerRight, child: _kaldirDugmesi(x, yenile)),
          ),
        ],
      ),
    );
  }

  Widget _kart(Map<String, dynamic> x, Renkler r, VoidCallback yenile) {
    final aktif = x['active'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Kutu(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          Text(
                            _kim(x),
                            style: TextStyle(fontWeight: FontWeight.w700, color: r.metin),
                          ),
                          _durumHapi(x),
                          _isabet(x),
                          if (tamsayi(x['count']) > 1) Rozet('${x['count']} kayıt', renk: Marka.mavi),
                        ],
                      ),
                      if (metinYa(x['reason']) != null) Text(metin(x['reason']), style: TextStyle(color: r.soluk, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _vektorler(x, r),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_sure(x)} · ${ekleyen(x)} · ${kisaZaman(tarihOku(x['created_at']))}${x['conversation_id'] != null ? ' · Sohbet #${x['conversation_id']}' : ''}',
                    style: TextStyle(color: r.silik, fontSize: 11.5),
                  ),
                ),
                _kaldirDugmesi(x, yenile),
              ],
            ),
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
