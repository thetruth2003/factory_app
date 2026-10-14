# İki cihazla saha denemesi — Factory Check 1.3.0

Amaç: İzleme çalışanı ile operatörün uygulama üzerinden çağrı açıp sonuçlandırmayı
denemesi ve akışın sahada anlaşılır olup olmadığını öğrenmek.

## Kurulum

İki Android cihaza da bu bilgisayarda hazırlanmış `FactoryCheck-1.3.0-vardiya.apk` dosyasını kurun.
Bu, test için debug paketidir. İki cihazın da internete erişmesi gerekir.
Paketi yeniden üretmek için `flutter build apk --debug --no-pub` kullanın;
ardından `build/app/outputs/flutter-apk/app-debug.apk` dosyasını kurabilirsiniz.
Android entegrasyon testi aynı çıktı dosyasını test uygulamasıyla değiştirebilir;
testten sonra yeniden normal derleme yapmadan bu çıktıyı dağıtmayın.

| Cihaz | Giriş | Şifre | Rol |
|---|---|---|---|
| İzleme çalışanının cihazı | `testizleme` | Yerel kurulum şifresi | Çağrı açma, not ekleme, izleme |
| Operatörün cihazı | `testoperator` | Yerel kurulum şifresi | Üstlenme, müdahale, sonuçlandırma |
| Takvim denemesinde yönetici | `testadmin` | Yerel kurulum şifresi | Çalışan listesi, bütün tarihler, plan ve raporlar |
| Takvim denemesinde ikinci operatör | `testoperator2` | Yerel kurulum şifresi | Kendi ekip planı, devir notu ve Okudum |

Test şifreleri depoya konmaz. Bu bilgisayardaki `FIELD_TEST_CREDENTIALS.local.md`
dosyasında saklanır; başka bir kurulumda hesapları hazırlayan kişiden alın.

E-posta biçimleri `testizleme@company.local` ve `testoperator@company.local` da
kullanılabilir. Eski `admin` hesabı mevcut fabrika kayıtlarına bağlıdır; bu
deneme için yukarıdaki test hesaplarını kullanın. Takvim yöneticisi **testadmin** hesabıdır.

Girişten sonra iki cihazda da **SAHA TESTİ** etiketi ve yalnızca üç örnek makine
görünmeli: TEST-1 Paketleme, TEST-2 Pişirme, TEST-3 Soğutma. Bu adlar gerçek
makinelerle eşleştirilmiş değildir.

## Yaklaşık 15 dakikalık ilk deneme

1. İki cihazda da uygulamayı açık tutun. Ana ekrandaki **Bildirim sesi dene**
   düğmesini kullanın. İzin sorulursa izin verin. Ses yoksa Android bildirim
   sesi, Factory Check bildirim kanalı ve Rahatsız Etmeyin ayarını kontrol edin.
2. İzleme hesabı: Makineler → TEST-1 → Çağrı oluştur. Açıklama olarak
   “DENEME — paketleme filmi sıkıştı” yazın, ekip Operatör, üretim durumu
   Üretim durdu seçin.
3. Operatör: **Yeni çağrı** uyarısını ve sesi kontrol edin. Uyarıdaki
   **Çağrıyı aç** düğmesine dokunun; “Gördüm, üstlen” ve
   ardından “Müdahaleye başla” düğmelerini kullanın.
4. İzleme cihazında yeni sorumlu ve durumun göründüğünü kontrol edin.
5. Operatör: “Üretim yeniden başladı” ile duruşu bitirin. Çağrı açık kalabilir.
   Ardından “Sonuçlandır”, “Deneme tamamlandı” notu ve üretim çalışıyor
   onayıyla kapatın. Örnek makinede gerçek işlem yapılması gerekmez.
6. İki cihazda Geçmiş ve Raporlar ekranına bakın. TEST-1 artık yeni çağrıya
   uygun olmalı; duruş toplamı, çağrının bütün açık kalma süresiyle karışmamalı.
7. TEST-2 için işlemi tekrarlayın. İsterseniz fotoğraf eklemeyi ayrı deneyin;
   depolama izinleri bu kontrolün parçasıdır.
8. İki çalışan da ana ekrandaki **Test geri bildirimi** ile kolaylığa 1–5 puan
   versin, zorlandığı adımı veya önerisini yazıp kaydetsin. Başarı mesajını
   görmeden kaydedildiğini kabul etmeyin. Kayıt çalışanın adı ve rolünü içerir.

Yeni çağrı uyarısı, uygulama öndeyken ilgili hedef ekibe gelir. İzleme ve
sorumlu roller bütün ekiplerdeki yeni çağrıları görür. Kendi açtığınız çağrı,
girişte mevcut olan çağrılar, aynı kaydın tekrar gelmesi ve durum değişiklikleri
bu yerel uyarıyı tetiklemez. Çevrimdışı önbellek sunucu onayı sayılmaz.
Birden fazla yeni çağrı aynı anda gelirse tek toplu uyarı görünür; düğme bu
gruptaki bir çağrıyı açar, diğerleri listede kalır. Uyarı kaydı üstlenmez.

İzleme ve operatör farklı ekipler olduğu için birbirlerinin vardiya devrini
teslim alamazlar. Aynı ekip içinde vardiya teslim alma denemesi için ayrıca
aynı rolde ikinci kişisel hesap gerekir; bunun için `testoperator2` hazırdır.
Yeni takvimdeki ekip notları da kendi ekibine görünür: operatör notunu
`testoperator2` okuyabilir, `testizleme` okuyamaz.

## İki cihazla vardiya ve rapor denemesi

