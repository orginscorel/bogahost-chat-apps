## 1.2.23 (26 Kas 2026)
- Düzeltme: Destek talebi karşılama gövdesi `ListView` (AyarSayfa gövdeyi kaydırmaz; Column ile alt bölümlere ulaşılamıyordu).

## 1.2.22 (26 Kas 2026)
- Yeni: Ayarlar > "Destek talebi karşılama" ayrı sayfa (`lib/ekranlar/ayar/destek_talebi.dart`, `DestekTalebiEkrani`); Yapay Zeka ekranındaki sekme kaldırıldı.
- Düzeltme: Yapay Zeka sekme çipleri `Wrap` ile sarar (yatay kaydırma masaüstünde çalışmıyordu).

## 1.2.21 (26 Kas 2026)
- Yeni: Yapay Zeka > "Destek talebi" sekmesi — Butoi destek talebi otomatik karşılama (sunucu `TicketOtoYanitServis`, panel API `ai/ticket`, `ai/ticket/kuru`, `ai/ticket/gecmis`). Eski task `ticket_auto_reply` mantığı; yanıt WHMCS'te "Butoi" adıyla görünür, departman şablonları, yer tutucular {isim_ek} {tid} {konu} {departman}.
- Sunucu: Butoi İngilizce sorulara İngilizce yanıt (AiService::dilTespit, AiOrkestra dil parametresi, yerel yanıt çevirisi).

## 1.2.20 (25 Kas 2026)
- Yeni: Düzelt kutusu = talimat/bilgi (sunucu `AiService::egitimOgret` → `talimatTaslagi`, Claude katmanı; mevcut yanıta %60+ benzer metin ya da "Doğrusu: …" aynen öğretilir). Uygulamada kutu boş açılır, etiket "Talimat ya da bilgi", düğme "Yeniden yaz".
- Sunucu: `serbestTalimat` 4+ kelime ve -ebilirsin/-malısın kalıplarını tanır; 24+ kelimelik talimatlar "ayrıca" ile bölünmez; butoi-claude sarmalayıcısı `--max-turns 2` (error_max_turns düzeltmesi).

## 1.2.19 (25 Kas 2026)
- Düzeltme: Butoi maskotu web widget'ı, personel paneli ve eğitim sohbetiyle aynı avatar paketinden gösterilir (assets/butoi/*.png ← livechat/public/img/butoi/circle/static/*.svg, rsvg-convert 256px). Elle çizilen maskot kaldırıldı; `ButoiMaskot(durum: 'typing' | 'handoff' | …)` ile durum seçilebilir.

## 1.2.18 (25 Kas 2026)
- Düzeltme: sohbet ekranında Butoi mesajlarında "B" baş harfi yerine Butoi maskotu.
- Yeni: asistan şeridi botu devralan personelin adını gösterir (meta.ai_handoff_by).
- Sunucu: son personel ayrılınca Butoi sohbeti geri alır; "butoi ile devam" isteği bota döner; temsilci bekleyen zili personel sohbetteyken susar.

## 1.2.17 (25 Kasım 2026)
- Yeni: Butoi devrettiğinde sohbet yeniden çalar (panel `handoffs` + bekleyen alarmı `Conversation::temsilciBekleyen`); devir olay satırı müşteri/panelde görünür.
- Düzeltme: "Devral" sohbete katılır (AiController::handoff → join) ve sonucu bildirir; join/takeover/reply → `AiService::insanDevraldi` (bot düşer).
- Yeni: Yasaklılar demet görünümü (BanController::demetler, `groups`); DELETE bans/{id} demetin tamamını kaldırır.

## 1.2.16 (24 Kasım 2026)
- Yeni: Davranış talimatı ("önce hangi lokasyon lazım sor") → karşı soru taslağı.
- Yeni: "Bunların İngilizcelerini de ekle" (yerleşik TR-EN sözlük); İngilizce sorular Türkçe bilgiyle eşleşir.
- Yeni: "X konusunu araştır" + sohbet içinden taslak onayı.
- Yeni: Kapanmış sohbetlerdeki temsilci yanıtlarından günlük taslak üretimi.

## 1.2.15 (24 Kasım 2026)
- Yeni: Öz bilgi soruları ("selamlama varyantları neler", "X deyince ne diyorsun", "ne biliyorsun", "kurallar neler", "son öğrendiklerin").
- Yeni: Eşdeğerlik öğretme ("howdy demek selam ile aynı şey", "kutu yani sanal sunucu").
- Düzeltme: Selam varyantları tanınıyor; açıklama cümleleri yanıt sanılmıyor.
- İyileştirme: Eğitim ekranı ipucu metni.

## 1.2.14

