import 'package:destek/veri/modeller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sohbet satırı sunucu JSON\'undan çözülür', () {
    final s = Sohbet.coz({'id': 12, 'visitor': 'Ayşe', 'status': 'open', 'unread': '3', 'favorite': 1, 'last': '2 dk önce', 'missed': false});
    expect(s.id, 12);
    expect(s.okunmamis, 3);
    expect(s.favori, isTrue);
    expect(s.durumAdi, 'Açık');
  });

  test('Bildirim adresinden sohbet numarası çıkar', () {
    final b = Bildirim.coz({'id': 'msg-5', 'title': 't', 'body': 'b', 'url': '/admin/chats?open=77', 'read': false, 'age_s': 10});
    expect(b.sohbetId, 77);
    expect(b.veritabaniId, isNull);
  });

  test('Mesaj türleri', () {
    final m = Mesaj.coz({'id': 1, 'sender': 'visitor', 'name': 'Z', 'type': 'text', 'body': 'merhaba', 'at': '10:00', 'file': {'url': '/x.png', 'name': 'x.png', 'size': 10, 'image': true}});
    expect(m.ziyaretci, isTrue);
    expect(m.ek?.gorsel, isTrue);
    expect(Mesaj.coz({'id': 2, 'sender': 'system', 'type': 'event', 'at': ''}).sistem, isTrue);
  });
}
