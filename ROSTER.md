# Vardiya takvimi ve ekip notları — 1.3.0

Ana ekranın **Vardiya takvimi** düğmesinden veya üstteki takvim simgesinden açılır.
TR, EN ve PL desteklenir. Bütün vardiya saatleri **Europe/Warsaw** saatidir;
telefonun saat dilimini değiştirmek fabrikanın günlerini değiştirmez.

## Admin

- Takvimde Dün / Bugün / Yarın veya Tarih seç ile tüm tarihlere bakar.
- Sağ üstteki çalışan simgesinden şirketteki hesapları ve aktif durumlarını görür.
  Bir hesabı pasifleştirmek sunucu erişimini kapatır, geçmişini ve planlarını silmez.
  İleri tarihli planların gerekiyorsa ayrıca iptal edilmesi gerekir. Admin hesapları
  bu ekrandan pasifleştirilemez. Yeni hesap oluşturmak bu ekranın işi değildir.
- Vardiya planla ile çalışan, vardiya adı, başlangıç ve bitiş seçer. Aynı kişi/gün
  kaydı yeniden girilirse mevcut plan güncellenir. Bitiş daha erkense ertesi gündür.
  Kişi başına günde bir vardiya, en fazla 16 saat desteklenir. Bitişik günlerdeki
  çakışmalar işlem içinde kontrol edilir; iptal edilen plan kayıtta kalır.
- Kişinin vardiya kartı; gün sonu raporunu, ilgili çağrıları ve vardiya sırasında
  yazılan eski devir kayıtlarını açar. Rapor yazılmış plan değiştirilemez/iptal edilemez.

## Çalışan

- Yalnızca kendi bölümünün **Pazartesi–Pazar mevcut haftasını** görür.
  `technician` bakım ekibiyle eşleşir; `supervisor` da kendi ekibiyle sınırlıdır.
  Tüm takvim sadece `admin` rolündedir.
- Yarınki ekibin isim ve saatlerini görür. **Pazar günü** gelecek haftanın listesi
  henüz görünmez; yarın için ekibine not bırakabilir. Plan pazartesi açılır.
- Kendi vardiya kartından gün sonu raporu yazar: özet, sorunlar, sonraki vardiyanın
  kontrol edecekleri. Başlangıçtan bitişin 24 saat sonrasına kadar kaydedebilir.
  Rapor değiştirilemez. Pazar gece vardiyasının kendi raporu pazartesi özel kartla
  tamamlanabilir; bu istisna geçen haftanın ekip listesini açmaz.
- Devir notu bırak ile Bugün/Yarın ve Önemli işareti seçer. Not ekip içindir;
  vardiya değişse veya alıcı henüz planlanmamış olsa da ekibe görünür.
- Seçilen gün uygulamanın ana ekranında notlar görünür. Her kişi kendi **Okudum**
  kaydını oluşturur; yazar ve admin okuyanları görebilir. Okundu, işi tamamlama
  veya eski çağrı devrini kabul etme anlamına gelmez.

## Kapsam ve test

Bu takvim **planlama** içindir; fiilî puantaj, kart basma veya canlı çevrimiçi
listesi değildir. İlgili çağrılar: kişinin bildirdiği veya şu anda üstlendiği,
vardiya süresiyle çakışan çağrılardır. Geçmişte başka kişiye devredilmiş tüm
işleri otomatik olarak yeniden kurmaz; kalıcı gün sonu/devir raporları da incelenir.
Rapordaki sonraki vardiya metni otomatik uyarıya çevrilmez; görünür uyarı için
ayrıca ekip notu bırakılır. Yeni notlar için kilitli telefona push gönderilmez.

Çalışan takvimi sunucu doğrulaması bekler; eski önbellek takvim olarak açılmaz.
Hafta/gün değişiminde ve uygulamaya dönüldüğünde görünüm yenilenir. Sunucu kuralları
erişim için telefon saatini değil kendi saatini kullanır. Polonya'daki 167/169
saatlik yaz/kış geçiş haftaları testlidir. Yaz geçişinde olmayan 02:00–02:59 saatleri
reddedilir; sonbaharda tekrarlanan saatlerin ilk oluşumu kullanılır.

Deneme: aynı şirketteki adminle bugüne iki operatör vardiyası ekleyin; operatörle
haftalık planı açın; vardiyası başlayan operatörle rapor ve önemli not kaydedin;
diğer operatörle notu okuyup Okudum deyin; adminle raporu ve okuyanları kontrol edin.
Üretim/test şirketleri ayrıdır. Hazır iki saha hesabı farklı ekiplerdedir; kendi
aralarında operatör ekip notu testi yapamazlar. Takvim denemesi için aynı test
şirketinde admin ve iki operatör hesabı gerekir. Gerçek fabrika planına sahte
vardiya eklenmedi.

Veri: `companies/{company}/roster_weeks/{monday}/shifts/{day_uid}`;
rapor `reports/end`; not `team_notes/{id}`; okundu `reads/{uid}`.
Güvenlik testleri `security/firestore.test.cjs`, servis/ekran testleri
`test/roster_test.dart`, yerel örnekli ekran görüntüleri
`flutter test --update-goldens tool/capture_roster_test.dart` ile üretilir.
