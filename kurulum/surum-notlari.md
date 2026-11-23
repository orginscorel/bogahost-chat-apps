## 1.2.2

- Görünüm boyutu: büyük monitörlerde arayüz otomatik büyür (1500 px üstü %112, 1900 üstü %125, 2300 üstü %135); Ayarlar > Görünüm boyutu ile Oto / 100 / 120 / 140 seçilebilir. Yazı, ikon, düğme ve boşluklar birlikte ölçeklenir.
- Geniş ekranda hiçbir ekran üst çubuktaki durum / zil / tema / profil nesnelerini yinelemez (kabuk içi işaretleme ile; sohbetler sayfası dahil).

## 1.2.1

Üst çubuk, sağdan paneller, gerçek logo, ekran izleme seçici, davet düzeltmesi.
- Geniş ekranda tek üst çubuk: sayfa başlığı · arama kutusu · durum · zil · tema · profil. Ekranlar kendi başlıklarını yinelemez; sıkışık ikonlar gitti. Düğme, çip, sekme ve ikonlar büyütüldü (masaüstünde de standart yoğunluk).
- Detay ekranları (ziyaretçi CRM, profil, bildirim ayarları, menüden açılan ayarlar) geniş ekranda sağdan kayan panelde açılır; telefonda tam sayfa.
- Büyük ekranlarda içerik genişliği sınırlı (1240 px) ve ortalı; sohbet listesi/ekip listesi/bilgi paneli genişliği ekrana göre; sohbet balonları ve yazı büyütüldü (15,5 px, 760 px balon).
- Sohbetler: arama + süzgeç çubuğu yatay kaydırılır, "Hepsini kapalıya al" çubukta. Widget ayarları: iki sütun (form + canlı önizleme), hazır renk paleti, konum/başlık/köşe için bölümlü düğmeler.
- Logo: gerçek Bogahost logosu (boynuzlu boğa başı "o"). Uygulama simgeleri, açılış ekranı ve amblemler yeniden üretildi; açılışta boğa başı kendini çizer.
- Canlı ekran izleme: düğmeye basınca web panelindeki gibi "İzinli co-browse / İzinsiz izle" seçici çıkar.
- Sohbete davet: sunucu daveti widget'a hiç iletmiyordu; artık ziyaretçide temsilci adı ve mesajıyla balon çıkar, tıklayınca sohbet açılır.

## 1.2.0

Web paneliyle aynı düzen; eşit boyda KPI kartları; uyarı/bildirim/istatistik sistemleri.
- Yan menü (geniş ekran): web panelindeki koyu, gruplu menü (Günlük iş / Analiz / Yönetim / Hesap & Yardım). Daraltılmış 74 px, üzerine gelince ya da sabitleyince 248 px; seçili öğe vurgulu + sol çubuk, hover yumuşak; bekleyen sohbet, çevrimiçi ziyaretçi, ekip ve bildirim rozetleri; acil durum/saldırı kırmızı nokta; altta sürüm satırı ve kullanıcı kartı.
- Üst çubuk (her sayfada): genel arama (sohbet, hazır cevap, geçmişte ara), Çevrimiçi / Uzakta / Rahatsız Etme / Çevrimdışı durum menüsü, bildirim zili (okunmamış sayısı, "N sohbet bekliyor", tümünü okundu, hızlı liste), açık/koyu tema anahtarı, profil menüsü (profil, cihazlar, ayarlar, sürüm notları, web paneli, çıkış). Telefonda durum noktası + zil.
- Genel Bakış: uyarı kartı (saldırı modu, acil durum, mesai dışı, bekleyen sohbet, yanıtsız çevrimdışı mesaj, kaçan sohbet, Rahatsız Etme/çevrimdışı durumunuz → "Çevrimiçi ol"), eşit boyda 6 KPI (canlı nokta ile "Şu an sitede"), 6 kısayol, 7 günlük yumuşak alan grafiği (üzerine gelince değer), Müşteri Memnuniyeti halkası + 👍/👎 + yıldız dağılımı, Bekleyen Kuyruğu, Temsilci Performansı, Departman Dağılımı, Son Sohbetler, Ekip.
- Canlı Ziyaretçiler: web ile aynı tablo (Ziyaretçi · Konum · Cihaz · Bulunduğu sayfa · Geliş kaynağı renkli nokta · Son hareket · İşlem), üstte canlı sayaç ve son güncelleme, arama, Tümü/Sohbette/Geziniyor/Yazıyor/Mobil çipleri, 6 sayaç kartı; satırda Sohbete git / Sohbet başlat, davet, ekranı izle, CRM detayı. Telefonda zengin kartlar.
- Bildirim merkezi: okunmamış/sohbet/mesaj/ekip/bugün sayaçları, tür süzgeçleri, Bugün/Dün/Daha eski grupları, tümünü okundu, bildirim ayarları kısayolu. Rahatsız Etme modunda uygulama içi ses ve bant susar.
- Raporlar: renkli SLA paneli (hedef içinde yüzdesi ≥90 yeşil / ≥70 kehribar / altı kırmızı + 6 kart), sohbet+ziyaretçi yumuşak seri grafiği, eşit boyda özet kartları. Geçmiş sohbetler: eşit kartlar, üst çubuk aramasından devralma. Yasaklılar: sayaçlar, arama, tür/durum süzgeçleri, tablo (Tür · Değer · Sebep · Durum · Ekleyen · Tarih · isabet).
- Sürüm notları: "Sistem sürümü · vX" / "Native sürümü · vY" rozetleri, dikey zaman çizelgesi, kaynak rozeti, "En güncel", tür etiketli maddeler.
- Analiz ve yönetim ekranları geniş ekranda kabuk içinde açılır (yan menüden); telefonda Menü sekmesinden.
- Arama: sesli/görüntülü arama düğmeleri ziyaretçi çevrimdışı görünse de gösterilir, durum açıkça sorulur. Sunucu: uygulama girişinde tüm yetki kataloğu gönderilir (ekran izleme, widget, rol yönetimi vb.).