- Sunucu: `AiService::niyetTam` (type=lexicon sözlük + Profanity::has, kelime sınırı), `sozlukEkle`, `niyetYanitiKaydet`, eğitim direktifleri (liste öğretme, "bunlara şöyle cevap ver", geniş onay sözcükleri, await/bildirim taslağı, taslaksız onay uyarısı), meta.nomatch/await. Web+uygulama: skor rozeti yalnız eşleşme yok / emin değilim.

## 1.2.13

- Sunucu: `AiAraclar` (araç katmanı, `ai_tool_calls`), `AiKoruma` (maskeleme, kota), RAG parçalı dizin (`parcala`, BM25, `config/ai_esanlam.php`, `yanitMetni`), `ai:ogren` komutu (04:40 cron) + köprü `closed_tickets_since`, `ai_knowledge.url/origin/pii_checked`, type=rule kurallar, `intent_replies`. Widget: `ui.kind=sources` kaynak satırı. Uygulama: `_talimat` sözlüğü genişledi.

## 1.2.12

- Sunucu: `app/Services/ButoiHizmet.php` (hizmet akışı), köprü `client_services/service_status/service_power/client_tickets/open_ticket`, imzalı kimlik (`includes/hooks/livechat_user_sig.php` + `bridge_secret.php`), `messages.ui`, `visitors.whmcs_verified_at`. Uygulama: kip uyarısı.

## 1.2.11

- `lib/ortak/maskot.dart` ButoiMaskot (CustomPainter; dusunuyor/mutlu). Eğitim sohbeti: `_dusunerek` faz akışı, taslak (meta.draft) için Böyle öğren / Vazgeç, meta.steps düşünce izi. Sunucu: `AiService::yenidenYaz` kural tabanlı talimat motoru, `talimatMi`, taslak onayı (evet/vazgeç). Web: public/img/butoi.svg.

## 1.2.10

- Sohbetler listesinin tepesinde sabit Butoi girişi (`_butoiSatiri`, secilenSohbet = -1 → `ButoiSohbetEkrani` gömülü). Web: chats listesinin tepesinde admin/ai#train bağlantısı.

## 1.2.9

- Butoi (yapay zeka): WHMCS köprüsü `ai_catalog` ile ürün/fiyat/alan adı/bilgi bankası/ödeme yöntemleri `ai_knowledge` (source=system, ext_key) olarak senkronlanır (gece 05:15 + elle). Eğitim sohbeti (`panel/ai/train*`), küçük konuşma üretimi (selam/teşekkür/veda), adlı throttle sayaçları (429 düzeltmesi).
- Arama: `CallService` arayan kimliğini saklar; widget arayanın adını/avatarını gösterir; sohbete olay mesajı düşer.
- Mesajlarda `avatar` alanı (mutlak URL); diğer personelin baloncuğunda `KisiAvatar`.

## 1.2.8

- Roller ve yetkiler: `*` (tüm yetkiler) içeren roller ve bu rollerdeki personelin yetki ekranında kutucuklar boş görünüyordu; `*` kataloğun tamamına açılır, hepsi seçili kaldıysa kaydedilirken `*` olarak korunur. Rol listesinde "tüm yetki" yazar. Grup başlığında Tümünü seç / Temizle.

## 1.2.7

- Ekran izleme: kareler web görünümünü baştan yüklemeden (DOM değişimiyle) uygulanır; yoklama kare yüklenmesini beklemez, kareler birleşir. Her karede 5-10 sn kilitlenme ve takılma giderildi. Widget, sunucu "need_html" derse ya da her 10 sn'de tam kareyi yeniden gönderir (ilk karenin boş gelmesi düzeltildi).
- Görüşme yoklaması: masaüstünde pencere odakta değilken (inactive) artık yavaşlamaz; yalnız paused/hidden'da 10 sn.
- Ekran izleme üst çubuğu Yönlendir / Kaydır düğmeleri kendi çizimiyle (tema beyaza çeviriyordu).
- Sunucu: ziyaretçi daveti widget açıkken panel içinde kart olarak gösterilir; "Sohbet başlat" ilk mesajı temsilci mesajı olarak kaydeder (widget müşteride kendiliğinden açılır).

## 1.2.6

