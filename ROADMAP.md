# Saha denemesi ve sonraki geliştirmeler

Ürünün odağı: izleme çalışanının fark ettiği sorunun operatöre ulaşması,
birinin üstlenmesi ve sonucun iki tarafta görünmesi.

## Bu pakette hazır — 1.2.3

- İki rol, ayrı test şirketi ve üç örnek makine.
- Çağrı açma, üstlenme, müdahale ve notla sonuçlandırma.
- Üretim duruşunu ayrıca izleme, geçmiş, dönem raporu ve vardiya devri.
- Uygulama açıkken yeni çağrı için görünür uyarı ve Android iznine bağlı ses.
- Bildirim sesini deneme düğmesi.
- Kullanım kolaylığı puanı ve çalışanın önerisini kaydeden geri bildirim formu.
- Çağrı türüne göre hazır nedenler; elle yazılmış açıklamalar korunur.
- Şirket filtreli makine sorguları ve 15 emülatör testi geçen Firestore kural dosyası.
  Kuralların canlıya dağıtımı henüz tamamlanmadı.

## Fabrikaya götürmeden önce

- İki gerçek Android cihazla FIELD_TEST.md akışını bitir; gecikme ve ses
  gözlemini geri bildirim formuna yaz. Emülatör iki cihazın saha testinin yerine geçmez.
- Telefon kilitliyken kullanım isteniyorsa Firebase faturalandırma kurulumu,
  sunucu bildirim işlevlerinin dağıtımı ve kilitli cihaz testi gerekir.
- Fotoğraf kullanılacaksa test hesaplarıyla yükleme ve diğer cihazda görüntüleme denenir.

## Denemeden sonra öncelik verilecekler

1. **Hazır nedenleri saha yorumlarıyla düzenleme:** Başlangıç seçenekleri eklendi;
   çalışanların kullandığı gerçek ifadeler deneme sonrası netleştirilecek.
2. **Geciken çağrıyı sorumluya bildirme:** Kaç dakika beklenebileceği ve kime
   gideceği fabrika tarafından belirlenir. Telefon kilitliyken çalışması için
   sunucuda zamanlama ve kişi/ekip bildirim yönlendirmesi gerekir.
3. **Tekrarlayan sorun özeti:** Aynı makinede tekrar açılan nedenleri göstermek;
   güvenilir sonuç için önce ortak neden listesi ve yeterli kayıt gerekir.
4. **Paylaşılabilir deneme raporu:** Tamamlanan çağrı, ilk üstlenme süresi ve
   kayıtlı duruşların kısa dışa aktarımı. Fabrikanın hangi formatı kullandığına
   göre PDF veya CSV seçilir.

## Gerçek kullanım / satış öncesi

Kişisel çalışan hesapları, sunucuda şirket ve rol yetkileri, bildirim
yönlendirmesi, veri saklama/yedekleme ve imzalı dağıtım paketi doğrulanmalı.
11 Ekim 2026 kontrolünde Firestore kurallarının bütün giriş yapan hesaplara
bütün belge yollarında okuma/yazma verdiği görüldü. Yetki kuralları bu nedenle
gerçek kullanıma geçişin ön koşuludur; bu güncellemede canlı kurallar değiştirilmedi.
Mevcut makine izleme ve işletme sistemleriyle entegrasyon, kullanılacak sistemin
yetkili kişisi ve arayüzü belli olduğunda ayrıca planlanır.

Buradaki sonraki maddeler uygulanmış özellik değildir; saha bulgularına göre
seçilecek geliştirme sırasıdır.
