import 'package:boga_ortak/boga_ortak.dart';
import 'package:flutter/material.dart';

import '../../ortak/parcalar.dart';
import '../../ortak/simgeler.dart';
import '../../veri/panel.dart';
import '../kabuk.dart';

/// Ayar sayfası iskeleti: yükle → göster; hata/yükleniyor durumları, yenile.
class AyarSayfa extends StatefulWidget {
  const AyarSayfa({
    super.key,
    required this.baslik,
    required this.yukle,
    required this.govde,
    this.eylemler = const [],
    this.altBar,
    this.dolgu = const EdgeInsets.fromLTRB(16, 4, 16, 40),
  });
  final String baslik;
  final Future<Map<String, dynamic>> Function() yukle;
  final Widget Function(BuildContext context, Map<String, dynamic> v, VoidCallback yenile) govde;
  final List<Widget> eylemler;
  final Widget? altBar;
  final EdgeInsets dolgu;
  @override
  State<AyarSayfa> createState() => _AyarSayfaState();
}

class _AyarSayfaState extends State<AyarSayfa> {
  Map<String, dynamic>? _v;
  String? _hata;

  @override
  void initState() {
    super.initState();
    yenile();
  }

  Future<void> yenile() async {
    try {
      final v = await widget.yukle();
      if (!mounted) return;
      setState(() {
        _v = v;
        _hata = null;
      });
    } catch (e) {
      if (mounted) setState(() => _hata = hataMetni(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gomulu = kabukGomulu(context);
    final yenileDugmesi = IconButton(tooltip: 'Yenile', onPressed: yenile, icon: const Icon(Simgeler.refresh));
    final icerik = _hata != null
        ? Durum.hata(_hata!, tekrar: yenile)
        : _v == null
        ? const Durum.yukleniyor()
        : RefreshIndicator(
            onRefresh: yenile,
            child: Padding(padding: widget.dolgu, child: widget.govde(context, _v!, yenile)),
          );
    return Scaffold(
      appBar: gomulu ? null : AppBar(title: Text(widget.baslik), actions: [...widget.eylemler, yenileDugmesi, ...kabukEylemleri(context)]),
      body: gomulu
          ? ortala(
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.baslik,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.r.metin),
                          ),
                        ),
                        ...widget.eylemler,
                        yenileDugmesi,
                      ],
                    ),
                  ),
                  Expanded(child: icerik),
                ],
              ),
              enCok: 1400,
            )
          : icerik,
      bottomNavigationBar: widget.altBar,
    );
  }
}

/// Kaydet düğmesi şeridi.
class KaydetSeridi extends StatelessWidget {
  const KaydetSeridi({super.key, required this.onKaydet, this.etiket = 'Kaydet', this.mesgul = false});
  final Future<void> Function() onKaydet;
  final String etiket;
  final bool mesgul;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: FilledButton.icon(
        onPressed: mesgul ? null : onKaydet,
        icon: mesgul ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Simgeler.save, size: 18),
        label: Text(etiket),
      ),
    ),
  );
}

/// Eylem yanıtını bildirime çevirir; hata olursa gösterir. Başarıda true.
Future<bool> kaydet(Future<Map<String, dynamic>> Function() f, {String? tamam}) async {
  final v = await islem(f);
  if (v == null) return false;
  bildir(tamam ?? mesajAl(v), tur: MesajTur.basari);
  return true;
}

/// Metin alanı (etiket üstte).
Widget alan(String etiket, TextEditingController c, {int satir = 1, String? ipucu, bool gizli = false, TextInputType? tur, String? alt, bool etkin = true}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: gizli ? 1 : satir,
        obscureText: gizli,
        keyboardType: tur,
        enabled: etkin,
        decoration: InputDecoration(labelText: etiket, hintText: ipucu, helperText: alt, alignLabelWithHint: satir > 1),
      ),
    );

/// Anahtar satırı.
Widget anahtar(String etiket, bool v, ValueChanged<bool> onChanged, {String? alt, IconData? ikon}) => SwitchListTile(
  value: v,
  onChanged: onChanged,
  title: Text(etiket),
  subtitle: alt == null ? null : Text(alt, style: const TextStyle(fontSize: 12)),
  secondary: ikon == null ? null : Icon(ikon),
  dense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
);

/// Açılır seçim.
Widget secim<T>(String etiket, T? deger, List<(T, String)> secenekler, ValueChanged<T?> onChanged) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: DropdownButtonFormField<T>(
    initialValue: deger,
    decoration: InputDecoration(labelText: etiket),
    items: [
      for (final (v, ad) in secenekler)
        DropdownMenuItem(
          value: v,
          child: Text(ad, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  ),
);

/// Saat seçici (HH:mm).
Widget saat(BuildContext context, String etiket, String deger, ValueChanged<String> onChanged, {bool etkin = true}) {
  final p = deger.split(':');
  final t = TimeOfDay(hour: int.tryParse(p.elementAtOrNull(0) ?? '') ?? 9, minute: int.tryParse(p.elementAtOrNull(1) ?? '') ?? 0);
  return OutlinedButton(
    onPressed: !etkin
        ? null
        : () async {
            final v = await showTimePicker(context: context, initialTime: t, initialEntryMode: TimePickerEntryMode.input);
            if (v != null) onChanged('${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}');
          },
    child: Text('$etiket $deger'),
  );
}

/// Basit tablo satırı (anahtar · değer).
Widget bilgi(BuildContext context, String k, String? v, {VoidCallback? onTap, bool kopyalanir = false}) {
  final r = context.r;
  if (v == null || v.isEmpty) return const SizedBox.shrink();
  return InkWell(
    onTap: onTap ?? (kopyalanir ? () => kopyala(v) : null),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(k, style: TextStyle(color: r.silik, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(v, style: TextStyle(color: r.metin, fontSize: 13.5)),
          ),
          if (kopyalanir) Icon(Simgeler.copy, size: 14, color: r.silik),
        ],
      ),
    ),
  );
}

/// Form diyaloğu: alanlar + Kaydet. true dönerse kaydedildi.
Future<bool> formDiyalog(
  BuildContext context,
  String baslik, {
  required List<Widget> alanlar,
  required Future<Map<String, dynamic>> Function() kaydetF,
  String tamam = 'Kaydet',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(baslik),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: alanlar),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tamam)),
      ],
    ),
  );
  if (ok != true) return false;
  return kaydet(kaydetF);
}

/// Çoklu seçim satırı (yetki listesi vb.).
class SecimListesi extends StatefulWidget {
  const SecimListesi({super.key, required this.gruplar, required this.secili, required this.onChanged});
  final Map<String, Map<String, String>> gruplar;
  final Set<String> secili;
  final ValueChanged<Set<String>> onChanged;
  @override
  State<SecimListesi> createState() => _SecimListesiState();
}

class _SecimListesiState extends State<SecimListesi> {
  late final _s = Set<String>.from(widget.secili);
  @override
  Widget build(BuildContext context) {
    final r = context.r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in widget.gruplar.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              g.key,
              style: TextStyle(fontWeight: FontWeight.w600, color: r.soluk, fontSize: 12.5),
            ),
          ),
          for (final p in g.value.entries)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _s.contains(p.key),
              title: Text(p.value, style: const TextStyle(fontSize: 13.5)),
              subtitle: Text(p.key, style: TextStyle(color: r.silik, fontSize: 11)),
              onChanged: (v) {
                setState(() => v == true ? _s.add(p.key) : _s.remove(p.key));
                widget.onChanged(_s);
              },
            ),
        ],
      ],
    );
  }
}