- Yapay zeka asistanı artık dış servis (API anahtarı, model) kullanmaz: kendi kendine öğrenen iç motor, ziyaretçi sorusunu anahtar kelime / TF-IDF benzerliğiyle bilgi tabanı ve hazır cevaplarla eşleştirir.
- Öğrenme: ekibin yanıtlarından, temsilci düzeltmelerinden ve kapanan görüşmelerden soru → yanıt çiftleri çıkarır; onaylı ya da "onaysız etkinleştir" açıksa doğrudan; aynı soru tekrar sayısı kadar görülürse kendiliğinden etkinleşir. "Geçmişten öğren" (gün / en çok görüşme) eski görüşmeleri tarar.
- Sohbet yazım kutusunda "Yanıt öner": eşleşen yanıtı taslak olarak koyar ("Öneri eklendi (%NN eşleşme)"); temsilci düzenleyip gönderir, fark öğrenme için sunucuya bildirilir.
- İsteğe bağlı otomatik yanıt: kip (yalnız öneri · temsilci yokken · her zaman), öneri eşiği ve otomatik yanıt eşiği (%5-100), devir cümlesi, devir kelimeleri, en çok bot turu, karşılama.
- Ayarlar › Yapay zeka asistanı (settings.manage): 30 günlük özet (öğrenilen, hazır cevaplar, ortalama eşleşme, otomatik yanıt, öneri kabul); bilgi tabanı (görülme sayısı, ağırlık); onay bekleyenler; günlük (eşleşme oranı, sonuç); deneme (eşleşme oranı, otomatik yanıtlanır / devredilir, kaynaklar).
- Görüşmede bot göstergesi: "Asistan yanıtlıyor" + Devral, devredilmişse "Bota geri ver".
- Düzeltme: açılışta "sunucuya ulaşılamıyor" hatası giderildi (HTTP/2 bağdaştırıcısı gzip yanıtı açamıyordu).

## 1.2.5

- Sohbet yoklaması web paneliyle aynı uyarlanır düzene geçti: hareket varken 0,9 sn, 3 dk'ya kadar 2,5 sn, sonra 6 sn, pencere arkadayken 10 sn; yoklama 8 sn alma zaman aşımı ve ekran kapanınca iptal ile çalışır (takılan tek istek görüşmeyi dondurmuyor).
- Performans: görünür bir şey değişmediyse görüşme, sohbet listesi ve yan menü rozetleri yeniden çizilmiyor; balonlar anahtarlı; balon başına SelectableText yerine masaüstünde tek seçim alanı; görsel önizlemeler küçük boyutta çözülüyor; okundu bilgisi JSON'u yeniden çözmeden güncelleniyor; HTTP istekleri gzip; ölçekli arayüzde RepaintBoundary.
- Ctrl+V / Cmd+V ile panodaki görsel ya da dosya doğrudan ek olarak gönderilir (metin yapıştırma aynen sürer); masaüstünde sohbete dosya sürükle-bırak.
- Talep formu modalı web ile aynı: Genel destek (birim seçimi, varsayılan otomatik) · Ödeme bildirimi (muhasebe) · İptal talebi (yalnız WHMCS müşterisi + yetki); kısa not isteğe bağlı.
- Yeni: Transkript "PDF indir" (masaüstünde farklı kaydet, telefonda aç); "Hizmetler & iptal talebi" ekranı (WHMCS hizmet listesi, çift onaylı gerçek iptal talebi); ziyaretçi dili / çeviri seçimi; ziyaretçinin sesli / görüntülü / ekran talebi için Başlat · Yoksay şeridi; önemli/arşiv/kaçan durumları sohbet detayından okunur.
- Canlı ekran izleme: JavaScript açık ve temizlenmiş kare (betik yok), kaydırma konumu gerçekten uygulanıyor; "Kaydır" ile temsilci sayfayı kaydırır ve bu ziyaretçinin tarayıcısına yansır; sona eren / reddedilen paylaşımda yoklama durur; sayfa değişince kare yeniden yüklenir; ilk kare denetleyiciden önce gelirse kaybolmuyor.
- Arama: yoklama üst üste binmiyor, ICE adayları sıralı gönderiliyor, 45 sn yanıt yoksa kapanır, kopan bağlantıda ICE yeniden başlatma (2 deneme), kapanışta kamera/mikrofon kesin bırakılır; durum metinleri sadeleşti. iOS izin açıklamaları bu uygulamaya göre yazıldı.
- Ziyaretçi bilgisi paneli toparlandı: Şu an → atama → bu sohbet → müşteri → ağ & cihaz → kaynak → teknik ayrıntılar (katlanır) → gezinti (8 + tümünü göster) → olay günlüğü (okunur) → geçmiş; yasaklama en altta.
- Sunucu: davet, ziyaretçinin açık sohbeti varsa doğrudan sohbet mesajı olarak gider (widget açıkken/paylaşımda davet balonu görünmüyordu); temsilci başlatmalı sohbet 15 sn yerine sinyalle 3-6 sn'de widget'a düşer; SSE havuz sınırı gerçekten uygulanıyor; widget 429/5xx'te geri çekilir; ekran paylaşımı sayfa geçişinde sürer; izleme kalp atışı 30 sn.

