# Factory Check 1.2.3

Android uygulaması: izleme ekibi, operatör ve destek ekipleri arasında çağrı takibi.

İki cihazlı saha denemesi için [FIELD_TEST.md](FIELD_TEST.md) rehberini kullanın.
Test profilleri ayrı örnek makineler görür ve ekranlarda SAHA TESTİ etiketi taşır.
1.2.2, uygulama öndeyken yeni çağrı uyarısı, bildirim sesi denemesi ve kayıtlı
test geri bildirimi ekler. Devam sırası [ROADMAP.md](ROADMAP.md) içindedir.
1.2.3, çağrı türüne göre hazır nedenler, şirket filtreli makine sorguları ve
emülatörde sınanmış Firestore yetki kurallarını ekler.
Hazırlıkta projede yayımlanmış bildirim işlevi bulunmadığı ve faturalandırmanın
kapalı olduğu doğrulandı; ilk deneme iki uygulama açıkken yapılmalıdır.

## Çalıştırma

Flutter 3.38.5 / Dart 3.10.4 ve Android SDK ile doğrulanmıştır.
Bu depoda Firebase'in yerel yapılandırması ve hesap şifreleri tutulmaz.

```powershell
git clone https://github.com/thetruth2003/factory_app.git
cd factory_app
flutter pub get
```

Uygulamayı kendi Firebase projenizle çalıştırmak için Firebase CLI ve
FlutterFire CLI ile oturum açıp Android yapılandırmasını üretin:

```powershell
dart pub global activate flutterfire_cli
firebase login
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID --platforms=android
```

`lib/firebase_options.dart` ve `android/app/google-services.json` dosyalarının
oluştuğunu kontrol edin. Gerekirse Android JSON dosyasını Firebase konsolundan
indirin. Mevcut kurulumda bu dosyalar bilgisayarda korunmuştur. Yönetim araçları
için `.firebaserc.example` dosyasını `.firebaserc` olarak kopyalayıp proje
kimliğini girin veya `FIREBASE_PROJECT_ID` ortam değişkenini ayarlayın.

```powershell
flutter pub get
flutter run
```

Proje: `C:\Users\alper\StudioProjects\factory_check_app`.

GitHub'a yükleme Firebase'e dağıtım yapmaz. `security/firestore.rules` kuralları
yerelde 15 emülatör testiyle doğrulanmıştır; bu kaynak sürümünün hazırlanması
sırasında canlıya yayımlanmamıştır. Önceki çalışma kapsamında, sahibinin onayıyla
eski iki kullanıcı ve dokuz makinenin eksik şirket alanları tamamlanmıştır.
Yeni kurulumlarda bütün kullanıcı ve makinelere açık `companyId` atanmalıdır.

## Eklenen akış

- Canlı özet, makine listesi, ekip / sorumlu filtresi ve tamamlanan çağrılar.
- Çağrı: açık → üstlenildi → müdahale → sonuçlandırıldı.
- Destek beklerken neden ve ekip seçimi; yeni ekip çağrıyı üstlenebilir.
- Üretim durumu çağrı durumundan ayrıdır. Üretim yeniden başladığında duruş
  sona erer; çağrı notlar tamamlanana kadar açık kalabilir.
- Notlar, olay geçmişi, fotoğraflar ve kayıtlı vardiya devri.
- Vardiya notu, ekip, seçilen açık çağrıların devir anındaki görüntüsü ve teslim
  alan kişinin zaman damgalı kaydı. Operasyon rolüyle teslim alındığında, hâlâ
  devreden kişiye atanmış açık çağrılar teslim alana geçer; kapanan veya başka
  bir kişinin üstlendiği çağrılar değişmez. İzleme rolü yalnızca teslimi onaylar.
- Tarih aralığına göre açılan / kapanan çağrı sayısı, ilk üstlenme ortalaması,
  toplam makine duruşu ve makine bazında döküm. Üst çubuktaki rapor simgesinden açılır.
- Eski dokuz makine krokisine ek olarak bütün makineleri gösteren liste.
- Türkçe / İngilizce / Lehçe ekranlar ve kalıcı dil tercihi.
- Fotoğraf yükleme başarısız olduğunda aynı çağrı üzerinde tekrar deneme.
- Eski şirket kodu girişi ve kişisel e-posta girişi.

## Kullanıcı profilleri

Firebase Authentication hesabının `users/{uid}` kaydı bulunmalıdır:

```json
{
  "companyId": "mevcut-kayitlarla-ayni-sirket-kodu",
  "displayName": "Çalışan adı",
  "role": "operator"
}
```

Roller: `operator`, `watcher`, `maintenance`, `technician`, `quality`,
`warehouse`, `supervisor`, `admin`, `viewer`.

