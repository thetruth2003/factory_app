import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Factory Check'**
  String get appTitle;

  /// No description provided for @machinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Machines'**
  String get machinesTitle;

  /// No description provided for @incidentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get incidentsTitle;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePolish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get languagePolish;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'role: {role}'**
  String roleLabel(String role);

  /// No description provided for @incidentReport.
  ///
  /// In en, this message translates to:
  /// **'Report fault'**
  String get incidentReport;

  /// No description provided for @incidentRepair.
  ///
  /// In en, this message translates to:
  /// **'Report repair'**
  String get incidentRepair;

  /// No description provided for @machineStatus.
  ///
  /// In en, this message translates to:
  /// **'Machine status'**
  String get machineStatus;

  /// No description provided for @selectedMachine.
  ///
  /// In en, this message translates to:
  /// **'Selected machine: {machine}'**
  String selectedMachine(String machine);

  /// No description provided for @noActiveIncidentNote.
  ///
  /// In en, this message translates to:
  /// **'Note: There is no active incident for this machine.'**
  String get noActiveIncidentNote;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmSend.
  ///
  /// In en, this message translates to:
  /// **'Yes, send it'**
  String get confirmSend;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusStopRequired.
  ///
  /// In en, this message translates to:
  /// **'Stop required'**
  String get statusStopRequired;

  /// No description provided for @statusNeedTechnician.
  ///
  /// In en, this message translates to:
  /// **'Technician needed'**
  String get statusNeedTechnician;

  /// No description provided for @categoryRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get categoryRed;

  /// No description provided for @categoryYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get categoryYellow;

  /// No description provided for @categoryBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get categoryBlue;

  /// No description provided for @categoryGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get categoryGreen;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @companyIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Company ID'**
  String get companyIdLabel;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Enter your account and password.'**
  String get loginMissingFields;

  /// No description provided for @loginNoUserDoc.
  ///
  /// In en, this message translates to:
  /// **'No record at users/\'{uid}\'. Add a role in Firestore.'**
  String loginNoUserDoc(Object uid);

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login error: {code}'**
  String loginError(String code);

  /// No description provided for @machinesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No machines.'**
  String get machinesEmpty;

  /// No description provided for @incidentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No incidents yet.'**
  String get incidentsEmpty;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String error(String msg);

  /// No description provided for @reportFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fault report form'**
  String get reportFormSubtitle;

  /// No description provided for @repairFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Repair report form'**
  String get repairFormSubtitle;

  /// No description provided for @errorCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fault code'**
  String get errorCodeLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @pickDateTime.
  ///
  /// In en, this message translates to:
  /// **'Pick date/time'**
  String get pickDateTime;

  /// No description provided for @reportedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Who reported it (name)'**
  String get reportedByLabel;

  /// No description provided for @writeName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get writeName;

  /// No description provided for @machineCanRun.
  ///
  /// In en, this message translates to:
  /// **'Can the machine still run?'**
  String get machineCanRun;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (issue / symptoms)'**
  String get descriptionLabel;

  /// No description provided for @redDescMin15.
  ///
  /// In en, this message translates to:
  /// **'For Red, description must be at least 15 characters'**
  String get redDescMin15;

  /// No description provided for @photoOptional.
  ///
  /// In en, this message translates to:
  /// **'Photo (optional)'**
  String get photoOptional;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @noPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos added yet.'**
  String get noPhotosYet;

  /// No description provided for @photosUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos...'**
  String get photosUploading;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// No description provided for @summaryMachine.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get summaryMachine;

  /// No description provided for @summaryErrorCode.
  ///
  /// In en, this message translates to:
  /// **'Fault code'**
  String get summaryErrorCode;

  /// No description provided for @summaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get summaryCategory;

  /// No description provided for @summaryDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date/time'**
  String get summaryDateTime;

  /// No description provided for @summaryReportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get summaryReportedBy;

  /// No description provided for @summaryCanRun.
  ///
  /// In en, this message translates to:
  /// **'Can run'**
  String get summaryCanRun;

  /// No description provided for @summaryPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get summaryPhotos;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get no;

  /// No description provided for @mustConfirmBeforeSend.
  ///
  /// In en, this message translates to:
  /// **'Confirm before sending.'**
  String get mustConfirmBeforeSend;

  /// No description provided for @alreadyHasActiveIncident.
  ///
  /// In en, this message translates to:
  /// **'This machine already has an active incident: {id}'**
  String alreadyHasActiveIncident(String id);

  /// No description provided for @incidentCreatedButNoId.
  ///
  /// In en, this message translates to:
  /// **'Incident was created but no id was returned (weird).'**
  String get incidentCreatedButNoId;

  /// No description provided for @faultReported.
  ///
  /// In en, this message translates to:
  /// **'Fault reported.'**
  String get faultReported;

  /// No description provided for @faultAndPhotosUploaded.
  ///
  /// In en, this message translates to:
  /// **'Fault + photo(s) uploaded.'**
  String get faultAndPhotosUploaded;

  /// No description provided for @submitError.
  ///
  /// In en, this message translates to:
  /// **'Submit error: {msg}'**
  String submitError(String msg);

  /// No description provided for @repairNoActiveIncidentInfo.
  ///
  /// In en, this message translates to:
  /// **'No active incident for this machine. You can still submit a repair note.'**
  String get repairNoActiveIncidentInfo;

  /// No description provided for @repairActiveFaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Active fault'**
  String get repairActiveFaultTitle;

  /// No description provided for @repairSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Repair submitted (resolved).'**
  String get repairSubmitted;

  /// No description provided for @repairSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Repair submit error: {msg}'**
  String repairSubmitError(String msg);

  /// No description provided for @repairedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Who repaired it (name)'**
  String get repairedByLabel;

  /// No description provided for @machineRunsAfterLabel.
  ///
  /// In en, this message translates to:
  /// **'Is the machine running?'**
  String get machineRunsAfterLabel;

  /// No description provided for @needsTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Need extra team/technician?'**
  String get needsTeamLabel;

  /// No description provided for @repairNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (what was done / status)'**
  String get repairNotesLabel;

  /// No description provided for @activeFaultDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Call details'**
  String get activeFaultDetailTitle;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @calls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get calls;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'Assigned to me'**
  String get mine;

  /// No description provided for @searchMachines.
  ///
  /// In en, this message translates to:
  /// **'Search machine or section'**
  String get searchMachines;

  /// No description provided for @activeCalls.
  ///
  /// In en, this message translates to:
  /// **'Active calls'**
  String get activeCalls;

  /// No description provided for @stoppedMachines.
  ///
  /// In en, this message translates to:
  /// **'Reported stopped'**
  String get stoppedMachines;

  /// No description provided for @waitingCalls.
  ///
  /// In en, this message translates to:
  /// **'Waiting for support'**
  String get waitingCalls;

  /// No description provided for @unassigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned yet'**
  String get unassigned;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get assignedTo;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Responsible team'**
  String get team;

  /// No description provided for @kind.
  ///
  /// In en, this message translates to:
  /// **'Call type'**
  String get kind;

  /// No description provided for @newCall.
  ///
  /// In en, this message translates to:
  /// **'Create call'**
  String get newCall;

  /// No description provided for @claim.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge & claim'**
  String get claim;

  /// No description provided for @startWork.
  ///
  /// In en, this message translates to:
  /// **'Start work'**
  String get startWork;

  /// No description provided for @waitForSupport.
  ///
  /// In en, this message translates to:
  /// **'Wait for support'**
  String get waitForSupport;

  /// No description provided for @resumeWork.
  ///
  /// In en, this message translates to:
  /// **'Resume work'**
  String get resumeWork;

  /// No description provided for @resolveCall.
  ///
  /// In en, this message translates to:
  /// **'Resolve call'**
  String get resolveCall;

  /// No description provided for @statusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get statusAcknowledged;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for support'**
  String get statusWaiting;

  /// No description provided for @teamOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get teamOperator;

  /// No description provided for @teamMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get teamMaintenance;

  /// No description provided for @teamQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get teamQuality;

  /// No description provided for @teamWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse / materials'**
  String get teamWarehouse;

  /// No description provided for @kindFault.
  ///
  /// In en, this message translates to:
  /// **'Fault'**
  String get kindFault;

  /// No description provided for @kindQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality issue'**
  String get kindQuality;

  /// No description provided for @kindMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material request'**
  String get kindMaterial;

  /// No description provided for @kindSupport.
  ///
  /// In en, this message translates to:
  /// **'Support request'**
  String get kindSupport;

  /// No description provided for @productionStopped.
  ///
  /// In en, this message translates to:
  /// **'Production stopped'**
  String get productionStopped;

  /// No description provided for @productionRunning.
  ///
  /// In en, this message translates to:
  /// **'Production running'**
  String get productionRunning;

  /// No description provided for @stateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Operating state not confirmed'**
  String get stateUnknown;

  /// No description provided for @productionState.
  ///
  /// In en, this message translates to:
  /// **'Reported production state'**
  String get productionState;

  /// No description provided for @noActiveCalls.
  ///
  /// In en, this message translates to:
  /// **'No active calls'**
  String get noActiveCalls;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No completed calls'**
  String get noHistory;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get timeline;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'Status, waiting reason or handover information'**
  String get noteHint;

  /// No description provided for @waitingReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for waiting'**
  String get waitingReason;

  /// No description provided for @resolutionNotes.
  ///
  /// In en, this message translates to:
  /// **'What was done?'**
  String get resolutionNotes;

  /// No description provided for @runningConfirmed.
  ///
  /// In en, this message translates to:
  /// **'I confirm production is running'**
  String get runningConfirmed;

  /// No description provided for @resolveHelp.
  ///
  /// In en, this message translates to:
  /// **'Use waiting status if production is still stopped or more support is needed.'**
  String get resolveHelp;

  /// No description provided for @recordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded at'**
  String get recordedAt;

  /// No description provided for @downtime.
  ///
  /// In en, this message translates to:
  /// **'Reported downtime'**
  String get downtime;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'Elapsed time'**
  String get elapsed;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @existingCall.
  ///
  /// In en, this message translates to:
  /// **'Opened the existing call. Add new information as a note.'**
  String get existingCall;

  /// No description provided for @cachedData.
  ///
  /// In en, this message translates to:
  /// **'Showing cached data. Check your connection for current status.'**
  String get cachedData;

  /// No description provided for @onlineRequired.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the action. Check your connection and retry.'**
  String get onlineRequired;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @photosPartial.
  ///
  /// In en, this message translates to:
  /// **'Call saved, but photos could not be uploaded. Retry the photos below.'**
  String get photosPartial;

  /// No description provided for @retryPhotos.
  ///
  /// In en, this message translates to:
  /// **'Retry photo upload'**
  String get retryPhotos;

  /// No description provided for @openCall.
  ///
  /// In en, this message translates to:
  /// **'Open call'**
  String get openCall;

  /// No description provided for @machineList.
  ///
  /// In en, this message translates to:
  /// **'Machine list'**
  String get machineList;

  /// No description provided for @factoryMap.
  ///
  /// In en, this message translates to:
  /// **'Factory map'**
  String get factoryMap;

  /// No description provided for @callDescription.
  ///
  /// In en, this message translates to:
  /// **'What happened or what is needed?'**
  String get callDescription;

  /// No description provided for @codeOptional.
  ///
  /// In en, this message translates to:
  /// **'Fault code (optional)'**
  String get codeOptional;

  /// No description provided for @signInAccount.
  ///
  /// In en, this message translates to:
  /// **'Email or company code'**
  String get signInAccount;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password / PIN'**
  String get password;

  /// No description provided for @sessionError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your account profile. Check your connection and user record.'**
  String get sessionError;

  /// No description provided for @notificationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone notifications could not be set up. You can follow in-app call alerts and the live list.'**
  String get notificationUnavailable;

  /// No description provided for @errorForbidden.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for this action.'**
  String get errorForbidden;

  /// No description provided for @errorAssigned.
  ///
  /// In en, this message translates to:
  /// **'Another worker has claimed this call.'**
  String get errorAssigned;

  /// No description provided for @errorStale.
  ///
  /// In en, this message translates to:
  /// **'This is no longer the current call for this machine. Refresh the list.'**
  String get errorStale;

  /// No description provided for @errorTransition.
  ///
  /// In en, this message translates to:
  /// **'The call status has changed. Check its current state.'**
  String get errorTransition;

  /// No description provided for @errorTime.
  ///
  /// In en, this message translates to:
  /// **'Time cannot be in the future or before the start.'**
  String get errorTime;

  /// No description provided for @errorNote.
  ///
  /// In en, this message translates to:
  /// **'Please enter a short description.'**
  String get errorNote;

  /// No description provided for @errorRunning.
  ///
  /// In en, this message translates to:
  /// **'Production must be confirmed running before resolution.'**
  String get errorRunning;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Record not found.'**
  String get notFound;

  /// No description provided for @photoLimit.
  ///
  /// In en, this message translates to:
  /// **'You can attach up to 5 photos.'**
  String get photoLimit;

  /// No description provided for @handover.
  ///
  /// In en, this message translates to:
  /// **'Shift handover'**
  String get handover;

  /// No description provided for @handoverHelp.
  ///
  /// In en, this message translates to:
  /// **'Record shift notes and outstanding calls for the incoming shift to acknowledge.'**
  String get handoverHelp;

  /// No description provided for @productionResume.
  ///
  /// In en, this message translates to:
  /// **'Production resumed'**
  String get productionResume;

  /// No description provided for @productionStop.
  ///
  /// In en, this message translates to:
  /// **'Report a stop'**
  String get productionStop;

  /// No description provided for @confirmState.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you want to update the reported production state.'**
  String get confirmState;

  /// No description provided for @reportSummary.
  ///
  /// In en, this message translates to:
  /// **'Call summary'**
  String get reportSummary;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @roleWatcher.
  ///
  /// In en, this message translates to:
  /// **'Monitoring team'**
  String get roleWatcher;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivity;

  /// No description provided for @createdEvent.
  ///
  /// In en, this message translates to:
  /// **'Call created'**
  String get createdEvent;

  /// No description provided for @photoEvent.
  ///
  /// In en, this message translates to:
  /// **'Photo attached'**
  String get photoEvent;

  /// No description provided for @noteEvent.
  ///
  /// In en, this message translates to:
  /// **'Note added'**
  String get noteEvent;

  /// No description provided for @changedEvent.
  ///
  /// In en, this message translates to:
  /// **'Status changed'**
  String get changedEvent;

  /// No description provided for @allTeams.
  ///
  /// In en, this message translates to:
  /// **'All teams'**
  String get allTeams;

  /// No description provided for @newHandover.
  ///
  /// In en, this message translates to:
  /// **'Create handover'**
  String get newHandover;

  /// No description provided for @noHandovers.
  ///
  /// In en, this message translates to:
  /// **'No handovers yet.'**
  String get noHandovers;

  /// No description provided for @handoverFrom.
  ///
  /// In en, this message translates to:
  /// **'Handed over by'**
  String get handoverFrom;

  /// No description provided for @handoverReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get handoverReceived;

  /// No description provided for @handoverPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting receipt'**
  String get handoverPending;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @newHandoverHelp.
  ///
  /// In en, this message translates to:
  /// **'Name the shift, leave notes for the incoming team and select calls to hand over.'**
  String get newHandoverHelp;

  /// No description provided for @shiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift name / hours'**
  String get shiftLabel;

  /// No description provided for @shiftHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. 11 October · Night 22:00–06:00'**
  String get shiftHint;

  /// No description provided for @handoverNotes.
  ///
  /// In en, this message translates to:
  /// **'Shift notes'**
  String get handoverNotes;

  /// No description provided for @handoverNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Pending materials, machines to check, important observations…'**
  String get handoverNotesHint;

  /// No description provided for @selectHandoverCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls to hand over ({count}/6)'**
  String selectHandoverCalls(int count);

  /// No description provided for @handoverSelectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Select up to 6 active calls. You can also leave shift notes without selecting calls.'**
  String get handoverSelectionHelp;

  /// No description provided for @saveHandover.
  ///
  /// In en, this message translates to:
  /// **'Save handover'**
  String get saveHandover;

  /// No description provided for @acceptHandover.
  ///
  /// In en, this message translates to:
  /// **'Receive handover'**
  String get acceptHandover;

  /// No description provided for @handoverAcceptHelp.
  ///
  /// In en, this message translates to:
  /// **'Your receipt will be recorded. Selected active calls still assigned to the sender will transfer to you. Calls owned by others will stay with them.'**
  String get handoverAcceptHelp;

  /// No description provided for @handoverReadReceiptHelp.
  ///
  /// In en, this message translates to:
  /// **'Your receipt of the shift notes will be recorded. The monitoring role does not transfer call ownership.'**
  String get handoverReadReceiptHelp;

  /// No description provided for @handoverTransferred.
  ///
  /// In en, this message translates to:
  /// **'Active calls transferred to recipient: {count}'**
  String handoverTransferred(int count);

  /// No description provided for @handoverSnapshotHelp.
  ///
  /// In en, this message translates to:
  /// **'The details below reflect the time of handover. Open a call to see its current state.'**
  String get handoverSnapshotHelp;

  /// No description provided for @noHandoverCalls.
  ///
  /// In en, this message translates to:
  /// **'This handover contains shift notes only.'**
  String get noHandoverCalls;

  /// No description provided for @errorHandover.
  ///
  /// In en, this message translates to:
  /// **'Check the shift details. A maximum of 6 calls can be included.'**
  String get errorHandover;

  /// No description provided for @errorHandoverChanged.
  ///
  /// In en, this message translates to:
  /// **'A selected call is no longer active. Your notes are preserved; select calls again from the current list.'**
  String get errorHandoverChanged;

  /// No description provided for @errorHandoverAccepted.
  ///
  /// In en, this message translates to:
  /// **'Another user has already received this handover.'**
  String get errorHandoverAccepted;

  /// No description provided for @errorHandoverSelf.
  ///
  /// In en, this message translates to:
  /// **'Another worker must receive your handover.'**
  String get errorHandoverSelf;

  /// No description provided for @handoverEvent.
  ///
  /// In en, this message translates to:
  /// **'Owner changed through shift handover'**
  String get handoverEvent;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @reportIntro.
  ///
  /// In en, this message translates to:
  /// **'Review calls and reported machine downtime for a date range.'**
  String get reportIntro;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @lastSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lastSevenDays;

  /// No description provided for @lastThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get lastThirtyDays;

  /// No description provided for @callsOpenedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Calls opened'**
  String get callsOpenedInPeriod;

  /// No description provided for @callsResolvedInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Calls resolved'**
  String get callsResolvedInPeriod;

  /// No description provided for @machineDowntimeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total machine downtime'**
  String get machineDowntimeTotal;

  /// No description provided for @firstResponseAverage.
  ///
  /// In en, this message translates to:
  /// **'Average time to first acknowledgement'**
  String get firstResponseAverage;

  /// No description provided for @responseSampleCount.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgement average uses {count} calls opened in this period with a known first acknowledgement time.'**
  String responseSampleCount(int count);

  /// No description provided for @reportMethodHelp.
  ///
  /// In en, this message translates to:
  /// **'Downtime sums reported intervals within the selected dates; ongoing stops count up to now. Machines are summed separately, so this is not total factory shutdown time. Dates use the device time zone.'**
  String get reportMethodHelp;

  /// No description provided for @reportIncomplete.
  ///
  /// In en, this message translates to:
  /// **'{count} legacy calls overlapping this period may have incomplete downtime history. Only known intervals are included; the total may understate production loss.'**
  String reportIncomplete(int count);

  /// No description provided for @machineBreakdown.
  ///
  /// In en, this message translates to:
  /// **'By machine'**
  String get machineBreakdown;

  /// No description provided for @noPeriodData.
  ///
  /// In en, this message translates to:
  /// **'No records for this period.'**
  String get noPeriodData;

  /// No description provided for @reportUpdated.
  ///
  /// In en, this message translates to:
  /// **'Calculated at'**
  String get reportUpdated;

  /// No description provided for @handoverTeamOnly.
  ///
  /// In en, this message translates to:
  /// **'A worker from the target team or a supervisor can receive this handover.'**
  String get handoverTeamOnly;

  /// No description provided for @trainingMode.
  ///
  /// In en, this message translates to:
  /// **'FIELD TEST'**
  String get trainingMode;

  /// No description provided for @trainingBanner.
  ///
  /// In en, this message translates to:
  /// **'You are practicing with sample machines. Use the factory’s existing communication process for real faults.'**
  String get trainingBanner;

  /// No description provided for @trainingStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Two-device test steps'**
  String get trainingStepsTitle;

  /// No description provided for @trainingSteps.
  ///
  /// In en, this message translates to:
  /// **'1. Keep the app open on both devices.\n2. With the monitoring account, create a sample call for TEST-1.\n3. With the operator account, find, claim and start work on the call.\n4. Report that production resumed, then resolve the call with a note.\n5. Check history and reports on both devices.\n6. Record missing calls and any difficult steps.\n\nBackground notifications require server setup and a separate device test.'**
  String get trainingSteps;

  /// No description provided for @incomingCall.
  ///
  /// In en, this message translates to:
  /// **'New call: {machine}'**
  String incomingCall(String machine);

  /// No description provided for @incomingCallCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new calls received'**
  String incomingCallCount(int count);

  /// No description provided for @incomingCallHelp.
  ///
  /// In en, this message translates to:
  /// **'Open the call to check the details.'**
  String get incomingCallHelp;

  /// No description provided for @soundTest.
  ///
  /// In en, this message translates to:
  /// **'Test notification sound'**
  String get soundTest;

  /// No description provided for @soundTestBody.
  ///
  /// In en, this message translates to:
  /// **'This is a test notification.'**
  String get soundTestBody;

  /// No description provided for @soundTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent. If you heard no sound, check notification volume, the Factory Check notification channel and Do Not Disturb.'**
  String get soundTestSent;

  /// No description provided for @soundTestDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled or unsupported on this device. Allow Factory Check notifications in Android settings.'**
  String get soundTestDisabled;

  /// No description provided for @testFeedback.
  ///
  /// In en, this message translates to:
  /// **'Test feedback'**
  String get testFeedback;

  /// No description provided for @feedbackHelp.
  ///
  /// In en, this message translates to:
  /// **'What was easy or difficult? Your feedback is saved in the test company with your name and role for review after the trial.'**
  String get feedbackHelp;

  /// No description provided for @feedbackEase.
  ///
  /// In en, this message translates to:
  /// **'Ease of use'**
  String get feedbackEase;

  /// No description provided for @feedbackScale.
  ///
  /// In en, this message translates to:
  /// **'1 = very difficult · 5 = very easy'**
  String get feedbackScale;

  /// No description provided for @feedbackNotes.
  ///
  /// In en, this message translates to:
  /// **'A difficult step or your suggestion'**
  String get feedbackNotes;

  /// No description provided for @feedbackRequired.
  ///
  /// In en, this message translates to:
  /// **'Please complete this field.'**
  String get feedbackRequired;

  /// No description provided for @feedbackSend.
  ///
  /// In en, this message translates to:
  /// **'Save feedback'**
  String get feedbackSend;

  /// No description provided for @feedbackSaved.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been saved.'**
  String get feedbackSaved;

  /// No description provided for @quickReason.
  ///
  /// In en, this message translates to:
  /// **'Quick reason (optional)'**
  String get quickReason;

  /// No description provided for @quickReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason or write a description. These are starter options for the trial; report production state separately.'**
  String get quickReasonHelp;

  /// No description provided for @reasonMachineStopped.
  ///
  /// In en, this message translates to:
  /// **'Machine stopped'**
  String get reasonMachineStopped;

  /// No description provided for @reasonMaterialJam.
  ///
  /// In en, this message translates to:
  /// **'Product / material jam'**
  String get reasonMaterialJam;

  /// No description provided for @reasonMachineAlarm.
  ///
  /// In en, this message translates to:
  /// **'Machine alarm'**
  String get reasonMachineAlarm;

  /// No description provided for @reasonShapeSize.
  ///
  /// In en, this message translates to:
  /// **'Shape / size issue'**
  String get reasonShapeSize;

  /// No description provided for @reasonBakingColour.
  ///
  /// In en, this message translates to:
  /// **'Baking / colour issue'**
  String get reasonBakingColour;

  /// No description provided for @reasonPackagingSeal.
  ///
  /// In en, this message translates to:
  /// **'Package not sealing'**
  String get reasonPackagingSeal;

  /// No description provided for @reasonMaterialEmpty.
  ///
  /// In en, this message translates to:
  /// **'Production material depleted'**
  String get reasonMaterialEmpty;

  /// No description provided for @reasonPackagingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Packaging material depleted'**
  String get reasonPackagingEmpty;

  /// No description provided for @reasonOperatorHelp.
  ///
  /// In en, this message translates to:
  /// **'Operator support'**
  String get reasonOperatorHelp;

  /// No description provided for @reasonTechnicalCheck.
  ///
  /// In en, this message translates to:
  /// **'Technical check needed'**
  String get reasonTechnicalCheck;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