## 1.2.4

- Yan menü uygulamanın ilk renk stiline döndü: tema kartı zemini + kenar (açık/koyu temaya uyar), seçili öğe yumuşak mor zemin + mor simge/yazı; koyu sabit (#12151D) zemin kaldırıldı.
- Büyük monitörde otomatik ölçek yumuşatıldı: 1500 px üstü %106, 1900 üstü %112, 2300 üstü %120 (önceki %112/%125/%135 fazla büyütüyordu).
- Ölçekli arayüzde logo yazı görseli yüksek örnekleme ile çizilir (pikselli görünüm giderildi).

## 1.2.3

- KPI kartları (pano, ziyaretçiler, bildirimler, raporlar, geçmiş): içerik sığmazsa taşmak yerine orantılı küçülür; büyük kart düzeni sıkılaştırıldı (36 px rozet, 26 px değer), pano hücresi 132 px. Yazı ölçeği 1.6'ya kadar taşma testi eklendi.
- Simge seti: varsayılan ağırlık Light → Regular (daha dolgun ve net); yan menüde etkin bölümün simgesi dolu (Fill) çizilir.
- Tablolar: Canlı Ziyaretçiler'de "Son hareket" (118 px) ve "İşlem" (236 px) sütunları sabit, metin sütunları esnek; dar pencerede tablo en az 1180 px olup yatay kaydırılır. Yasaklılar tablosunda işlem sütunu sabit (52 px). Tablo başlığı sabit genişlikli sütun destekler.

## 1.2.2

- Görünüm boyutu: büyük monitörlerde arayüz otomatik büyür (1500 px üstü %112, 1900 üstü %125, 2300 üstü %135); Ayarlar > Görünüm boyutu ile Oto / 100 / 120 / 140 seçilebilir. Yazı, ikon, düğme ve boşluklar birlikte ölçeklenir.
- Düzeltme (build 11): ölçek sarmalayıcısında içerik pencere boyutunda yerleşip büyütülüyor, açılış dahil her şey taşıyordu; artık küçültülmüş mantıksal boyutta yerleşir (OverflowBox), regresyon testi eklendi.
- Geniş ekranda hiçbir ekran üst çubuktaki durum / zil / tema / profil nesnelerini yinelemez (kabuk içi işaretleme ile; sohbetler sayfası dahil).
- Sohbetler: sol listede süzgeç çipleri (Açık/Bekleyen/Kaçan/Çevrimdışı/Kapalı) artık sarılır, hepsi görünür; liste geniş ekranda 480 px'e kadar; mesaj sütunu ve yazım kutusu en çok 1180 px ortalanır (uçsuz bucaksız genişlik yok).
- Sayfa içeriği büyük ekranda daha geniş: genel 1600 px, ziyaretçi tablosu 1900 px, ayar sayfaları 1400 px.
- Sohbet ekranı sağ blok (Ziyaretçi bilgileri) web paneliyle aynı kapsamda yeniden yazıldı: bayrak + ad, e-posta/telefon, ziyaret/sohbet sayıları, WHMCS ID (müşteri kaydına bağlantı), müşteri adayı durumu; **Ziyaretçiyi yasakla** (IP · IP bloğu /24 /16 · cihaz parmak izi · ziyaretçi kimliği · e-posta · tam yasak; sebep + süre) ve **Tüm yasakları kaldır** / tek tek kaldır; atama; şu anki sayfa + yazıyor; iletişim & kimlik (kalıcı kimlik, sohbet dili); ağ & cihaz (IP, port, işletim sistemi, tarayıcı, cihaz, ekran, dil, saat dilimi + ziyaretçinin yerel saati, parmak izi, tarayıcı kimliği); konum; oturum (başlangıç, son hareket, sayfa sayısı); kaynak + UTM; bu sohbet (departman, temsilci, katılımcılar, değerlendirme); sayfa gezinti geçmişi (50); olay günlüğü; geçmiş görüşmeler (tıklayınca açılır); CRM detayı ve ekran izleme kısayolları. Panel geniş ekranda 340–460 px.
- Uygulama simgesi posta uygulamalarıyla aynı aileye döndü: kurumsal amblem (boynuzlu taç + üç sunucu sütunu) + yeşil sohbet rozeti (packages/boga_ortak BogaAmblem; uygulama içi logo boğa başı olarak kalır).
- Sunucu: `panel/chats/{id}/visitor` ucu ve `chats/{id}/ban` / `unban` rotaları uygulama API'sine eklendi (yedek /root/backups/chat-sohbet-ziyaretci-20261123).

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