- `watcher`: çağrı açar, not ekler ve izler.
- Operatör ve destek rolleri: çağrı üstlenir ve işlem yapar.
- `supervisor` / `admin`: başka kullanıcıya atanmış çağrıya da müdahale edebilir.
- `viewer` veya tanınmayan roller: salt okunur.
- Kişisel e-posta hesaplarında `companyId` zorunludur.
- Eski `firma@company.local` hesaplarında eksik şirket kodu e-postadan alınır.
  Eski ortak hesapların işlemleri aynı kimliğe yazılır; kişi bazlı kayıt için ayrı
  hesaplar açılmalıdır.
- Profildeki şirket kodu mevcut incident kayıtlarının `createdByCompanyId`
  değeriyle eşleşmelidir.

Bu kontroller istemci davranışıdır. 11 Ekim 2026'da okunan canlı Firestore
kuralı, oturum açmış bütün kullanıcılara bütün belge yollarında okuma/yazma
izni veriyordu; şirket ve rol ayrımını sunucuda uygulamıyor. Storage kuralları
incelenmedi. Üretime geçmeden önce kullanıcı rolü, şirket üyeliği, izin verilen
alanlar ve işlem geçişleri için sunucu kuralları yazılıp test edilmelidir.

## Mevcut verilerle uyumluluk ve sınırlar

Mevcut `machines`, `incidents`, `events`, `photos` koleksiyonları korunur.
Yeni çağrılar `schemaVersion: 3` kullanır. Eski arızalara tahmini duruş süresi
yazılmaz. Yeni kayıtlarda `downtimeSeconds` tamamlanan aralıkların toplamıdır;
`downtimeStartedAt` ve boş `downtimeEndedAt` devam eden aralığı belirtir.

1.2 ile yeni duruşlar `downtime_intervals/{id}` koleksiyonuna çağrı ve makine
güncellemesiyle aynı transaction içinde yazılır. Alanlar: `companyId`,
`incidentId`, `machineId`, `machineKey`, `startAt`, `endAt`. Açık aralığın
kimliği çağrıdaki `activeDowntimeId` alanında tutulur. Üretimin yeniden
başlaması veya çağrının kapatılması o aralığı tamamlar.

Rapor, aralıkları seçilen günlerin başlangıcı ve sonuna göre keser; açık
duruşları şu ana kadar sayar. Günler cihazın yerel saat dilimindedir.
Makinelerin süreleri ayrı ayrı toplanır; eşzamanlı iki makine duruşu iki kez
katkı yapar. Sonuç fabrika genelinin kapalı kalma süresi veya OEE değildir.
İlk üstlenme ortalaması, dönemde açılan ve geçerli `ackAt` zamanı bulunan
çağrıları kullanır; henüz üstlenilmeyen çağrılar sıfır süre kabul edilmez.

Eski kayıtlarda yalnızca zamanı bilinen son duruş aralığı ve sonradan kaydedilen
aralıklar rapora girer. Eski `downtimeSeconds` toplamı günlere dağıtılmaz.
Rapor, dönemle kesişen eski çağrıları eksik geçmiş uyarısıyla gösterir.
Canlı verilerde otomatik dönüşüm yapılmaz. Pilot cihazlarda aynı sürüm
kullanılmalıdır; eski istemciler yeni duruş aralıklarını güncellemez.

Vardiya kayıtları `companies/{companyId}/handovers/{id}` yolundadır.
`shift`, `team`, `notes`, `calls` anlık görüntüsü, `createdByUid/Name/Role`,
`createdAt`, `status`, `acceptedByUid/Name`, `acceptedAt`, `transferredCalls`
alanları tutulur. Kayıt değiştirilemez; düzeltme yeni devir notuyla yapılır.
En fazla 50 açık çağrı seçilir; çağrısız vardiya notu da bırakılabilir.
Kişi kendi devrini teslim alamaz, aynı kişi tekrar teslim aldığında ikinci
kayıt oluşmaz. Teslim alanın rolü hedef ekibe ait olmalıdır; yönetici ve vardiya
sorumlusu tüm ekiplerin devrini alabilir. Ortak hesapla teslim eden ve alan kişiler ayırt edilemez;
bu akış için kişisel kullanıcı hesapları gerekir. Liste 30 kayıt gösterir,
"Daha fazla göster" ile geçmiş kayıtlar yüklenir.

**Yeni yollar için canlı Firestore kuralları ayrıca hazırlanıp doğrulanmalıdır.**
Şirket kapsamındaki okuma, rol kontrolü, vardiya kaydının değiştirilemezliği,
tek alıcı tarafından kabul, sorumluluk aktarımı ve duruş aralıklarının ilgili
çağrıyla tutarlılığı sunucuda doğrulanmadan ticari kullanıma hazır sayılmaz.
Bu depoda canlı güvenlik kuralları yoktur ve bu güncellemede dağıtım yapılmadı.

