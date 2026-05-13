# Mobilyamevime Mobile Admin

Flutter ile hazirlanan Android/iOS mobil admin uygulamasi.

## API

Tum istekler POST JSON olarak su adrese gider:

```text
https://www.mobilyamevime.com/furnituresnzk/php/mobilyamevimeapp/index.php
```

Token `flutter_secure_storage` icinde saklanir. Token gecersiz veya suresi dolmus kabul edilirse kullanici login ekranina yonlendirilir.

## Kurulum

Bu klasor Flutter kaynak yapisini icerir. Bu calisma ortaminda Flutter SDK bulunmadigi icin `flutter create` komutu calistirilamadi. Flutter SDK kurulu bir makinede platform klasorleri yoksa once su komutu calistir:

```bash
cd mobilyamevime_app
flutter create . --platforms=android,ios
```

Sonra paketleri indir ve uygulamayi calistir:

```bash
cd mobilyamevime_app
flutter pub get
flutter run
```

Android build:

```bash
flutter build apk --release
```

iOS build:

```bash
flutter build ios --release
```

iOS icin macOS ve Xcode gerekir.

## Paketler

- `dio`: API istekleri
- `flutter_riverpod`: state management
- `flutter_secure_storage`: token saklama
- `cached_network_image`: urun gorselleri
- `intl`: para formatlama
- `go_router`: uygulama route yapisi
- `url_launcher`: telefon, e-posta ve fiyat listesi dosyalarini acma
- `flutter_launcher_icons`: Android/iOS app icon uretimi

## Assets

Logo ve app icon dosyalarini su konumlara koy:

```text
assets/images/logo.png
assets/icons/app_icon.png
```

App icon uretmek icin:

```bash
dart run flutter_launcher_icons
```

## Ekranlar

- Login
- Dashboard
- Urun listesi
- Urun detay ve modul listesi
- Tedarikci listesi
- Tedarikci detay ve fiyat listeleri
- Ayarlar / cikis

## Test Sirasi

1. Uygulamayi calistir.
2. Admin kullanici adi ve sifre ile giris yap.
3. Dashboard istatistiklerini kontrol et.
4. Urun listesinden arama ve infinite scroll test et.
5. Urun detayinda gorsel, fiyat, tedarikci ve `modules` listesini kontrol et.
6. Urun detayinda tedarikci adina tiklayip tedarikci detaya gec.
7. Fiyat listeleri sekmesinde dosya acmayi test et.
8. Tedarikci listesini ara.
9. Ayarlar ekranindan cikis yap.
