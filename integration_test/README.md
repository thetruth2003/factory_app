# Android vardiya akış testi

Bu test gerçek Flutter ekranlarını ve Android Firebase SDK'sını, yerel Auth ve
Firestore emülatörlerine bağlar. `demo-factory-check` isimli ayrı Firebase uygulaması
kullanılır; mevcut üretim oturumu ve fabrika verileri kullanılmaz.

Önce Android Studio'dan bir Android emülatörü açın. Flutter, Node.js, Firebase CLI
ve Java 21 komutları PATH üzerinde bulunmalıdır. Proje kökünde:

```powershell
flutter pub get
firebase emulators:exec --only "auth,firestore" --project demo-factory-check --config security/firebase.json "powershell -NoProfile -ExecutionPolicy Bypass -File tool/test_roster_android.ps1"
```

Varsayılan cihaz `emulator-5554`; başka cihaz için scriptin sonuna `-Device ID`
eklenebilir. Script Windows'un standart `%LOCALAPPDATA%/Android/sdk` konumunu
kullanır. Sunucular yalnızca `127.0.0.1` üzerinde dinler; `adb reverse` bağlantıları
test sonunda kaldırılır. İlk çalıştırmada Firebase emülatörlerini indirmek için
internet gerekebilir. Test hesaplarının sabit parolası sadece yerel emülatör içindir.

Akış: adminle vardiya planlama → operatörle gün sonu raporu ve önemli ekip notu →
diğer operatörün ana ekranında notu görmesi ve Okudum → adminin raporu ve okuyanları
görmesi. Çalışanın personel listesine/gelecek haftaya erişimi, başka ekibin ve başka
şirketin vardiya belgesine erişimi de sınanır. Bunlar sahadaki iki ayrı cihazın
gecikme veya kilitli telefon bildirimi testi değildir.

Test Android'e geçici bir test giriş noktası kurar. Sonrasında normal uygulamaya
dönmek için `flutter run` kullanın veya önceden üretilmiş normal APK'yı yeniden
kurun. Test APK'sını kullanıcılara dağıtmayın.
