// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Factory Check';

  @override
  String get machinesTitle => 'Makineler';

  @override
  String get incidentsTitle => 'Çağrılar';

  @override
  String get logout => 'Çıkış';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languagePolish => 'Lehçe';

  @override
  String roleLabel(String role) {
    return 'rol: $role';
  }

  @override
  String get incidentReport => 'Arıza bildir';

  @override
  String get incidentRepair => 'Tamir bildir';

  @override
  String get machineStatus => 'Makine durumu';

  @override
  String selectedMachine(String machine) {
    return 'Seçilen makine: $machine';
  }

  @override
  String get noActiveIncidentNote => 'Not: Bu makinede aktif arıza yok.';

  @override
  String get send => 'Gönder';

  @override
  String get cancel => 'İptal';

  @override
  String get confirmSend => 'Eminim, gönder';

  @override
  String get statusOpen => 'Açık';

  @override
  String get statusInProgress => 'İşlemde';

  @override
  String get statusResolved => 'Çözüldü';

  @override
  String get statusStopRequired => 'Durdurulmalı';

  @override
  String get statusNeedTechnician => 'Teknisyen gerekli';

  @override
  String get categoryRed => 'Kırmızı';

  @override
  String get categoryYellow => 'Sarı';

  @override
  String get categoryBlue => 'Mavi';

  @override
  String get categoryGreen => 'Yeşil';

  @override
  String get loginWelcome => 'Hoş geldin';

  @override
  String get loginSubtitle => 'Devam etmek için giriş yap';

  @override
  String get companyIdLabel => 'Company ID';

  @override
  String get pinLabel => 'PIN';

  @override
  String get loginButton => 'Giriş';

  @override
  String get loginMissingFields => 'Hesap ve şifre alanlarını doldurun.';

  @override
  String loginNoUserDoc(Object uid) {
    return 'users/\'$uid\' kaydı yok. Firestore’a role ekle.';
  }

  @override
  String loginError(String code) {
    return 'Login hata: $code';
  }

  @override
  String get machinesEmpty => 'Makine yok.';

  @override
  String get incidentsEmpty => 'Henüz incident yok.';

  @override
  String error(String msg) {
    return 'Hata: $msg';
  }

  @override
  String get reportFormSubtitle => 'Arıza bildirim formu';

  @override
  String get repairFormSubtitle => 'Arıza tamir formu';

  @override
  String get errorCodeLabel => 'Arıza kodu';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get choose => 'Seç';

  @override
  String get pickDateTime => 'Tarih/saat seç';

  @override
  String get reportedByLabel => 'Arızayı kim belirtti (isim)';

  @override
  String get writeName => 'İsim yaz';

  @override
  String get machineCanRun => 'Makine hala çalışabilir mi?';

  @override
  String get descriptionLabel => 'Açıklama (sorun / belirtiler)';

  @override
  String get redDescMin15 => 'Kırmızı için açıklama min 15 karakter';

  @override
  String get photoOptional => 'Foto (opsiyonel)';

  @override
  String get camera => 'Kamera';

  @override
  String get gallery => 'Galeri';

  @override
  String get noPhotosYet => 'Henüz foto eklenmedi.';

  @override
  String get photosUploading => 'Fotoğraflar yükleniyor...';

  @override
  String get summaryTitle => 'Özet';

  @override
  String get summaryMachine => 'Makine';

  @override
  String get summaryErrorCode => 'Arıza kodu';

  @override
  String get summaryCategory => 'Kategori';

  @override
  String get summaryDateTime => 'Tarih/saat';

  @override
  String get summaryReportedBy => 'Bildiren';

  @override
  String get summaryCanRun => 'Çalışabilir';

  @override
  String get summaryPhotos => 'Foto';

  @override
  String get yes => 'evet';

  @override
  String get no => 'hayır';

  @override
  String get mustConfirmBeforeSend => 'Göndermeden önce onay ver.';

  @override
  String alreadyHasActiveIncident(String id) {
    return 'Bu makinede zaten aktif arıza var: $id';
  }

  @override
  String get incidentCreatedButNoId =>
      'Incident oluşturuldu ama id gelmedi (garip).';

  @override
  String get faultReported => 'Arıza bildirildi.';

  @override
  String get faultAndPhotosUploaded => 'Arıza + foto(lar) yüklendi.';

  @override
  String submitError(String msg) {
    return 'Gönderim hatası: $msg';
  }

  @override
  String get repairNoActiveIncidentInfo =>
      'Bu makinede aktif incident yok. Yine de “tamir bildir” notu gönderebilirsin.';

  @override
  String get repairActiveFaultTitle => 'Aktif Arıza';

  @override
  String get repairSubmitted => 'Tamir bildirildi (resolved).';

  @override
  String repairSubmitError(String msg) {
    return 'Tamir gönderim hatası: $msg';
  }

  @override
  String get repairedByLabel => 'Tamiri kim yaptı (isim)';

  @override
  String get machineRunsAfterLabel => 'Makine çalışır durumda mı?';

  @override
  String get needsTeamLabel => 'Ek ekip / teknisyen gerekiyor mu?';

  @override
  String get repairNotesLabel => 'Açıklama (ne yapıldı / durum)';

  @override
  String get activeFaultDetailTitle => 'Çağrı detayı';

  @override
  String get overview => 'Genel bakış';

  @override
  String get calls => 'Çağrılar';

  @override
  String get history => 'Geçmiş';

  @override
  String get all => 'Tümü';

  @override
  String get mine => 'Üstlendiğim';

  @override
  String get searchMachines => 'Makine veya bölüm ara';

  @override
  String get activeCalls => 'Aktif çağrı';

  @override
  String get stoppedMachines => 'Duruş bildirilen';

  @override
  String get waitingCalls => 'Destek bekleyen';

  @override
  String get unassigned => 'Henüz üstlenilmedi';

  @override
  String get assignedTo => 'Sorumlu';

  @override
  String get team => 'İlgili ekip';

  @override
  String get kind => 'Çağrı türü';

  @override
  String get newCall => 'Çağrı oluştur';

  @override
  String get claim => 'Gördüm, üstlen';

  @override
  String get startWork => 'Müdahaleye başla';

  @override
  String get waitForSupport => 'Destek bekle';

  @override
  String get resumeWork => 'Müdahaleye devam et';

  @override
  String get resolveCall => 'Sonuçlandır';

  @override
  String get statusAcknowledged => 'Üstlenildi';

  @override
  String get statusWaiting => 'Destek bekleniyor';

  @override
  String get teamOperator => 'Operatör';

  @override
  String get teamMaintenance => 'Bakım';

  @override
  String get teamQuality => 'Kalite';

  @override
  String get teamWarehouse => 'Depo / malzeme';

  @override
  String get kindFault => 'Arıza';

  @override
  String get kindQuality => 'Kalite sorunu';

  @override
  String get kindMaterial => 'Malzeme ihtiyacı';

  @override
  String get kindSupport => 'Destek çağrısı';

  @override
  String get productionStopped => 'Üretim durdu';

  @override
  String get productionRunning => 'Üretim çalışıyor';

  @override
  String get stateUnknown => 'Çalışma durumu doğrulanmadı';

  @override
  String get productionState => 'Bildirilen üretim durumu';

  @override
  String get noActiveCalls => 'Aktif çağrı yok';

  @override
  String get noResults => 'Sonuç bulunamadı';

  @override
  String get noHistory => 'Tamamlanan çağrı yok';

  @override
  String get addNote => 'Not ekle';

  @override
  String get timeline => 'İşlem geçmişi';

  @override
  String get noteHint =>
      'Durum, bekleme nedeni veya vardiyaya aktarılacak bilgi';

  @override
  String get waitingReason => 'Bekleme nedeni';

  @override
  String get resolutionNotes => 'Ne yapıldı?';

  @override
  String get runningConfirmed => 'Üretimin çalıştığını doğruluyorum';

  @override
  String get resolveHelp =>
      'Üretim hâlâ duruyorsa veya ek destek gerekiyorsa çağrıyı beklemeye alın.';

  @override
  String get recordedAt => 'Kayıt zamanı';

  @override
  String get downtime => 'Bildirilen duruş';

  @override
  String get elapsed => 'Geçen süre';

  @override
  String get minutes => 'dk';

  @override
  String get existingCall =>
      'Bu makinenin aktif çağrısı açıldı. Yeni bilgiyi not olarak ekleyebilirsiniz.';

  @override
  String get cachedData =>
      'Önbellekteki veriler gösteriliyor. Güncel durum için bağlantıyı kontrol edin.';

  @override
  String get onlineRequired =>
      'İşlem tamamlanamadı. Bağlantıyı kontrol edip tekrar deneyin.';

  @override
  String get saved => 'Kaydedildi';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get photosPartial =>
      'Çağrı kaydedildi fakat fotoğraflar yüklenemedi. Aşağıdan fotoğrafları tekrar gönderebilirsiniz.';

  @override
  String get retryPhotos => 'Fotoğrafları tekrar gönder';

  @override
  String get openCall => 'Çağrıyı aç';

  @override
  String get machineList => 'Makine listesi';

  @override
  String get factoryMap => 'Fabrika krokisi';

  @override
  String get callDescription => 'Ne oldu, ne gerekiyor?';

  @override
  String get codeOptional => 'Arıza kodu (varsa)';

  @override
  String get signInAccount => 'E-posta veya şirket kodu';

  @override
  String get password => 'Şifre / PIN';

  @override
  String get sessionError =>
      'Hesap profili yüklenemedi. Bağlantıyı ve kullanıcı kaydını kontrol edin.';

  @override
  String get notificationUnavailable =>
      'Telefon bildirimleri kurulamadı. Uygulama içindeki çağrı uyarıları ve canlı listeyi takip edebilirsiniz.';

  @override
  String get errorForbidden => 'Bu işlem için yetkiniz yok.';

  @override
  String get errorAssigned => 'Çağrıyı başka bir çalışan üstlenmiş.';

  @override
  String get errorStale =>
      'Bu çağrı artık makinenin güncel çağrısı değil. Listeyi yenileyin.';

  @override
  String get errorTransition =>
      'Çağrının durumu değişmiş. Güncel durumu kontrol edin.';

  @override
  String get errorTime => 'Tarih/saat gelecekte veya başlangıçtan önce olamaz.';

  @override
  String get errorNote => 'Lütfen kısa bir açıklama yazın.';

  @override
  String get errorRunning =>
      'Sonuçlandırmak için üretimin çalıştığı doğrulanmalıdır.';

  @override
  String get notFound => 'Kayıt bulunamadı.';

  @override
  String get photoLimit => 'En fazla 5 fotoğraf ekleyebilirsiniz.';

  @override
  String get handover => 'Vardiya devri';

  @override
  String get handoverHelp =>
      'Vardiya notlarını ve açık işleri kayıt altına alın. Gelen vardiya teslim aldığını onaylasın.';

  @override
  String get productionResume => 'Üretim yeniden başladı';

  @override
  String get productionStop => 'Duruş bildir';

  @override
  String get confirmState =>
      'Makinenin bildirilen üretim durumunu değiştirmek istediğinizi doğrulayın.';

  @override
  String get reportSummary => 'Vardiyanın özeti';

  @override
  String get roleViewer => 'Görüntüleyici';

  @override
  String get roleSupervisor => 'Vardiya sorumlusu';

  @override
  String get roleWatcher => 'İzleme ekibi';

  @override
  String get roleAdmin => 'Yönetici';

  @override
  String get noActivity => 'Henüz işlem yok';

  @override
  String get createdEvent => 'Çağrı açıldı';

  @override
  String get photoEvent => 'Fotoğraf eklendi';

  @override
  String get noteEvent => 'Not eklendi';

  @override
  String get changedEvent => 'Durum değişti';

  @override
  String get allTeams => 'Tüm ekipler';

  @override
  String get newHandover => 'Vardiya devri oluştur';

  @override
  String get noHandovers => 'Henüz vardiya devri yok.';

  @override
  String get handoverFrom => 'Devreden';

  @override
  String get handoverReceived => 'Teslim alındı';

  @override
  String get handoverPending => 'Teslim alınmayı bekliyor';

  @override
  String get loadMore => 'Daha fazla göster';

  @override
  String get newHandoverHelp =>
      'Vardiyayı tanımlayın, sonraki ekibin bilmesi gerekenleri yazın ve devredilecek çağrıları seçin.';

  @override
  String get shiftLabel => 'Vardiya adı / saatleri';

  @override
  String get shiftHint => 'Örn. 11 Ekim · Gece 22:00–06:00';

  @override
  String get handoverNotes => 'Vardiya notları';

  @override
  String get handoverNotesHint =>
      'Bekleyen malzeme, kontrol edilecek makine, önemli uyarılar…';

  @override
  String selectHandoverCalls(int count) {
    return 'Devredilecek çağrılar ($count/6)';
  }

  @override
  String get handoverSelectionHelp =>
      'En fazla 6 açık çağrı seçilebilir. Çağrı seçmeden de vardiya notu bırakabilirsiniz.';

  @override
  String get saveHandover => 'Devri kaydet';

  @override
  String get acceptHandover => 'Vardiyayı teslim al';

  @override
  String get handoverAcceptHelp =>
      'Bu devri teslim aldığınız kaydedilecek. Seçili çağrılardan hâlâ devreden kişiye atanmış ve açık olanlar size geçecek. Diğer kişilerin işleri değişmeyecek.';

  @override
  String get handoverReadReceiptHelp =>
      'Bu vardiya notlarını teslim aldığınız kaydedilecek. İzleme rolünde çağrı sorumluları değişmez.';

  @override
  String handoverTransferred(int count) {
    return 'Teslim alana devredilen açık çağrı: $count';
  }

  @override
  String get handoverSnapshotHelp =>
      'Aşağıdaki bilgiler devir anındaki kayıttır. Güncel durumu görmek için çağrıya dokunun.';

  @override
  String get noHandoverCalls => 'Bu devirde yalnızca vardiya notu var.';

  @override
  String get errorHandover =>
      'Vardiya bilgilerini kontrol edin. En fazla 6 çağrı eklenebilir.';

  @override
  String get errorHandoverChanged =>
      'Seçilen bir çağrı artık açık değil. Notlarınız korundu; güncel listeden çağrıları yeniden seçin.';

  @override
  String get errorHandoverAccepted =>
      'Bu vardiya devrini başka bir kullanıcı teslim aldı.';

  @override
  String get errorHandoverSelf => 'Devri başka bir çalışan teslim almalı.';

  @override
  String get handoverEvent => 'Vardiya devriyle sorumlu değişti';

  @override
  String get reports => 'Raporlar';

  @override
  String get reportIntro =>
      'Tarih aralığı seçerek çağrıları ve bildirilen makine duruşlarını inceleyin.';

  @override
  String get today => 'Bugün';

  @override
  String get lastSevenDays => 'Son 7 gün';

  @override
  String get lastThirtyDays => 'Son 30 gün';

  @override
  String get callsOpenedInPeriod => 'Açılan çağrılar';

  @override
  String get callsResolvedInPeriod => 'Kapatılan çağrılar';

  @override
  String get machineDowntimeTotal => 'Toplam makine duruşu';

  @override
  String get firstResponseAverage => 'Ortalama ilk üstlenme süresi';

  @override
  String responseSampleCount(int count) {
    return 'Üstlenme ortalaması, bu dönemde açılan ve ilk üstlenme zamanı bilinen $count çağrıdan hesaplanır.';
  }

  @override
  String get reportMethodHelp =>
      'Duruş, yalnızca seçilen tarih aralığına düşen bildirilmiş sürelerin toplamıdır; açık duruşlar şu ana kadar sayılır. Makineler ayrı ayrı toplanır; bu değer fabrikanın toplam kapalı kalma süresi değildir. Tarihler cihazın yerel saatine göredir.';

  @override
  String reportIncomplete(int count) {
    return 'Bu döneme denk gelen $count eski çağrının duruş geçmişi eksik olabilir. Yalnızca zamanı bilinen aralıklar toplama katıldı; bu toplam tam üretim kaybını göstermeyebilir.';
  }

  @override
  String get machineBreakdown => 'Makine bazında';

  @override
  String get noPeriodData => 'Seçilen dönemde kayıt bulunamadı.';

  @override
  String get reportUpdated => 'Hesaplama zamanı';

  @override
  String get handoverTeamOnly =>
      'Bu devri hedef ekipten bir çalışan veya vardiya sorumlusu teslim alabilir.';

  @override
  String get trainingMode => 'SAHA TESTİ';

  @override
  String get trainingBanner =>
      'Örnek makinelerle deneme yapıyorsunuz. Gerçek bir arıza için fabrikanın mevcut iletişim yolunu kullanın.';

  @override
  String get trainingStepsTitle => 'İki cihazla test adımları';

  @override
  String get trainingSteps =>
      '1. İki cihazda da uygulamayı açık tutun.\n2. İzleme hesabıyla TEST-1 makinesinde örnek çağrı açın.\n3. Operatör hesabıyla çağrıyı görün, üstlenin ve müdahaleyi başlatın.\n4. Üretim yeniden başladı seçeneğini deneyin; ardından notla çağrıyı kapatın.\n5. İki cihazdan geçmişi ve raporu kontrol edin.\n6. Görünmeyen çağrıları veya zorlandığınız adımları not edin.\n\nArka plan bildirimleri için sunucu kurulumu ve ayrıca cihaz testi gerekir.';

  @override
  String incomingCall(String machine) {
    return 'Yeni çağrı: $machine';
  }

  @override
  String incomingCallCount(int count) {
    return '$count yeni çağrı geldi';
  }

  @override
  String get incomingCallHelp => 'Çağrıyı açıp ayrıntıları kontrol edin.';

  @override
  String get soundTest => 'Bildirim sesi dene';

  @override
  String get soundTestBody => 'Bu bir deneme bildirimidir.';

  @override
  String get soundTestSent =>
      'Deneme bildirimi gönderildi. Ses duymadıysanız telefonun bildirim sesi, Factory Check bildirim kanalı ve Rahatsız Etmeyin ayarını kontrol edin.';

  @override
  String get soundTestDisabled =>
      'Bildirim izni kapalı veya bu cihazda desteklenmiyor. Android ayarlarında Factory Check bildirimlerine izin verin.';

  @override
  String get testFeedback => 'Test geri bildirimi';

  @override
  String get feedbackHelp =>
      'Neyi kolay, neyi zor buldunuz? Yorumunuz test şirketinde adınız ve rolünüzle kaydedilir; deneme sonrası geliştirmeler için incelenebilir.';

  @override
  String get feedbackEase => 'Kullanım kolaylığı';

  @override
  String get feedbackScale => '1 = çok zor · 5 = çok kolay';

  @override
  String get feedbackNotes => 'Zorlandığınız adım veya öneriniz';

  @override
  String get feedbackRequired => 'Lütfen bu alanı doldurun.';

  @override
  String get feedbackSend => 'Geri bildirimi kaydet';

  @override
  String get feedbackSaved => 'Geri bildiriminiz kaydedildi.';

  @override
  String get quickReason => 'Hazır neden (isteğe bağlı)';

  @override
  String get quickReasonHelp =>
      'Uygun olanı seçin veya açıklama yazın. Bunlar deneme için başlangıç seçenekleridir; üretim durumunu ayrıca belirtin.';

  @override
  String get reasonMachineStopped => 'Makine durdu';

  @override
  String get reasonMaterialJam => 'Ürün / malzeme sıkıştı';

  @override
  String get reasonMachineAlarm => 'Makine alarm veriyor';

  @override
  String get reasonShapeSize => 'Şekil / ölçü uygunsuz';

  @override
  String get reasonBakingColour => 'Pişirme / renk uygunsuz';

  @override
  String get reasonPackagingSeal => 'Paket kapanmıyor';

  @override
  String get reasonMaterialEmpty => 'Üretim malzemesi bitti';

  @override
  String get reasonPackagingEmpty => 'Ambalaj malzemesi bitti';

  @override
  String get reasonOperatorHelp => 'Operatör desteği';

  @override
  String get reasonTechnicalCheck => 'Teknik kontrol gerekiyor';

  @override
  String get roster => 'Vardiya takvimi';

  @override
  String get staff => 'Çalışanlar';

  @override
  String get rosterHelp =>
      'Polonya saati · Pazartesi–Pazar. Bu ekran planlanan vardiyaları gösterir; giriş-çıkış kaydı değildir.';

  @override
  String get weekOnly =>
      'Yalnızca kendi ekibinizin bu haftaki planını görebilirsiniz. Pazar günü gelecek haftanın isimleri açılmaz; yarın için ekibinize not bırakabilirsiniz.';

  @override
  String get yesterday => 'Dün';

  @override
  String get tomorrow => 'Yarın';

  @override
  String get chooseDate => 'Tarih seç';

  @override
  String get addShift => 'Vardiya planla';

  @override
  String get editShift => 'Vardiyayı düzenle';

  @override
  String get shiftStart => 'Başlangıç';

  @override
  String get shiftEnd => 'Bitiş';

  @override
  String get nightShiftHelp =>
      'Bitiş başlangıçtan erkense vardiya ertesi gün biter. Kişi başına günde bir vardiya, en fazla 16 saat. Saat değişiminde 02:00–02:59 tekrarlanırsa ilk oluşum kullanılır.';

  @override
  String get noShifts => 'Bu gün için vardiya planı yok.';

  @override
  String get noEmployees => 'Planlanabilecek aktif çalışan yok.';

  @override
  String get activeEmployee => 'Aktif çalışan';

  @override
  String get inactiveEmployee => 'Pasif çalışan';

  @override
  String get staffHelp =>
      'Şirket hesabı bulunan çalışanlar. Pasifleştirme uygulama erişimini kapatır; geçmiş kayıtları silmez.';

  @override
  String get changeEmployeeStatus => 'Çalışanın erişim durumunu değiştir?';

  @override
  String get scheduled => 'Planlandı';

  @override
  String get shiftCancelled => 'Vardiya iptal edildi';

  @override
  String get cancelShift => 'Vardiyayı iptal et';

  @override
  String get cancelShiftHelp =>
      'Bu plan iptal edilecek; kaydı takvimde kalacak.';

  @override
  String get endReport => 'Gün sonu raporu';

  @override
  String get writeReport => 'Gün sonu raporu yaz';

  @override
  String get reportProblems => 'Karşılaşılan sorunlar';

  @override
  String get reportFollowUp => 'Sonraki vardiyanın kontrol etmesi gerekenler';

  @override
  String get reportHelp =>
      'Rapor kaydedildikten sonra değiştirilemez. Vardiya başladıktan sonra ve bitişinden itibaren 24 saat içinde yazılır. Ertesi günün ekranında uyarı göstermek için ayrıca devir notu bırakın.';

  @override
  String get noReport => 'Henüz gün sonu raporu yok.';

  @override
  String get dailyIssues => 'Bu vardiyayla ilişkili çağrılar';

  @override
  String get dailyIssuesHelp =>
      'Bu kişinin bildirdiği veya şu anda üstlendiği, vardiya süresiyle çakışan çağrılar. Geçmişte el değiştiren işler için devir raporlarını da inceleyin.';

  @override
  String get dayHandovers => 'Vardiyada yazılan devir kayıtları';

  @override
  String get teamNotes => 'Devir notları ve uyarılar';

  @override
  String get leaveNote => 'Devir notu bırak';

  @override
  String get importantNote => 'Önemli / kontrol gerekiyor';

  @override
  String get markRead => 'Okudum';

  @override
  String get readNote => 'Okundu';

  @override
  String get noteHelp =>
      'Not, seçilen gün kendi ekibiniz uygulamayı açtığında ana ekranda görünür. Her çalışan ayrı ayrı okundu işaretler.';

  @override
  String get noNotes => 'Bu gün için devir notu yok.';

  @override
  String get readReceipts => 'Okuyanlar';

  @override
  String get noReaders => 'Henüz okunmadı.';

  @override
  String get nextTeam => 'Yarınki ekip';

  @override
  String get nextWeekHidden =>
      'Yarın yeni hafta başlıyor. Plan pazartesi açılır; ekibinize bugünden not bırakabilirsiniz.';

  @override
  String get invalidShift =>
      'Vardiya adını ve saatlerini kontrol edin. Süre en fazla 16 saat olmalı.';

  @override
  String get shiftOverlap =>
      'Bu çalışanın bitişik gündeki vardiyasıyla saatler çakışıyor.';

  @override
  String get reportLocked =>
      'Raporu yazılmış vardiya değiştirilemez veya iptal edilemez.';

  @override
  String get reportTime =>
      'Rapor vardiya başladıktan sonra ve bitişinden itibaren 24 saat içinde yazılabilir.';

  @override
  String get dstTime =>
      'Bu saat Polonya’da yaz saati geçişinde mevcut değil. Başka bir saat seçin.';

  @override
  String get onlineRoster =>
      'Güncel vardiya planı için sunucu bağlantısı bekleniyor.';

  @override
  String get save => 'Kaydet';
}