Her makine için tek aktif çağrı politikası korunur. Tekrar bildirim aktif çağrıyı
açar; ek bilgi not olarak yazılabilir. Bağımsız birden çok arıza desteği henüz yok.

Mevcut tek fabrika verileriyle uyumluluk için şirket alanı olmayan makine
kayıtları görünür. Bu yapı çok şirketli ticari kullanım için yeterli izolasyon
sağlamaz. Böyle bir kullanımdan önce makineler şirketlere bağlanmalı, sorgular
şirkete göre daraltılmalı ve sunucu kuralları birlikte uygulanmalıdır.

Çevrimdışı önbellek görünür biçimde işaretlenir. Transaction ile yapılan çağrı
işlemleri internet gerektirir; kalıcı çevrimdışı gönderim kuyruğu henüz yoktur.
Fotoğraf tekrar deneme bilgisi açık form oturumu boyunca korunur.

Web panosu, rapor dışa aktarma, otomatik eskalasyon, cihaz / kamera entegrasyonu
ve tam planlı bakım bu sürümde yoktur. Vardiya devri için ayrı push bildirimi
henüz yoktur; teslim bekleyen kayıtlar uygulamadaki vardiya ekranında görünür.
Çağrı listesi ve rapor şirketin çağrı / duruş kayıtlarını canlı dinler; büyük
veri hacmi için ayrıca sayfalama ve sunucu tarafı özetleme gerekir.

## Bildirimler

`functions/index.js` Firebase Functions v1 API'sini açıkça içe aktarır.
Kaynakta yeni çağrı, durum değişikliği, ekip değişikliği ve üretim durumu
değişikliği için bildirim vardır. Bildirime dokunmak ilgili çağrıyı açar.
Çıkışta abonelik temizlenir; başarısız abonelik temizliği sonraki girişte
yeniden denenir.

Cloud Functions değişiklikleri bu çalışma sırasında yayımlanmamıştır.
Mevcut proje üzerinde kontrollü dağıtım ve iki gerçek cihazla bildirim testi
gereklidir. Topic abonelikleri yetkilendirme sınırı değildir; hassas not ve
fotoğraflar bildirim gövdesine konulmaz.

## Kontroller

Firebase hesabı olmadan yerel widget testleri için örnek yapılandırmayı kopyalayın
(bu dosya uygulamayı gerçek Firebase'e bağlamaz):

```powershell
Copy-Item lib/firebase_options.example.dart lib/firebase_options.dart
flutter pub get
```

Mevcut gerçek yapılandırmanız varsa üzerine örneği kopyalamayın.

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

```powershell
cd functions
npm run lint
npm test
```

Servis testleri sahte Firestore ile iş kurallarını ve işlem sonuçlarını sınar;
gerçek Firestore çakışma tekrarlarını, sunucu güvenlik kurallarını veya FCM
teslimatını kanıtlamaz. Widget testleri giriş, liste ve çağrı üstlenme akışını
kontrol eder. Vardiya servis ve ekran testleri oluşturma, teslim alma,
sorumluluk aktarımı ve eski kaydın korunmasını sınar. Rapor testleri gece
yarısını aşan ve devam eden duruşları, çoklu aralıkları, ilk üstlenme örneklerini
ve eksik eski geçmişi kapsar. Functions testleri dışarıya bildirim göndermez.

Güvenlik kuralları için Node.js ve Java 21 gerekir:

```powershell
npm --prefix security ci
firebase emulators:exec --only firestore --project demo-factory-check --config security/firebase.json "node --test --test-concurrency=1 security/firestore.test.cjs"
```

Emülatör yalnızca `127.0.0.1` üzerinde çalışır; canlı Firebase'e bağlanmaz.
Testler şirket ayrımı, rol değiştirme yasağı, işlem geçişleri, sahiplik,
olay kayıtları, altı çağrılık vardiya devri ve eski çağrılarla uyumluluğu kapsar.
Son doğrulama: 61 Flutter testi, 15 güvenlik testi, temiz `flutter analyze` ve
başarılı debug APK derlemesi.

Yönetim araçları `tool/` altındadır. `prepare_company_access.cjs` için
`company_access.example.json` dosyasını `company_access.local.json` olarak
kopyalayıp doğrulanmış eşleştirmeleri girin. Önce parametresiz önizlemeyi
inceleyin; `--apply` canlı veride değişiklik yapar ve önce yerel yedek alır.

## Yedek

Güncelleme öncesi kaynak yedeği:

`C:\Users\alper\StudioProjects\factory_check_app_backups\before-update-20261011-031914.zip`

1.2 geliştirmesinden önce alınan 1.1 kaynak yedeği:

`C:\Users\alper\StudioProjects\factory_check_app_backups\before-v12-20261011-034748.zip`

Üretilen debug APK: `build/app/outputs/flutter-apk/app-debug.apk`.