15 Ekim 2026 hazırlığında **14, 15 ve 16 Ekim** için dokuz örnek vardiya eklendi.
Her gün Test Operatör ve Test İzleme 00:00–08:00, Test Operatör 2 08:00–16:00
planlıdır; bütün saatler Polonya saatidir. Bunlar deneme saatleridir; admin
uygulamadan değiştirebilir. Başka gün deneyecekseniz admin o güne yeni plan ekler.

1. Birinci cihazda `testadmin`, ikinci cihazda `testoperator` ile giriş yapın.
   Admin takvimde üç planlı çalışanı ve çalışan listesinde dört aktif hesabı görmeli.
   Operatör ise kendi haftasında yalnızca iki operatörün planlarını görmeli.
2. Operatör, bugünkü kendi vardiyasını açıp bir gün sonu raporu yazsın.
   Kaydedilen rapor adminin aynı vardiya kartında görünmeli.
3. Operatör **Devir notu bırak** ile Bugün ve Önemli seçip
   “DENEME — paketleme sensörünü kontrol et” yazsın.
4. Birinci cihazda adminden çıkıp `testoperator2` ile girin. Ana ekranda notu
   görüp **Okudum** deyin. İkinci cihazdaki yazar okundu kaydını görmeli.
5. Yarın için ayrı not bırakın. Yarın seçiliyken takvimde görünmeli;
   ertesi gün ana ekranda da görünür. Adminle tekrar girip raporu ve okuyanları inceleyin.

Rapor başlangıçtan vardiya bitişinin 24 saat sonrasına kadar yazılabilir.
İkinci operatörün kendi raporunu denemek için 08:00'i bekleyin veya adminle
henüz rapor yazılmamış planın saatini değiştirin. Raporlar sonradan değişmez.

## Mevcut sınır: arka plan bildirimi

Hazırlık sırasında Firebase projesinde yayımlanmış Cloud Function bulunmadığı,
faturalandırmanın kapalı olduğu doğrulandı. Çağrı listeleri uygulama açıkken
Firestore üzerinden güncellenir; telefon kilitliyken veya uygulama arka
plandayken push bildirimlerinin gelmesi bu paketle garanti edilmez.
Yerel bildirim sesi düğmesi, arka plan sunucu bildirimini test etmez.

Sunucu kodu `functions/index.js` içinde hazırdır; dağıtım ve ilgili Firebase
faturalandırma kurulumu yapılmadan uygulama, fabrikanın telefonla iletişim
yönteminin yerine geçirilmemelidir. Gerçek bir arızada mevcut yöntemi kullanın.

İnternet kesilirse önbellek uyarısı beklenir. Yeni çağrı ve durum değişiklikleri
internet gerektirir; kaydedilemeyen işlemi başarılı kabul etmeyin.

## Arkadaşından isteyeceğin kısa geri bildirim

- Çağrı diğer cihazda göründü mü; belirgin gecikme oldu mu?
- Çağrı açmak için hangi adımda duraksadın?
- Açıklama yazmak mı, birkaç hazır neden seçmek mi kolay olurdu?
- Hangi ekranda bilgi eksikti veya gereksizdi?
- Türkçe / Lehçe / İngilizce etiketler anlaşılır mıydı?
- Bu işlemi gerçekten yapacak kişinin cihazı sürekli yanında mı?

Gerçek sorun türlerini önceden bilmek gerekmez; ilk denemenin çıktısı bu
cevaplar ve uygulamada tamamlanmış birkaç örnek çağrı olacaktır.

## Teknik kapsam

Test hesapları `environment: training`, `companyId: factory-check-pilot`
profil alanlarını kullanır. Test makineleri `fieldtest_1`, `fieldtest_2`,
`fieldtest_3` kimliklerine sahiptir. Çağrı, rapor, devir ve bildirim aboneliği
aynı test şirketi üzerinden çalışır. Normal kullanıcıların arayüzünde örnek
makineler gösterilmez; test kullanıcısı arayüzünde eski fabrika makineleri
gösterilmez. 1.3.0 ile şirket ve rol sınırlarını uygulayan Firestore kuralları
test edilip yayımlandı. Test hesaplarını yalnızca denemeyi yapan kişilere verin.
Takvim ve devir notlarının deneme adımları [ROSTER.md](ROSTER.md) içindedir.

`tool/provision_field_test.cjs`, mevcut kayıtlara dokunmadan test hesaplarını ve
makinelerini oluşturur. Tekrar çalıştırmak mevcut şifreleri, açık çağrıları
ve makine durumlarını sıfırlamaz. Şifre `FIELD_TEST_PASSWORD` ortam
değişkeninden alınır; veritabanındaki kullanıcı profiline yazılmaz.

`node tool/prepare_roster_demo.cjs` dün/bugün/yarın için eklenecek örnekleri
önizler; `node tool/prepare_roster_demo.cjs --apply` ekler. Firebase CLI oturumu,
yerel proje ayarı ve `functions` bağımlılıkları gereklidir. Araç yalnızca
`factory-check-pilot` şirketinin dört doğrulanmış test hesabını kullanır.
Mevcut veya iptal edilmiş planları, raporları ve notları değiştirmez; komşu
vardiyayla çakışan eklemeleri atlar. Örnek rapor/okundu üretmez; bunları denemede
kişiler kaydeder. Tarih ve çakışma kontrolleri:
`node --test tool/prepare_roster_demo.test.cjs`.

Geri bildirimler `companies/factory-check-pilot/test_feedback/{id}` altında
saklanır. Form aynı kimlikle tekrar denediği için kayıp yanıt sonrasında çift
kayıt oluşturmaz. `tool/verify_field_feedback.cjs` yalnızca bu koleksiyonda
kendi oluşturduğu geçici kayıtlarla hesapların okuma/yazmasını kontrol eder
ve o kayıtları sürüm koşuluyla temizler.
