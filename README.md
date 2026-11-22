# Bogahost Chat — uygulamalar

chat.bogahost.com canlı destek panelinin **yerel** (web görünümü değil) temsilci uygulaması. Flutter 3.47 ile tek kod tabanından
iPhone/iPad, Mac, Android ve Windows.

| Platform | Dağıtım | İmza |
|---|---|---|
| iOS | TestFlight → App Store | Apple Distribution (takım X58V6L5247), profil `imza/destek-ios.mobileprovision` |
| macOS | TestFlight (Mac) → Mac App Store | Mac App Distribution + Installer, profil `imza/destek-macos.provisionprofile` |
| Android | GitHub sürümleri (APK) | Kalıcı anahtar (takma ad `bambumpos`) |
| Windows | GitHub sürümleri (Inno Setup + taşınabilir zip) | imzasız |

Paket kimliği: `com.bogahost.destek` · Sunucu API: `https://chat.bogahost.com/api/app/v1` (taşıyıcı jeton, 180 gün).

## Yapı

```
apps/destek/            Uygulama (lib/ekranlar: kabuk, sohbetler, gorusme, ziyaretciler, ekip, bildirimler, ozet, ayarlar)
packages/boga_ortak/    Ortak paket: BogaApi (çerez+CSRF ya da Bearer), giriş+2FA ekranı, açılış, APNs köprüsü, tema
tool/simge/             Simge üretimi (flutter test → tüm platform simgeleri)
imza/                   Sağlama profilleri (gizli değil; sertifikalar GitHub gizlilerinde)
kurulum/                windows.iss, surum-notlari.md, gizlileri-yukle.sh
.github/workflows/      uygulamalar.yml — 4 platform derleme ve yükleme
```

## Geliştirme

```bash
flutter pub get
cd apps/destek && flutter run -d macos     # ya da ios / android / windows
```

Sunucu tarafı (livechat Laravel): `routes/app.php`, `app/Http/Controllers/AppApi/*`, `app/Services/ApnsService.php`,
`app/Http/Middleware/AppTokenAuth.php`. Rota değişikliğinden sonra `route:cache` yenilenir.

## Sürüm çıkarma

`apps/destek/pubspec.yaml` içinde `version:` yükseltilir, `kurulum/surum-notlari.md` güncellenir, `main`e gönderilir.
İş akışı iOS/macOS'u TestFlight'a yükler, Android/Windows paketlerini `surum-<run>` GitHub sürümüne ekler.
