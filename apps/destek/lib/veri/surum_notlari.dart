/// Yerel uygulamanın (native) sürüm notları — web panelindeki changelog ile aynı zaman çizelgesinde,
/// "Native" rozetiyle gösterilir. En yeni en üstte.
const uygulamaNotlari = <Map<String, dynamic>>[
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
