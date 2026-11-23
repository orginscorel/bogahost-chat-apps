/// Yerel uygulamanın (native) sürüm notları — web panelindeki changelog ile aynı zaman çizelgesinde,
/// "Native" rozetiyle gösterilir. En yeni en üstte.
const uygulamaNotlari = <Map<String, dynamic>>[
  {
    'version': '1.2.7',
    'date': '2026-11-23',
    'title': 'Ekran izleme, gecikme, davet, sohbet başlatma',
    'items': [
      {
        'type': 'fix',
        'text': 'Ekran izleme: kareler sayfayı baştan yüklemeden uygulanır (her karede 5-10 sn kilitlenme ve takılma giderildi); ilk kare sunucuda yoksa widget tam kareyi yeniden gönderir.',
      },
      {
        'type': 'fix',
        'text': 'Pencere odakta değilken (ör. tarayıcıda test ederken) görüşme yoklaması 10 sn\'ye düşüyordu; artık yalnız uygulama gizli/duraklatılmışken yavaşlar.',
      },
      {'type': 'fix', 'text': 'Ekran izleme üst çubuğundaki Yönlendir / Kaydır düğmeleri beyaz çıkıyordu.'},
      {'type': 'fix', 'text': 'Ziyaretçiyi davet et: widget açıkken de davet kartı gösterilir (önce sessizce düşüyordu).'},
      {'type': 'fix', 'text': 'Sohbet başlat: yazılan ilk mesaj artık sohbete düşer ve müşteride widget kendiliğinden açılır.'},
    ],
  },
  {
    'version': '1.2.6',
    'date': '2026-11-23',
    'title': 'Kendi kendine öğrenen asistan',
    'items': [
      {'type': 'new', 'text': 'Yapay zeka asistanı dış servis kullanmadan çalışır: bilgi tabanı ve hazır cevaplardan eşleştirir.'},
      {
        'type': 'new',
        'text': 'Ekibin yanıtlarından, temsilci düzeltmelerinden ve kapanan görüşmelerden öğrenir; "Geçmişten öğren" ile eski görüşmeler taranır.',
      },
      {'type': 'new', 'text': 'Sohbette "Yanıt öner": eşleşme oranıyla birlikte taslak önerir, temsilci düzenleyip gönderir.'},
      {
        'type': 'new',
        'text': 'İsteğe bağlı otomatik yanıt (temsilci yokken / her zaman): öneri ve otomatik yanıt eşikleri ayarlanabilir; eşik altında temsilciye devreder.',
      },
      {
        'type': 'improve',
        'text': 'Ayarlar › Yapay zeka asistanı: bilgi tabanı, onay bekleyen öğrenilenler, günlük ve deneme (eşleşme oranı, kaynaklar); bot devrede göstergesi ve Devral / Bota geri ver.',
      },
      {'type': 'fix', 'text': 'Açılışta "sunucuya ulaşılamıyor" hatası düzeltildi (HTTP/2 bağdaştırıcısı gzip yanıtı açamıyordu).'},
    ],
  },
  {
    'version': '1.2.5',
    'date': '2026-11-23',
    'title': 'Hız, yapıştırma, talep formu, PDF, iptal talebi, ekran kaydırma',
    'items': [
      {'type': 'improve', 'text': 'Uyarlanır yoklama (0,9 / 2,5 / 6 sn) ve gereksiz yeniden çizimlerin kaldırılması: uygulama belirgin hafifledi.'},
      {'type': 'new', 'text': 'Ctrl+V / Cmd+V ile panodaki görsel ve dosyalar ek olarak gider; masaüstünde sürükle-bırak.'},
      {'type': 'improve', 'text': 'Talep formu modalı web ile aynı: Genel destek · Ödeme bildirimi · İptal talebi.'},
      {'type': 'new', 'text': 'Transkript PDF indir, Hizmetler & iptal talebi ekranı, ziyaretçi dili seçimi, görüşme talebi şeridi.'},
      {'type': 'fix', 'text': 'Canlı ekran izleme: kaydırma gerçekten uygulanıyor; "Kaydır" ile temsilcinin kaydırması ziyaretçiye yansır.'},
      {'type': 'fix', 'text': 'Arama: yanıt yoksa 45 sn\'de kapanır, kopan bağlantı yeniden kurulur, kamera/mikrofon kesin bırakılır.'},
      {'type': 'improve', 'text': 'Ziyaretçi bilgisi paneli derli toplu sırada; teknik kimlikler katlanır; olay günlüğü okunur.'},
      {'type': 'fix', 'text': 'Canlı ziyaretçilerde "Davet et": açık sohbeti olan ziyaretçiye davet doğrudan sohbet mesajı olarak düşer.'},
    ],
  },
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
