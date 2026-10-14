// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Factory Check';

  @override
  String get machinesTitle => 'Maszyny';

  @override
  String get incidentsTitle => 'Zgłoszenia';

  @override
  String get logout => 'Wyloguj';

  @override
  String get language => 'Język';

  @override
  String get languageSystem => 'System';

  @override
  String get languageTurkish => 'Turecki';

  @override
  String get languageEnglish => 'Angielski';

  @override
  String get languagePolish => 'Polski';

  @override
  String roleLabel(String role) {
    return 'rola: $role';
  }

  @override
  String get incidentReport => 'Zgłoś awarię';

  @override
  String get incidentRepair => 'Zgłoś naprawę';

  @override
  String get machineStatus => 'Status maszyny';

  @override
  String selectedMachine(String machine) {
    return 'Wybrana maszyna: $machine';
  }

  @override
  String get noActiveIncidentNote =>
      'Uwaga: Ta maszyna nie ma aktywnego incydentu.';

  @override
  String get send => 'Wyślij';

  @override
  String get cancel => 'Anuluj';

  @override
  String get confirmSend => 'Tak, wyślij';

  @override
  String get statusOpen => 'Otwarte';

  @override
  String get statusInProgress => 'W toku';

  @override
  String get statusResolved => 'Rozwiązane';

  @override
  String get statusStopRequired => 'Wymagane zatrzymanie';

  @override
  String get statusNeedTechnician => 'Potrzebny technik';

  @override
  String get categoryRed => 'Czerwony';

  @override
  String get categoryYellow => 'Żółty';

  @override
  String get categoryBlue => 'Niebieski';

  @override
  String get categoryGreen => 'Zielony';

  @override
  String get loginWelcome => 'Witamy';

  @override
  String get loginSubtitle => 'Zaloguj się, aby kontynuować';

  @override
  String get companyIdLabel => 'Company ID';

  @override
  String get pinLabel => 'PIN';

  @override
  String get loginButton => 'Zaloguj';

  @override
  String get loginMissingFields => 'Wpisz konto i hasło.';

  @override
  String loginNoUserDoc(Object uid) {
    return 'Brak rekordu w users/\'$uid\'. Dodaj rolę w Firestore.';
  }

  @override
  String loginError(String code) {
    return 'Błąd logowania: $code';
  }

  @override
  String get machinesEmpty => 'Brak maszyn.';

  @override
  String get incidentsEmpty => 'Brak incydentów.';

  @override
  String error(String msg) {
    return 'Błąd: $msg';
  }

  @override
  String get reportFormSubtitle => 'Formularz zgłoszenia awarii';

  @override
  String get repairFormSubtitle => 'Formularz zgłoszenia naprawy';

  @override
  String get errorCodeLabel => 'Kod awarii';

  @override
  String get categoryLabel => 'Kategoria';

  @override
  String get choose => 'Wybierz';

  @override
  String get pickDateTime => 'Wybierz datę/godzinę';

  @override
  String get reportedByLabel => 'Kto zgłosił (imię)';

  @override
  String get writeName => 'Wpisz imię';

  @override
  String get machineCanRun => 'Czy maszyna może dalej pracować?';

  @override
  String get descriptionLabel => 'Opis (problem / objawy)';

  @override
  String get redDescMin15 => 'Dla Czerwonego opis min. 15 znaków';

  @override
  String get photoOptional => 'Zdjęcie (opcjonalnie)';

  @override
  String get camera => 'Aparat';

  @override
  String get gallery => 'Galeria';

  @override
  String get noPhotosYet => 'Nie dodano jeszcze zdjęć.';

  @override
  String get photosUploading => 'Trwa wysyłanie zdjęć...';

  @override
  String get summaryTitle => 'Podsumowanie';

  @override
  String get summaryMachine => 'Maszyna';

  @override
  String get summaryErrorCode => 'Kod awarii';

  @override
  String get summaryCategory => 'Kategoria';

  @override
  String get summaryDateTime => 'Data/godzina';

  @override
  String get summaryReportedBy => 'Zgłaszający';

  @override
  String get summaryCanRun => 'Może pracować';

  @override
  String get summaryPhotos => 'Zdjęcia';

  @override
  String get yes => 'tak';

  @override
  String get no => 'nie';

  @override
  String get mustConfirmBeforeSend => 'Potwierdź przed wysłaniem.';

  @override
  String alreadyHasActiveIncident(String id) {
    return 'Ta maszyna ma już aktywny incydent: $id';
  }

  @override
  String get incidentCreatedButNoId =>
      'Incydent utworzony, ale nie zwrócono id (dziwne).';

  @override
  String get faultReported => 'Awaria zgłoszona.';

  @override
  String get faultAndPhotosUploaded => 'Awaria + zdjęcie(a) wysłane.';

  @override
  String submitError(String msg) {
    return 'Błąd wysyłania: $msg';
  }

  @override
  String get repairNoActiveIncidentInfo =>
      'Brak aktywnego incydentu dla tej maszyny. Nadal możesz wysłać notatkę naprawy.';

  @override
  String get repairActiveFaultTitle => 'Aktywna awaria';

  @override
  String get repairSubmitted => 'Naprawa zgłoszona (resolved).';

  @override
  String repairSubmitError(String msg) {
    return 'Błąd wysyłania naprawy: $msg';
  }

  @override
  String get repairedByLabel => 'Kto naprawił (imię)';

  @override
  String get machineRunsAfterLabel => 'Czy maszyna działa?';

  @override
  String get needsTeamLabel => 'Czy potrzebny dodatkowy zespół/technik?';

  @override
  String get repairNotesLabel => 'Opis (co zrobiono / stan)';

  @override
  String get activeFaultDetailTitle => 'Szczegóły zgłoszenia';

  @override
  String get overview => 'Przegląd';

  @override
  String get calls => 'Zgłoszenia';

  @override
  String get history => 'Historia';

  @override
  String get all => 'Wszystkie';

  @override
  String get mine => 'Przypisane do mnie';

  @override
  String get searchMachines => 'Szukaj maszyny lub sekcji';

  @override
  String get activeCalls => 'Aktywne zgłoszenia';

  @override
  String get stoppedMachines => 'Zgłoszone przestoje';

  @override
  String get waitingCalls => 'Oczekujące na wsparcie';

  @override
  String get unassigned => 'Jeszcze nieprzypisane';

  @override
  String get assignedTo => 'Osoba odpowiedzialna';

  @override
  String get team => 'Odpowiedzialny zespół';

  @override
  String get kind => 'Typ zgłoszenia';

  @override
  String get newCall => 'Nowe zgłoszenie';

  @override
  String get claim => 'Potwierdź i przejmij';

  @override
  String get startWork => 'Rozpocznij pracę';

  @override
  String get waitForSupport => 'Oczekiwanie na wsparcie';

  @override
  String get resumeWork => 'Wznów pracę';

  @override
  String get resolveCall => 'Zakończ zgłoszenie';

  @override
  String get statusAcknowledged => 'Przyjęte';

  @override
  String get statusWaiting => 'Oczekiwanie na wsparcie';

  @override
  String get teamOperator => 'Operator';

  @override
  String get teamMaintenance => 'Utrzymanie ruchu';

  @override
  String get teamQuality => 'Jakość';

  @override
  String get teamWarehouse => 'Magazyn / materiały';

  @override
  String get kindFault => 'Awaria';

  @override
  String get kindQuality => 'Problem jakościowy';

  @override
  String get kindMaterial => 'Zapotrzebowanie na materiał';

  @override
  String get kindSupport => 'Prośba o wsparcie';

  @override
  String get productionStopped => 'Produkcja zatrzymana';

  @override
  String get productionRunning => 'Produkcja działa';

  @override
  String get stateUnknown => 'Stan pracy niepotwierdzony';

  @override
  String get productionState => 'Zgłoszony stan produkcji';

  @override
  String get noActiveCalls => 'Brak aktywnych zgłoszeń';

  @override
  String get noResults => 'Brak wyników';

  @override
  String get noHistory => 'Brak zakończonych zgłoszeń';

  @override
  String get addNote => 'Dodaj notatkę';

  @override
  String get timeline => 'Historia działań';

  @override
  String get noteHint =>
      'Status, powód oczekiwania lub informacja dla kolejnej zmiany';

  @override
  String get waitingReason => 'Powód oczekiwania';

  @override
  String get resolutionNotes => 'Co zostało zrobione?';

  @override
  String get runningConfirmed => 'Potwierdzam, że produkcja działa';

  @override
  String get resolveHelp =>
      'Ustaw oczekiwanie, jeśli produkcja nadal stoi lub potrzebne jest wsparcie.';

  @override
  String get recordedAt => 'Czas zgłoszenia';

  @override
  String get downtime => 'Zgłoszony przestój';

  @override
  String get elapsed => 'Czas od zgłoszenia';

  @override
  String get minutes => 'min';

  @override
  String get existingCall =>
      'Otwarto istniejące zgłoszenie. Nowe informacje dodaj jako notatkę.';

  @override
  String get cachedData =>
      'Wyświetlane są dane z pamięci. Sprawdź połączenie, aby zobaczyć aktualny stan.';

  @override
  String get onlineRequired =>
      'Nie udało się wykonać operacji. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get saved => 'Zapisano';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get photosPartial =>
      'Zgłoszenie zapisano, ale zdjęć nie wysłano. Spróbuj wysłać je ponownie poniżej.';

  @override
  String get retryPhotos => 'Wyślij zdjęcia ponownie';

  @override
  String get openCall => 'Otwórz zgłoszenie';

  @override
  String get machineList => 'Lista maszyn';

  @override
  String get factoryMap => 'Plan zakładu';

  @override
  String get callDescription => 'Co się stało lub czego potrzeba?';

  @override
  String get codeOptional => 'Kod awarii (opcjonalny)';

  @override
  String get signInAccount => 'E-mail lub kod firmy';

  @override
  String get password => 'Hasło / PIN';

  @override
  String get sessionError =>
      'Nie udało się wczytać profilu konta. Sprawdź połączenie i dane użytkownika.';

  @override
  String get notificationUnavailable =>
      'Nie udało się skonfigurować powiadomień telefonu. Możesz śledzić alerty w aplikacji i listę zgłoszeń na żywo.';

  @override
  String get errorForbidden => 'Brak uprawnień do tej operacji.';

  @override
  String get errorAssigned => 'Zgłoszenie przejął inny pracownik.';

  @override
  String get errorStale =>
      'To zgłoszenie nie jest już aktualne dla tej maszyny. Odśwież listę.';

  @override
  String get errorTransition =>
      'Status zgłoszenia się zmienił. Sprawdź aktualny stan.';

  @override
  String get errorTime =>
      'Czas nie może być w przyszłości ani przed początkiem.';

  @override
  String get errorNote => 'Wpisz krótki opis.';

  @override
  String get errorRunning =>
      'Przed zakończeniem należy potwierdzić pracę produkcji.';

  @override
  String get notFound => 'Nie znaleziono rekordu.';

  @override
  String get photoLimit => 'Możesz dodać maksymalnie 5 zdjęć.';

  @override
  String get handover => 'Przekazanie zmiany';

  @override
  String get handoverHelp =>
      'Zapisz notatki i otwarte zgłoszenia, aby kolejna zmiana mogła potwierdzić odbiór.';

  @override
  String get productionResume => 'Produkcja wznowiona';

  @override
  String get productionStop => 'Zgłoś przestój';

  @override
  String get confirmState => 'Potwierdź zmianę zgłoszonego stanu produkcji.';

  @override
  String get reportSummary => 'Podsumowanie zmiany';

  @override
  String get roleViewer => 'Obserwator';

  @override
  String get roleSupervisor => 'Kierownik zmiany';

  @override
  String get roleWatcher => 'Zespół monitorujący';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get noActivity => 'Brak działań';

  @override
  String get createdEvent => 'Utworzono zgłoszenie';

  @override
  String get photoEvent => 'Dodano zdjęcie';

  @override
  String get noteEvent => 'Dodano notatkę';

  @override
  String get changedEvent => 'Zmieniono status';

  @override
  String get allTeams => 'Wszystkie zespoły';

  @override
  String get newHandover => 'Utwórz przekazanie';

  @override
  String get noHandovers => 'Brak przekazań zmiany.';

  @override
  String get handoverFrom => 'Przekazuje';

  @override
  String get handoverReceived => 'Odebrano';

  @override
  String get handoverPending => 'Oczekuje na odbiór';

  @override
  String get loadMore => 'Pokaż więcej';

  @override
  String get newHandoverHelp =>
      'Nazwij zmianę, zapisz informacje dla kolejnego zespołu i wybierz zgłoszenia do przekazania.';

  @override
  String get shiftLabel => 'Nazwa / godziny zmiany';

  @override
  String get shiftHint => 'Np. 11 października · Noc 22:00–06:00';

  @override
  String get handoverNotes => 'Notatki zmiany';

  @override
  String get handoverNotesHint =>
      'Brakujące materiały, maszyny do sprawdzenia, ważne uwagi…';

  @override
  String selectHandoverCalls(int count) {
    return 'Zgłoszenia do przekazania ($count/6)';
  }

  @override
  String get handoverSelectionHelp =>
      'Wybierz do 6 otwartych zgłoszeń. Możesz też zapisać same notatki zmiany.';

  @override
  String get saveHandover => 'Zapisz przekazanie';

  @override
  String get acceptHandover => 'Odbierz przekazanie';

  @override
  String get handoverAcceptHelp =>
      'Odbiór zostanie zapisany. Wybrane otwarte zgłoszenia nadal przypisane do osoby przekazującej przejdą do Ciebie. Zgłoszenia innych osób pozostaną bez zmian.';

  @override
  String get handoverReadReceiptHelp =>
      'Odbiór notatek zostanie zapisany. Rola monitoringu nie zmienia osób przypisanych do zgłoszeń.';

  @override
  String handoverTransferred(int count) {
    return 'Otwarte zgłoszenia przekazane odbiorcy: $count';
  }

  @override
  String get handoverSnapshotHelp =>
      'Poniższe dane przedstawiają stan z chwili przekazania. Otwórz zgłoszenie, aby zobaczyć aktualny stan.';

  @override
  String get noHandoverCalls => 'To przekazanie zawiera tylko notatki zmiany.';

  @override
  String get errorHandover =>
      'Sprawdź dane zmiany. Można dodać maksymalnie 6 zgłoszeń.';

  @override
  String get errorHandoverChanged =>
      'Wybrane zgłoszenie nie jest już otwarte. Notatki zachowano; wybierz zgłoszenia ponownie z aktualnej listy.';

  @override
  String get errorHandoverAccepted =>
      'Inny użytkownik odebrał już to przekazanie.';

  @override
  String get errorHandoverSelf => 'Przekazanie musi odebrać inny pracownik.';

  @override
  String get handoverEvent =>
      'Zmiana osoby odpowiedzialnej przy przekazaniu zmiany';

  @override
  String get reports => 'Raporty';

  @override
  String get reportIntro =>
      'Sprawdź zgłoszenia i zgłoszone przestoje maszyn w wybranym okresie.';

  @override
  String get today => 'Dzisiaj';

  @override
  String get lastSevenDays => 'Ostatnie 7 dni';

  @override
  String get lastThirtyDays => 'Ostatnie 30 dni';

  @override
  String get callsOpenedInPeriod => 'Utworzone zgłoszenia';

  @override
  String get callsResolvedInPeriod => 'Zamknięte zgłoszenia';

  @override
  String get machineDowntimeTotal => 'Łączny przestój maszyn';

  @override
  String get firstResponseAverage => 'Średni czas do pierwszego przyjęcia';

  @override
  String responseSampleCount(int count) {
    return 'Średni czas przyjęcia obliczono dla $count zgłoszeń utworzonych w tym okresie ze znanym czasem pierwszego przyjęcia.';
  }

  @override
  String get reportMethodHelp =>
      'Przestój to suma zgłoszonych odcinków czasu w wybranym okresie; trwające przestoje liczone są do teraz. Maszyny sumuje się oddzielnie, więc nie jest to czas zatrzymania całej fabryki. Daty używają strefy czasowej urządzenia.';

  @override
  String reportIncomplete(int count) {
    return '$count starszych zgłoszeń obejmujących ten okres może mieć niepełną historię przestojów. Uwzględniono tylko znane odcinki; suma może być zaniżona.';
  }

  @override
  String get machineBreakdown => 'Według maszyny';

  @override
  String get noPeriodData => 'Brak danych w wybranym okresie.';

  @override
  String get reportUpdated => 'Obliczono';

  @override
  String get handoverTeamOnly =>
      'Przekazanie może odebrać pracownik zespołu docelowego lub kierownik zmiany.';

  @override
  String get trainingMode => 'TEST TERENOWY';

  @override
  String get trainingBanner =>
      'Ćwiczysz na przykładowych maszynach. W przypadku rzeczywistej awarii użyj obecnego sposobu komunikacji w fabryce.';

  @override
  String get trainingStepsTitle => 'Test na dwóch urządzeniach';

  @override
  String get trainingSteps =>
      '1. Pozostaw aplikację otwartą na obu urządzeniach.\n2. Kontem monitoringu utwórz przykładowe zgłoszenie dla TEST-1.\n3. Kontem operatora znajdź zgłoszenie, przyjmij je i rozpocznij pracę.\n4. Zgłoś wznowienie produkcji, a potem zamknij zgłoszenie z notatką.\n5. Sprawdź historię i raporty na obu urządzeniach.\n6. Zapisz brakujące zgłoszenia i trudne kroki.\n\nPowiadomienia w tle wymagają konfiguracji serwera i oddzielnego testu urządzeń.';

  @override
  String incomingCall(String machine) {
    return 'Nowe zgłoszenie: $machine';
  }

  @override
  String incomingCallCount(int count) {
    return 'Nowe zgłoszenia: $count';
  }

  @override
  String get incomingCallHelp => 'Otwórz zgłoszenie, aby sprawdzić szczegóły.';

  @override
  String get soundTest => 'Test dźwięku powiadomień';

  @override
  String get soundTestBody => 'To jest powiadomienie testowe.';

  @override
  String get soundTestSent =>
      'Wysłano powiadomienie testowe. Jeśli nie było dźwięku, sprawdź głośność powiadomień, kanał Factory Check i tryb Nie przeszkadzać.';

  @override
  String get soundTestDisabled =>
      'Powiadomienia są wyłączone lub nieobsługiwane. Zezwól na powiadomienia Factory Check w ustawieniach Androida.';

  @override
  String get testFeedback => 'Opinia o teście';

  @override
  String get feedbackHelp =>
      'Co było łatwe, a co trudne? Opinia zostanie zapisana w firmie testowej wraz z Twoim imieniem i rolą do analizy po próbie.';

  @override
  String get feedbackEase => 'Łatwość obsługi';

  @override
  String get feedbackScale => '1 = bardzo trudno · 5 = bardzo łatwo';

  @override
  String get feedbackNotes => 'Trudny krok lub Twoja sugestia';

  @override
  String get feedbackRequired => 'Uzupełnij to pole.';

  @override
  String get feedbackSend => 'Zapisz opinię';

  @override
  String get feedbackSaved => 'Twoja opinia została zapisana.';

  @override
  String get quickReason => 'Gotowy powód (opcjonalnie)';

  @override
  String get quickReasonHelp =>
      'Wybierz powód lub wpisz opis. To początkowe opcje do testu; stan produkcji podaj osobno.';

  @override
  String get reasonMachineStopped => 'Maszyna zatrzymana';

  @override
  String get reasonMaterialJam => 'Zacięcie produktu / materiału';

  @override
  String get reasonMachineAlarm => 'Alarm maszyny';

  @override
  String get reasonShapeSize => 'Problem z kształtem / rozmiarem';

  @override
  String get reasonBakingColour => 'Problem z wypiekiem / kolorem';

  @override
  String get reasonPackagingSeal => 'Opakowanie się nie zamyka';

  @override
  String get reasonMaterialEmpty => 'Brak materiału produkcyjnego';

  @override
  String get reasonPackagingEmpty => 'Brak materiału opakowaniowego';

  @override
  String get reasonOperatorHelp => 'Wsparcie operatora';

  @override
  String get reasonTechnicalCheck => 'Potrzebna kontrola techniczna';

  @override
  String get roster => 'Grafik zmian';

  @override
  String get staff => 'Pracownicy';

  @override
  String get rosterHelp =>
      'Czas polski · poniedziałek–niedziela. To grafik zmian, nie ewidencja obecności.';

  @override
  String get weekOnly =>
      'Widzisz tylko bieżący tydzień swojego zespołu. W niedzielę nazwiska z kolejnego tygodnia pozostają ukryte; nadal możesz zostawić notatkę na jutro.';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String get tomorrow => 'Jutro';

  @override
  String get chooseDate => 'Wybierz datę';

  @override
  String get addShift => 'Zaplanuj zmianę';

  @override
  String get editShift => 'Edytuj zmianę';

  @override
  String get shiftStart => 'Początek';

  @override
  String get shiftEnd => 'Koniec';

  @override
  String get nightShiftHelp =>
      'Godzina końca wcześniejsza od początku oznacza następny dzień. Jedna zmiana na osobę dziennie, do 16 godzin. Przy powtórzeniu 02:00–02:59 podczas zmiany czasu używane jest pierwsze wystąpienie.';

  @override
  String get noShifts => 'Brak zaplanowanych zmian na ten dzień.';

  @override
  String get noEmployees => 'Brak aktywnych pracowników do zaplanowania.';

  @override
  String get activeEmployee => 'Aktywny pracownik';

  @override
  String get inactiveEmployee => 'Nieaktywny pracownik';

  @override
  String get staffHelp =>
      'Pracownicy z kontem firmowym. Dezaktywacja blokuje dostęp do aplikacji i zachowuje historię.';

  @override
  String get changeEmployeeStatus => 'Zmienić dostęp pracownika?';

  @override
  String get scheduled => 'Zaplanowano';

  @override
  String get shiftCancelled => 'Zmiana anulowana';

  @override
  String get cancelShift => 'Anuluj zmianę';

  @override
  String get cancelShiftHelp =>
      'Zmiana zostanie anulowana i pozostanie w historii grafiku.';

  @override
  String get endReport => 'Raport końca zmiany';

  @override
  String get writeReport => 'Napisz raport zmiany';

  @override
  String get reportProblems => 'Napotkane problemy';

  @override
  String get reportFollowUp => 'Co powinna sprawdzić następna zmiana';

  @override
  String get reportHelp =>
      'Po zapisaniu raportu nie można zmienić. Złóż go po rozpoczęciu zmiany, do 24 godzin od jej końca. Zostaw osobną notatkę, aby wyświetlić ostrzeżenie na ekranie głównym następnego dnia.';

  @override
  String get noReport => 'Brak raportu końca zmiany.';

  @override
  String get dailyIssues => 'Zgłoszenia związane z tą zmianą';

  @override
  String get dailyIssuesHelp =>
      'Zgłoszenia tej osoby lub obecnie jej przypisane, pokrywające się ze zmianą. Sprawdź też raporty przekazania zadań później przypisanych innym.';

  @override
  String get dayHandovers => 'Przekazania zapisane podczas zmiany';

  @override
  String get teamNotes => 'Notatki i ostrzeżenia';

  @override
  String get leaveNote => 'Zostaw notatkę';

  @override
  String get importantNote => 'Ważne / wymaga sprawdzenia';

  @override
  String get markRead => 'Oznacz jako przeczytane';

  @override
  String get readNote => 'Przeczytano';

  @override
  String get noteHelp =>
      'Notatka pojawi się na ekranie głównym zespołu wybranego dnia. Każdy potwierdza przeczytanie osobno.';

  @override
  String get noNotes => 'Brak notatek na ten dzień.';

  @override
  String get readReceipts => 'Przeczytane przez';

  @override
  String get noReaders => 'Jeszcze nie przeczytano.';

  @override
  String get nextTeam => 'Zespół na jutro';

  @override
  String get nextWeekHidden =>
      'Jutro zaczyna się nowy tydzień. Grafik otworzy się w poniedziałek; już teraz możesz zostawić notatkę.';

  @override
  String get invalidShift =>
      'Sprawdź nazwę i godziny zmiany. Maksymalny czas to 16 godzin.';

  @override
  String get shiftOverlap =>
      'Godziny nakładają się na zmianę tego pracownika w sąsiednim dniu.';

  @override
  String get reportLocked =>
      'Zmiany z raportem nie można edytować ani anulować.';

  @override
  String get reportTime =>
      'Raport można złożyć po rozpoczęciu zmiany, do 24 godzin od jej końca.';

  @override
  String get dstTime =>
      'Ta godzina nie istnieje podczas wiosennej zmiany czasu w Polsce. Wybierz inną.';

  @override
  String get onlineRoster =>
      'Oczekiwanie na połączenie z serwerem w celu sprawdzenia grafiku.';

  @override
  String get save => 'Zapisz';
}