## 1.1.0

Dashboard ve yönetim: uygulama artık web panelinin işlevlerini taşıyor.
- Animasyonlu açılış: kendini çizen Bogahost logosu, canlı destek rozeti; yeni uygulama simgesi ve açılış görseli.
- Özet (pano): canlı/çevrimdışı/kaçan uyarıları, 7 günlük sohbet grafiği, kuyruk, son sohbetler, personel sıralaması, bölüm yükü, puan dağılımı, 4 müsaitlik modu (çevrimiçi / uzakta / rahatsız etme / çevrimdışı).
- Sohbet listesi: durum sekmeleri dar ekrana sığar (sarmalı çipler); Mac/Windows'ta fare ile sürükleyerek kaydırma.
- Görüşme: sesli ve görüntülü arama (WebRTC), ekranı izle (onaylı / onaysız), ziyaretçi detayı/CRM kısayolu.
- Ziyaretçi detayı: oturum ve cihaz bilgisi, UTM, gezinti geçmişi, olaylar, sohbetler, CRM (durum, puan, atama, takip tarihi), notlar, etiketler, yasaklama, davet / sohbet başlat, ekran izleme.
- Ayarlar merkezi (yetkiye göre): Profil ve güvenlik (avatar, parola, 2FA), Bildirimler (push olayları, ses, e-posta, eşikler, test push), Müsaitlik ve çalışma saatlerim, Mesai saatleri (günler, tatiller, çevrimdışı metinleri, karşılama), Widget (canlı önizleme ile görünüm/konum/önizleme/arama), WhatsApp bağlantısı (olay → grup/numara, test), Tetikleyiciler, Hazır yanıtlar, Bölümler, Personel (ekle/düzenle/sil, özel yetkiler), Roller, Erişim engelleri, Yasaklar, Acil durum (arıza duyurusu, saldırı modu), Cihazlar ve oturumlar (uzaktan çıkış), Geçmiş sohbetler (süzgeç + sayfalama), Raporlar (günlük/aylık, SLA, personel, detaylı rapor), Denetim kaydı, Sürüm ve değişiklik günlüğü.
- Sunucu: çevrimdışı mesaj bırakan ziyaretçinin widget'ı, temsilci uygulamadan yanıtlayınca kendiliğinden sohbete döner (45 dk boyunca denetler).
- Mac: kamera ve mikrofon izinleri (arama için).

## 1.0.0

İlk sürüm — Bogahost Chat (iPhone/iPad, Mac, Android, Windows).
- Canlı sohbetler: açık / bekleyen / çevrimdışı / kaçan / kapalı listeleri, arama, okunmamış sayaçları, müşterinin yazdığını önizleme.
- Görüşme: mesajlar ve ekler, hazır yanıtlar (/kısayol), dosya ve görsel gönderme, iç not, katıl / devral / kapat / yeniden aç, transkript e-postası, talep formu.
- Canlı ziyaretçiler: kim hangi sayfada, ülke/cihaz, davet ve sohbet başlatma.
- Ekip: dahili sohbet (ekip kanalı ve kişiye özel), kim çevrimiçi.
- Bildirimler: iPhone/Mac'te APNs ile anlık; uygulama açıkken tüm platformlarda canlı akış.
- Müsaitlik: çevrimiçi / uzakta / rahatsız etme.
