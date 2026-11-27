/// Yerel uygulamanın (native) sürüm notları — web panelindeki changelog ile aynı zaman çizelgesinde,
/// "Native" rozetiyle gösterilir. En yeni en üstte.
const uygulamaNotlari = <Map<String, dynamic>>[
  {
    'version': '1.2.24',
    'date': '2026-11-27',
    'title': 'Tek dokunuşla sessize al',
    'items': [
      {'type': 'new', 'text': 'Üst çubuğa hoparlör düğmesi eklendi: yeni sohbet ve mesaj sesini tek dokunuşla sessize alır, tekrar dokununca açılır. Tercih bu cihaza özeldir; Ayarlar\'daki "Uygulama açıkken ses" ile aynıdır.'},
      {'type': 'fix', 'text': 'Web panelinde üst çubuktaki ses düğmesi geri getirildi; bekleyen sohbet alarmı sessize alınabilir, ses açılınca bekleyen varsa alarm hemen yeniden çalar (sunucu).'},
    ],
  },
  {
    'version': '1.2.23',
    'date': '2026-11-26',
    'title': 'Destek talebi sayfası kayar',
    'items': [
      {'type': 'fix', 'text': 'Destek talebi karşılama sayfası aşağı kaydırılamıyordu; departman şablonları, Kaydet ve gönderilenler bölümlerine ulaşılamıyordu. Düzeltildi.'},
    ],
  },
  {
    'version': '1.2.22',
    'date': '2026-11-26',
    'title': 'Destek talebi karşılama ayrı sayfada',
    'items': [
      {'type': 'new', 'text': 'Ayarlar menüsüne "Destek talebi karşılama" sayfası eklendi; Butoi\'nin talep karşılama ayarları artık Yapay Zeka sekmeleri içinde değil, kendi sayfasında.'},
      {'type': 'fix', 'text': 'Yapay Zeka ekranındaki sekme çipleri yan yana sığmayınca alt satıra sarar (masaüstünde kaydırma gerekmez).'},
    ],
  },
  {
    'version': '1.2.21',
    'date': '2026-11-26',
    'title': 'Destek talebi karşılama (Butoi)',
    'items': [
      {
        'type': 'new',
        'text': 'Yapay Zeka > "Destek talebi": yanıtsız kalan WHMCS destek taleplerine Butoi adıyla otomatik karşılama yanıtı. Bekleme süresi, yanıt sonrası durum, genel mesaj ve imza, departmana göre şablonlar, kuru çalıştırma ve gönderilenler listesi uygulamadan yönetilir.',
      },
      {'type': 'new', 'text': 'Butoi İngilizce yazan müşteriye İngilizce yanıt verir (sunucu).'},
    ],
  },
  {
    'version': '1.2.20',
    'date': '2026-11-25',
    'title': 'Düzelt kutusu talimat alır',
    'items': [
      {
        'type': 'new',
        'text': 'Eğitim sohbetinde "Düzelt" kutusuna yazılan metin artık talimat/bilgi olarak işlenir; Butoi yanıtı buna göre yeniden yazıp taslak sunar. Metni aynen öğretmek için "Doğrusu: …" ile başlayın.',
      },
      {'type': 'fix', 'text': 'Kısa talimatlar ("…yönlendirebilirsin") ve uzun, "ayrıca" ile birleşik talimatlar yeni soru sanılmaz; tek taslak üretilir.'},
    ],
  },
  {
    'version': '1.2.19',
    'date': '2026-11-25',
    'title': 'Butoi avatarı web ile aynı',
    'items': [
      {
        'type': 'fix',
        'text': 'Butoi maskotu artık web widget\'ı, personel paneli ve eğitim sohbetiyle aynı avatar paketinden (idle, düşünüyor, yazıyor, selamlama, devir, çevrimdışı) gösterilir; elle çizilen eski maskot kaldırıldı.',
      },
    ],
  },
  {
    'version': '1.2.18',
    'date': '2026-11-25',
    'title': 'Butoi avatarı, devralan personel',
    'items': [
      {'type': 'fix', 'text': 'Sohbet ekranında Butoi mesajlarında baş harf yerine Butoi maskotu görünür.'},
      {'type': 'new', 'text': 'Asistan şeridi botu kimin devraldığını gösterir ("Asistan devredildi · Yusuf yanıtlıyor").'},
      {
        'type': 'new',
        'text':
            'Son personel sohbetten ayrılınca Butoi sohbeti geri alır ve bekleyen müşteri mesajını yanıtlar; müşteri "butoi ile devam" derse de geri döner.',
      },
    ],
  },
  {
    'version': '1.2.17',
    'date': '2026-11-25',
    'title': 'Devir zili, Devral katılımı, yasak demetleri',
    'items': [
      {
        'type': 'new',
        'text': 'Butoi "temsilciye aktarıyorum" dediğinde sohbet panelde ve uygulamada yeni istek gibi yeniden çalar; personel katılana kadar bekleyen alarmı sürer.',
      },
      {
        'type': 'fix',
        'text': '"Devral" artık sohbete gerçekten katılır (katılımcı + atama + "sohbete katıldı" olayı) ve sonucu bildirir; personel katılınca/yazınca Butoi düşer, "Bota geri ver" denene kadar susar.',
      },
      {
        'type': 'new',
        'text': 'Yasaklılar: sohbetten verilen IP + ağ bloğu + cihaz + ziyaretçi + e-posta yasakları tek satırda "neyle yasaklandı" çipleriyle; "Hepsini kaldır" ile tek dokunuşta kalkar.',
      },
    ],
  },
  {
    'version': '1.2.16',
    'date': '2026-11-24',
    'title': 'Butoi araştırır, İngilizce öğrenir',
    'items': [
      {
        'type': 'new',
        'text': 'Davranış talimatı: "doğrudan paket öneriyorsun, önce hangi lokasyon lazım sormalısın" → Butoi karşı soru taslağı üretir (seçenekleri kataloğundan çıkarır), "Tamamdır" ile öğrenir.',
      },
      {
        'type': 'new',
        'text': '"Bunların İngilizcelerini de ekle": yerleşik Türkçe-İngilizce sözlükten kategori varyantları ve eş anlamlar; İngilizce sorular ("domain price", "how much is a vps") Türkçe bilgiyle eşleşir.',
      },
      {
        'type': 'new',
        'text': '"X konusunu araştır": etkin bilgi + ticket/sohbetten öğrenilmiş onay bekleyen taslaklar; "hepsini onayla", "2\'yi göster", "1\'i reddet".',
      },
      {'type': 'new', 'text': 'Kapanmış canlı sohbetlerdeki temsilci yanıtlarından günlük otomatik taslak üretimi (Sohbetten etiketi, onay bekler).'},
    ],
  },
  {
    'version': '1.2.15',
    'date': '2026-11-24',
    'title': 'Butoi kendini anlatıyor',
    'items': [
      {
        'type': 'new',
        'text': 'Öz bilgi: "selamlama varyantları neler", "küfür listesinde ne var", "X deyince ne diyorsun", "ne biliyorsun", "kurallar neler", "son öğrendiklerin" sorularını Butoi kendi durumundan yanıtlar.',
      },
      {
        'type': 'new',
        'text':
            'Eşdeğerlik öğretme: "howdy demek selam ile aynı şey", "kutu yani sanal sunucu" ile sözlük ya da eş anlam ekleme; bekleyen soru yeniden denenir.',
      },
      {
        'type': 'fix',
        'text': 'Selam varyantları (selamlar, merhabalar, hello there, good morning…) tanınıyor; "selamlar demek selam ile aynı şey" açıklaması artık yanıt sanılmıyor.',
      },
      {'type': 'improve', 'text': 'Eğitim ekranı ipucu metni yeni sohbet biçimine göre güncellendi.'},
    ],
  },
  {
    'version': '1.2.14',
    'date': '2026-11-24',
    'title': 'Butoi ile sohbet ederek eğitim',
    'items': [
      {
        'type': 'new',
        'text': 'Doğal direktifler: "bunlar küfür: oç, amk" sözlüğe ekler (tam kelime; "koç" sayılmaz), "bunlara şöyle cevap ver: …" yanıtı belirler, "verdiğin cevabı değiştir" alternatif üretir, "tamamdır / bunu geçerli say" onaylar.',
      },
      {
        'type': 'new',
        'text': 'Butoi bilmediğinde "nasıl yanıtlamam gerektiğini yazın" der; bir sonraki serbest cümleniz taslak olur. Noktayla biten düzeltme cümleleri de taslağa dönüşür ("Doğrusu:" zorunlu değil).',
      },
      {
        'type': 'improve',
        'text': 'Yüzde eşleşme etiketi kaldırıldı; yalnız eşleşme bulunamadığında ya da Butoi emin değilken uyarı gösterilir. Kaynak başlıkları yanıt altında.',
      },
      {'type': 'fix', 'text': 'Küfür ve hakarete yanıtsız kalma düzeltildi: yerleşik filtre + öğretilen sözlükle nazik yanıt.'},
    ],
  },
  {
    'version': '1.2.13',
    'date': '2026-11-24',
    'title': 'Butoi RAG öğrenme yapısı',
    'items': [
      {
        'type': 'new',
        'text': 'Konuşarak düzeltme genişledi: "cevabını geliştir", "daha profesyonel", "beğenmedim başka türlü yaz" gibi genel talimatlar anlaşılır; anlaşılmayan talimatta 3 alternatif sunulur, numarası seçilir.',
      },
      {'type': 'new', 'text': 'Eğitim sohbetinde "kural: …" (konuya bağlı) / "genel kural: …" (her yanıt) ve "bilgi ekle: soru = yanıt" komutları.'},
      {
        'type': 'improve',
        'text': 'Sunucu: parçalı RAG arama (BM25 + TF-IDF + eş anlam), bilgi bankası makalelerinde ilgili bölüm + kaynak bağlantısı, takip sorusu bağlamı, araç katmanı (kimlik / onay / bütçe), KVKK maskeleme, kota.',
      },
      {
        'type': 'new',
        'text':
            'Öğrenme kuyruğu: kapanmış ticketlerden her gece onay bekleyen bilgi taslakları ("Ticketten" etiketi, kişisel veri uyarısı). Otomatik yayın yok.',
      },
      {
        'type': 'fix',
        'text': 'Selam gibi kısa sorularda "Böyle öğren" tamamlanmıyordu; öğretilen selamlama yanıtı artık hemen devreye giriyor. Tur sınırında Butoi sessiz kalmak yerine açıkça devrediyor.',
      },
    ],
  },
  {
    'version': '1.2.12',
    'date': '2026-11-24',
    'title': 'Butoi müşteri hizmet akışı',
    'items': [
      {
        'type': 'new',
        'text': 'Butoi, giriş yapmış müşterinin hizmetlerini tanır: erişim sorununda hizmet seçtirir, durumu (BogaVM güç durumu dahil) sorgular, onayla başlat / yeniden başlat yapar, lisans önerisi verir, acil ticket açar, ticket durumunu söyler.',
      },
      {'type': 'improve', 'text': 'Yapay zeka ayarında kip "Yalnız öneri" iken uyarı: Butoi ziyaretçiye yazmaz.'},
      {'type': 'fix', 'text': 'Sohbette uzun mesajlar ekrana sığmıyordu (iç içe Flexible); düzeltildi. Mesaj metni seçilebilir ve kopyalanabilir.'},
      {
        'type': 'improve',
        'text': 'Butoi sohbeti tam ekranda kalan alanı doldurur; Düzelt kutusuna yazılan talimat ("daha kısa yaz") yanıt yerine yeniden yazma taslağı üretir, öğretilen yanıtın öncelik kazandığı doğrulanır.',
      },
      {'type': 'fix', 'text': '"Bota geri ver" artık widget\'ta da Butoi\'yi devreye alır.'},
    ],
  },
  {
    'version': '1.2.11',
    'date': '2026-11-24',
    'title': 'Butoi maskotu ve konuşarak eğitim',
    'items': [
      {'type': 'new', 'text': 'Butoi maskotu (boğa başlı küçük robot) sohbet listesinde, başlıkta ve baloncuklarda; düşünürken hareket eder.'},
      {
        'type': 'new',
        'text': 'Konuşarak düzeltme: "kısalt", "fiyatı ekle", "resmi ol", "madde madde yaz", "\'X\' yerine \'Y\' yaz" gibi talimatlarla Butoi yanıtını yeniden yazar, Evet / Böyle öğren deyince öğrenir.',
      },
      {'type': 'improve', 'text': 'Eğitim sohbetinde düşünüyor › arıyor › yanıtlıyor akışı ve "Nasıl düşündüm?" düşünce izi.'},
    ],
  },
  {
    'version': '1.2.10',
    'date': '2026-11-23',
    'title': 'Butoi sohbetlerde',
    'items': [
      {
        'type': 'new',
        'text': 'Sohbetler listesinin en üstünde sabit "Butoi" girişi: yapay zeka asistanıyla eğitim sohbeti artık doğrudan sohbetlerden açılır (geniş ekranda sağ panelde).',
      },
    ],
  },
  {
    'version': '1.2.9',
    'date': '2026-11-23',
    'title': 'Butoi ve arama düzeltmeleri',
    'items': [
      {
        'type': 'new',
        'text': 'Butoi: yapay zeka asistanı artık WHMCS ürün/paket fiyatlarını, özelliklerini, alan adı ücretlerini, bilgi bankasını ve ödeme yöntemlerini kendisi bilir (her gece senkron).',
      },
      {'type': 'new', 'text': 'Butoi\'yi eğit: Yapay zeka ekranında sohbet ederek eğitim — soru sorun, Düzelt ile doğrusunu öğretin, Doğru ile pekiştirin.'},
      {'type': 'improve', 'text': 'Selamlama, teşekkür ve veda gibi mesajlara Butoi kendisi yanıt üretir.'},
      {'type': 'fix', 'text': 'Yanıt önerisinde "istek başarısız (429)" hatası giderildi.'},
      {
        'type': 'fix',
        'text': 'Sesli/görüntülü aramada arayan personel doğru gösterilir (birincil temsilciyle karışmıyor); sohbete "X arama başlattı" olayı düşer.',
      },
      {'type': 'fix', 'text': 'Sohbete katılan diğer personelin mesajlarında avatarı görünür.'},
    ],
  },
  {
    'version': '1.2.8',
    'date': '2026-11-23',
    'title': 'Rol yetkileri',
    'items': [
      {
        'type': 'fix',
        'text': 'Roller ve yetkiler: tüm yetkilere sahip roller (Yönetici, Süper Yönetici) ve bu rollerdeki personelde kutucuklar boş görünüyordu; artık hepsi işaretli gelir ve kaydedince "tüm yetkiler" korunur.',
      },
      {'type': 'improve', 'text': 'Yetki listesinde her grup için "Tümünü seç / Temizle".'},
    ],
  },
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
