# İki cihazla saha denemesi — Factory Check 1.2.3

Amaç: İzleme çalışanı ile operatörün uygulama üzerinden çağrı açıp sonuçlandırmayı
denemesi ve akışın sahada anlaşılır olup olmadığını öğrenmek.

## Kurulum

İki Android cihaza da `build/app/outputs/flutter-apk/app-debug.apk` dosyasını kurun.
Bu, test için debug paketidir. İki cihazın da internete erişmesi gerekir.

| Cihaz | Giriş | Şifre | Rol |
|---|---|---|---|
| İzleme çalışanının cihazı | `testizleme` | Yerel kurulum şifresi | Çağrı açma, not ekleme, izleme |
| Operatörün cihazı | `testoperator` | Yerel kurulum şifresi | Üstlenme, müdahale, sonuçlandırma |

Test şifreleri depoya konmaz. Bu bilgisayardaki `FIELD_TEST_CREDENTIALS.local.md`
dosyasında saklanır; başka bir kurulumda hesapları hazırlayan kişiden alın.

E-posta biçimleri `testizleme@company.local` ve `testoperator@company.local` da
kullanılabilir. Eski `admin` hesabı mevcut fabrika kayıtlarına bağlıdır; bu
deneme için yukarıdaki iki hesabı kullanın.

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
aynı rolde ikinci kişisel hesap gerekir. Mevcut iki hesapla devir notu
oluşturma ve okuma denenebilir.

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
gösterilmez. Bu istemci ayrımı sunucuda erişim koruması değildir: 11 Ekim 2026'da
okunan canlı Firestore kuralı bütün oturum açmış hesaplara bütün belgelerde
okuma/yazma izni veriyordu. Test hesaplarını yalnızca denemeyi yapan iki kişiye
verin; gerçek kullanım öncesinde şirket ve rol kuralları hazırlanmalıdır.

`tool/provision_field_test.cjs`, mevcut kayıtlara dokunmadan test hesaplarını ve
makinelerini oluşturur. Tekrar çalıştırmak mevcut şifreleri, açık çağrıları
ve makine durumlarını sıfırlamaz. Şifre `FIELD_TEST_PASSWORD` ortam
değişkeninden alınır; veritabanındaki kullanıcı profiline yazılmaz.

Geri bildirimler `companies/factory-check-pilot/test_feedback/{id}` altında
saklanır. Form aynı kimlikle tekrar denediği için kayıp yanıt sonrasında çift
kayıt oluşturmaz. `tool/verify_field_feedback.cjs` yalnızca bu koleksiyonda
kendi oluşturduğu geçici kayıtlarla hesapların okuma/yazmasını kontrol eder
ve o kayıtları sürüm koşuluyla temizler.
