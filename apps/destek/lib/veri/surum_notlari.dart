/// Yerel uygulamanın (native) sürüm notları — web panelindeki changelog ile aynı zaman çizelgesinde,
/// "Native" rozetiyle gösterilir. En yeni en üstte.
const uygulamaNotlari = <Map<String, dynamic>>[
  {
    'version': '1.2.4',
    'date': '2026-11-23',
    'title': 'Yan menü ilk renk stili, yumuşak ölçek',
    'items': [
      {'type': 'improve', 'text': 'Yan menü tema renklerinde (ilk stil): açık/koyu temaya uyar, seçili öğe mor.'},
      {'type': 'improve', 'text': 'Büyük monitörde otomatik ölçek daha yumuşak (%106 / %112 / %120).'},
      {'type': 'fix', 'text': 'Ölçekli arayüzde logo yazısı pikselli görünmüyor (yüksek örnekleme).'},
    ],
  },
  {
    'version': '1.2.3',
    'date': '2026-11-23',
    'title': 'KPI taşması, Regular simgeler, tablo sütunları',
    'items': [
      {'type': 'fix', 'text': 'KPI kartlarındaki yazılar taşmıyor; sığmazsa orantılı küçülür.'},
      {'type': 'improve', 'text': 'Simge seti Regular ağırlığa geçti; etkin menü öğesi dolu simgeyle.'},
      {'type': 'improve', 'text': 'Ziyaretçi ve yasak tablolarında sabit işlem sütunları, dar pencerede yatay kaydırma.'},
    ],
  },
  {
    'version': '1.2.2',
    'date': '2026-11-23',
    'title': 'Büyük monitörde otomatik büyütme',
    'items': [
      {'type': 'new', 'text': 'Görünüm boyutu: geniş pencerede arayüz otomatik büyür; Ayarlar > Görünüm boyutu ile Oto / 100 / 120 / 140.'},
      {'type': 'fix', 'text': 'Geniş ekranda üst çubuk nesneleri (durum, zil, tema, profil) ekranlarda bir daha yinelenmez.'},
      {'type': 'improve', 'text': 'Sohbetler: süzgeç çipleri sarılır ve hepsi görünür; mesaj sütunu ortalanır (en çok 1180 px).'},
      {'type': 'improve', 'text': 'Sayfa içeriği büyük ekranda daha geniş (1600 / ziyaretçiler 1900 px).'},
      {'type': 'fix', 'text': 'Uygulama simgesi posta uygulamalarıyla aynı aileye döndü (kurumsal amblem + sohbet rozeti).'},
      {
        'type': 'new',
        'text': 'Sohbet sağ bloğu web paneliyle aynı kapsamda: kimlik, WHMCS, IP/port/parmak izi, cihaz, yerel saat, kaynak, gezinti, olay günlüğü, geçmiş görüşmeler, atama; ziyaretçiyi yasakla / yasakları kaldır.',
      },
    ],
  },
  {
    'version': '1.2.1',
    'date': '2026-11-23',
    'title': 'Üst çubuk, sağdan paneller, gerçek logo, ekran izleme seçici',
    'items': [
      {
        'type': 'improve',
        'text':
            'Geniş ekranda tek üst çubuk: başlık, arama kutusu, durum, zil, tema, profil; ekranlar başlıklarını yinelemez. Düğme, çip ve ikonlar büyütüldü.',
      },
      {'type': 'improve', 'text': 'Ziyaretçi CRM, profil, bildirim ayarları ve menüden açılan ayarlar sağdan kayan panelde açılır.'},
      {'type': 'improve', 'text': 'Büyük ekranlarda içerik ortalı ve 1240 px ile sınırlı; sohbet balonları ve yazı büyütüldü.'},
      {'type': 'new', 'text': 'Gerçek Bogahost logosu (boynuzlu boğa başı): uygulama simgeleri ve açılış yenilendi.'},
      {'type': 'new', 'text': 'Canlı ekran izleme: İzinli co-browse / İzinsiz izle seçici (web paneliyle aynı).'},
      {'type': 'fix', 'text': 'Sohbete davet artık ziyaretçinin widget\'ında temsilci adı ve mesajıyla görünüyor.'},
      {'type': 'improve', 'text': 'Widget ayarları: iki sütun, canlı önizleme, hazır renk paleti, bölümlü seçenekler.'},
    ],
  },
  {
    'version': '1.2.0',
    'date': '2026-11-23',
    'title': 'Web paneliyle aynı düzen: yan menü, üst çubuk, pano ve ziyaretçi tablosu',
    'items': [
      {'type': 'new', 'text': 'Koyu yan menü: gruplu (Günlük iş / Analiz / Yönetim / Hesap), üzerine gelince genişler, sabitlenebilir, rozetli.'},
      {
        'type': 'new',
        'text': 'Üst çubuk: genel arama, Çevrimiçi / Uzakta / Rahatsız Etme / Çevrimdışı durum menüsü, bildirim zili, tema anahtarı, profil menüsü.',
      },
      {
        'type': 'new',
        'text': 'Genel Bakış: uyarı kartı (saldırı, acil durum, mesai dışı, bekleyen, çevrimdışı mesaj, kaçan), eşit boyda KPI kartları, kısayollar, 7 günlük yumuşak trend grafiği, memnuniyet halkası ve yıldız dağılımı, bekleyen kuyruğu, temsilci performansı, departman dağılımı.',
      },
      {
        'type': 'new',
        'text': 'Canlı Ziyaretçiler: web ile aynı tablo (konum, cihaz, sayfa, geliş kaynağı renkli, son hareket), sayaçlar, arama, süzgeç çipleri, davet / sohbet başlat / ekran izle / CRM.',
      },
      {'type': 'new', 'text': 'Bildirim merkezi: sayaçlar, tür süzgeçleri, zaman grupları; zil açılırında bekleyen sohbet uyarısı.'},
      {
        'type': 'improved',
        'text': 'Raporlar: renkli SLA paneli, eşit boyda özet kartları, yumuşatılmış seri grafiği. Geçmiş, Yasaklılar ve Sürüm notları web düzenine çekildi.',
      },
      {'type': 'fixed', 'text': 'Sesli / görüntülü arama düğmeleri ziyaretçi çevrimdışı görünse de erişilebilir; durum açıkça yazılır.'},
      {'type': 'improved', 'text': 'Rahatsız Etme modunda uygulama içi ses ve bant kapalı.'},
    ],
  },
  {
    'version': '1.1.0',
    'date': '2026-11-23',
    'title': 'Pano, ayarlar, arama, ekran izleme ve CRM',
    'items': [
      {'type': 'new', 'text': 'Pano, bildirim onayları, ziyaretçi detayı ve CRM (aday durumu, puan, atama, takip tarihi, etiket, not).'},
      {
        'type': 'new',
        'text': 'Ayarlar: profil, 2 adımlı doğrulama, bildirim tercihleri, mesai saatleri, widget, WhatsApp, tetikleyiciler, hazır yanıtlar, personel / roller / bölümler, yasaklar, acil durum, cihazlar, denetim kaydı, raporlar, geçmiş.',
      },
      {'type': 'new', 'text': 'Sesli / görüntülü arama (WebRTC, TURN relay), ekran izleme (onaylı / onaysız), kamera.'},
      {'type': 'fixed', 'text': 'Çevrimdışı mesaj bırakan ziyaretçinin widget\'ı temsilci yanıtlayınca sohbete döner.'},
    ],
  },
  {
    'version': '1.0.0',
    'date': '2026-11-22',
    'title': 'İlk sürüm',
    'items': [
      {
        'type': 'new',
        'text': 'iOS, macOS, Android ve Windows için yerel Bogahost Chat uygulaması: sohbetler, ekip içi sohbet, ziyaretçiler, bildirimler, push.',
      },
      {'type': 'new', 'text': 'Animasyonlu Bogahost açılış ekranı.'},
    ],
  },
];
