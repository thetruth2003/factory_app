// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Factory Check';

  @override
  String get machinesTitle => 'Machines';

  @override
  String get incidentsTitle => 'Calls';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePolish => 'Polish';

  @override
  String roleLabel(String role) {
    return 'role: $role';
  }

  @override
  String get incidentReport => 'Report fault';

  @override
  String get incidentRepair => 'Report repair';

  @override
  String get machineStatus => 'Machine status';

  @override
  String selectedMachine(String machine) {
    return 'Selected machine: $machine';
  }

  @override
  String get noActiveIncidentNote =>
      'Note: There is no active incident for this machine.';

  @override
  String get send => 'Send';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmSend => 'Yes, send it';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusStopRequired => 'Stop required';

  @override
  String get statusNeedTechnician => 'Technician needed';

  @override
  String get categoryRed => 'Red';

  @override
  String get categoryYellow => 'Yellow';

  @override
  String get categoryBlue => 'Blue';

  @override
  String get categoryGreen => 'Green';

  @override
  String get loginWelcome => 'Welcome';

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get companyIdLabel => 'Company ID';

  @override
  String get pinLabel => 'PIN';

  @override
  String get loginButton => 'Login';

  @override
  String get loginMissingFields => 'Enter your account and password.';

  @override
  String loginNoUserDoc(Object uid) {
    return 'No record at users/\'$uid\'. Add a role in Firestore.';
  }

  @override
  String loginError(String code) {
    return 'Login error: $code';
  }

  @override
  String get machinesEmpty => 'No machines.';

  @override
  String get incidentsEmpty => 'No incidents yet.';

  @override
  String error(String msg) {
    return 'Error: $msg';
  }

  @override
  String get reportFormSubtitle => 'Fault report form';

  @override
  String get repairFormSubtitle => 'Repair report form';

  @override
  String get errorCodeLabel => 'Fault code';

  @override
  String get categoryLabel => 'Category';

  @override
  String get choose => 'Choose';

  @override
  String get pickDateTime => 'Pick date/time';

  @override
  String get reportedByLabel => 'Who reported it (name)';

  @override
  String get writeName => 'Enter a name';

  @override
  String get machineCanRun => 'Can the machine still run?';

  @override
  String get descriptionLabel => 'Description (issue / symptoms)';

  @override
  String get redDescMin15 =>
      'For Red, description must be at least 15 characters';

  @override
  String get photoOptional => 'Photo (optional)';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get noPhotosYet => 'No photos added yet.';

  @override
  String get photosUploading => 'Uploading photos...';

  @override
  String get summaryTitle => 'Summary';

  @override
  String get summaryMachine => 'Machine';

  @override
  String get summaryErrorCode => 'Fault code';

  @override
  String get summaryCategory => 'Category';

  @override
  String get summaryDateTime => 'Date/time';

  @override
  String get summaryReportedBy => 'Reported by';

  @override
  String get summaryCanRun => 'Can run';

  @override
  String get summaryPhotos => 'Photos';

  @override
  String get yes => 'yes';

  @override
  String get no => 'no';

  @override
  String get mustConfirmBeforeSend => 'Confirm before sending.';

  @override
  String alreadyHasActiveIncident(String id) {
    return 'This machine already has an active incident: $id';
  }

  @override
  String get incidentCreatedButNoId =>
      'Incident was created but no id was returned (weird).';

  @override
  String get faultReported => 'Fault reported.';

  @override
  String get faultAndPhotosUploaded => 'Fault + photo(s) uploaded.';

  @override
  String submitError(String msg) {
    return 'Submit error: $msg';
  }

  @override
  String get repairNoActiveIncidentInfo =>
      'No active incident for this machine. You can still submit a repair note.';

  @override
  String get repairActiveFaultTitle => 'Active fault';

  @override
  String get repairSubmitted => 'Repair submitted (resolved).';

  @override
  String repairSubmitError(String msg) {
    return 'Repair submit error: $msg';
  }

  @override
  String get repairedByLabel => 'Who repaired it (name)';

  @override
  String get machineRunsAfterLabel => 'Is the machine running?';

  @override
  String get needsTeamLabel => 'Need extra team/technician?';

  @override
  String get repairNotesLabel => 'Notes (what was done / status)';

  @override
  String get activeFaultDetailTitle => 'Call details';

  @override
  String get overview => 'Overview';

  @override
  String get calls => 'Calls';

  @override
  String get history => 'History';

  @override
  String get all => 'All';

  @override
  String get mine => 'Assigned to me';

  @override
  String get searchMachines => 'Search machine or section';

  @override
  String get activeCalls => 'Active calls';

  @override
  String get stoppedMachines => 'Reported stopped';

  @override
  String get waitingCalls => 'Waiting for support';

  @override
  String get unassigned => 'Not assigned yet';

  @override
  String get assignedTo => 'Assigned to';

  @override
  String get team => 'Responsible team';

  @override
  String get kind => 'Call type';

  @override
  String get newCall => 'Create call';

  @override
  String get claim => 'Acknowledge & claim';

  @override
  String get startWork => 'Start work';

  @override
  String get waitForSupport => 'Wait for support';

  @override
  String get resumeWork => 'Resume work';

  @override
  String get resolveCall => 'Resolve call';

  @override
  String get statusAcknowledged => 'Acknowledged';

  @override
  String get statusWaiting => 'Waiting for support';

  @override
  String get teamOperator => 'Operator';

  @override
  String get teamMaintenance => 'Maintenance';

  @override
  String get teamQuality => 'Quality';

  @override
  String get teamWarehouse => 'Warehouse / materials';

  @override
  String get kindFault => 'Fault';

  @override
  String get kindQuality => 'Quality issue';

  @override
  String get kindMaterial => 'Material request';

  @override
  String get kindSupport => 'Support request';

  @override
  String get productionStopped => 'Production stopped';

  @override
  String get productionRunning => 'Production running';

  @override
  String get stateUnknown => 'Operating state not confirmed';

  @override
  String get productionState => 'Reported production state';

  @override
  String get noActiveCalls => 'No active calls';

  @override
  String get noResults => 'No results';

  @override
  String get noHistory => 'No completed calls';

  @override
  String get addNote => 'Add note';

  @override
  String get timeline => 'Activity';

  @override
  String get noteHint => 'Status, waiting reason or handover information';

  @override
  String get waitingReason => 'Reason for waiting';

  @override
  String get resolutionNotes => 'What was done?';

  @override
  String get runningConfirmed => 'I confirm production is running';

  @override
  String get resolveHelp =>
      'Use waiting status if production is still stopped or more support is needed.';

  @override
  String get recordedAt => 'Recorded at';

  @override
  String get downtime => 'Reported downtime';

  @override
  String get elapsed => 'Elapsed time';

  @override
  String get minutes => 'min';

  @override
  String get existingCall =>
      'Opened the existing call. Add new information as a note.';

  @override
  String get cachedData =>
      'Showing cached data. Check your connection for current status.';

  @override
  String get onlineRequired =>
      'Could not complete the action. Check your connection and retry.';

  @override
  String get saved => 'Saved';

  @override
  String get retry => 'Retry';

  @override
  String get photosPartial =>
      'Call saved, but photos could not be uploaded. Retry the photos below.';

  @override
  String get retryPhotos => 'Retry photo upload';

  @override
  String get openCall => 'Open call';

  @override
  String get machineList => 'Machine list';

  @override
  String get factoryMap => 'Factory map';

  @override
  String get callDescription => 'What happened or what is needed?';

  @override
  String get codeOptional => 'Fault code (optional)';

  @override
  String get signInAccount => 'Email or company code';

  @override
  String get password => 'Password / PIN';

  @override
  String get sessionError =>
      'Could not load your account profile. Check your connection and user record.';

  @override
  String get notificationUnavailable =>
      'Phone notifications could not be set up. You can follow in-app call alerts and the live list.';

  @override
  String get errorForbidden => 'You do not have permission for this action.';

  @override
  String get errorAssigned => 'Another worker has claimed this call.';

  @override
  String get errorStale =>
      'This is no longer the current call for this machine. Refresh the list.';

  @override
  String get errorTransition =>
      'The call status has changed. Check its current state.';

  @override
  String get errorTime => 'Time cannot be in the future or before the start.';

  @override
  String get errorNote => 'Please enter a short description.';

  @override
  String get errorRunning =>
      'Production must be confirmed running before resolution.';

  @override
  String get notFound => 'Record not found.';

  @override
  String get photoLimit => 'You can attach up to 5 photos.';

  @override
  String get handover => 'Shift handover';

  @override
  String get handoverHelp =>
      'Record shift notes and outstanding calls for the incoming shift to acknowledge.';

  @override
  String get productionResume => 'Production resumed';

  @override
  String get productionStop => 'Report a stop';

  @override
  String get confirmState =>
      'Confirm that you want to update the reported production state.';

  @override
  String get reportSummary => 'Call summary';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get roleSupervisor => 'Supervisor';

  @override
  String get roleWatcher => 'Monitoring team';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get noActivity => 'No activity yet';

  @override
  String get createdEvent => 'Call created';

  @override
  String get photoEvent => 'Photo attached';

  @override
  String get noteEvent => 'Note added';

  @override
  String get changedEvent => 'Status changed';

  @override
  String get allTeams => 'All teams';

  @override
  String get newHandover => 'Create handover';

  @override
  String get noHandovers => 'No handovers yet.';

  @override
  String get handoverFrom => 'Handed over by';

  @override
  String get handoverReceived => 'Received';

  @override
  String get handoverPending => 'Awaiting receipt';

  @override
  String get loadMore => 'Load more';

  @override
  String get newHandoverHelp =>
      'Name the shift, leave notes for the incoming team and select calls to hand over.';

  @override
  String get shiftLabel => 'Shift name / hours';

  @override
  String get shiftHint => 'E.g. 11 October · Night 22:00–06:00';

  @override
  String get handoverNotes => 'Shift notes';

  @override
  String get handoverNotesHint =>
      'Pending materials, machines to check, important observations…';

  @override
  String selectHandoverCalls(int count) {
    return 'Calls to hand over ($count/6)';
  }

  @override
  String get handoverSelectionHelp =>
      'Select up to 6 active calls. You can also leave shift notes without selecting calls.';

  @override
  String get saveHandover => 'Save handover';

  @override
  String get acceptHandover => 'Receive handover';

  @override
  String get handoverAcceptHelp =>
      'Your receipt will be recorded. Selected active calls still assigned to the sender will transfer to you. Calls owned by others will stay with them.';

  @override
  String get handoverReadReceiptHelp =>
      'Your receipt of the shift notes will be recorded. The monitoring role does not transfer call ownership.';

  @override
  String handoverTransferred(int count) {
    return 'Active calls transferred to recipient: $count';
  }

  @override
  String get handoverSnapshotHelp =>
      'The details below reflect the time of handover. Open a call to see its current state.';

  @override
  String get noHandoverCalls => 'This handover contains shift notes only.';

  @override
  String get errorHandover =>
      'Check the shift details. A maximum of 6 calls can be included.';

  @override
  String get errorHandoverChanged =>
      'A selected call is no longer active. Your notes are preserved; select calls again from the current list.';

  @override
  String get errorHandoverAccepted =>
      'Another user has already received this handover.';

  @override
  String get errorHandoverSelf => 'Another worker must receive your handover.';

  @override
  String get handoverEvent => 'Owner changed through shift handover';

  @override
  String get reports => 'Reports';

  @override
  String get reportIntro =>
      'Review calls and reported machine downtime for a date range.';

  @override
  String get today => 'Today';

  @override
  String get lastSevenDays => 'Last 7 days';

  @override
  String get lastThirtyDays => 'Last 30 days';

  @override
  String get callsOpenedInPeriod => 'Calls opened';

  @override
  String get callsResolvedInPeriod => 'Calls resolved';

  @override
  String get machineDowntimeTotal => 'Total machine downtime';

  @override
  String get firstResponseAverage => 'Average time to first acknowledgement';

  @override
  String responseSampleCount(int count) {
    return 'Acknowledgement average uses $count calls opened in this period with a known first acknowledgement time.';
  }

  @override
  String get reportMethodHelp =>
      'Downtime sums reported intervals within the selected dates; ongoing stops count up to now. Machines are summed separately, so this is not total factory shutdown time. Dates use the device time zone.';

  @override
  String reportIncomplete(int count) {
    return '$count legacy calls overlapping this period may have incomplete downtime history. Only known intervals are included; the total may understate production loss.';
  }

  @override
  String get machineBreakdown => 'By machine';

  @override
  String get noPeriodData => 'No records for this period.';

  @override
  String get reportUpdated => 'Calculated at';

  @override
  String get handoverTeamOnly =>
      'A worker from the target team or a supervisor can receive this handover.';

  @override
  String get trainingMode => 'FIELD TEST';

  @override
  String get trainingBanner =>
      'You are practicing with sample machines. Use the factory’s existing communication process for real faults.';

  @override
  String get trainingStepsTitle => 'Two-device test steps';

  @override
  String get trainingSteps =>
      '1. Keep the app open on both devices.\n2. With the monitoring account, create a sample call for TEST-1.\n3. With the operator account, find, claim and start work on the call.\n4. Report that production resumed, then resolve the call with a note.\n5. Check history and reports on both devices.\n6. Record missing calls and any difficult steps.\n\nBackground notifications require server setup and a separate device test.';

  @override
  String incomingCall(String machine) {
    return 'New call: $machine';
  }

  @override
  String incomingCallCount(int count) {
    return '$count new calls received';
  }

  @override
  String get incomingCallHelp => 'Open the call to check the details.';

  @override
  String get soundTest => 'Test notification sound';

  @override
  String get soundTestBody => 'This is a test notification.';

  @override
  String get soundTestSent =>
      'Test notification sent. If you heard no sound, check notification volume, the Factory Check notification channel and Do Not Disturb.';

  @override
  String get soundTestDisabled =>
      'Notifications are disabled or unsupported on this device. Allow Factory Check notifications in Android settings.';

  @override
  String get testFeedback => 'Test feedback';

  @override
  String get feedbackHelp =>
      'What was easy or difficult? Your feedback is saved in the test company with your name and role for review after the trial.';

  @override
  String get feedbackEase => 'Ease of use';

  @override
  String get feedbackScale => '1 = very difficult · 5 = very easy';

  @override
  String get feedbackNotes => 'A difficult step or your suggestion';

  @override
  String get feedbackRequired => 'Please complete this field.';

  @override
  String get feedbackSend => 'Save feedback';

  @override
  String get feedbackSaved => 'Your feedback has been saved.';

  @override
  String get quickReason => 'Quick reason (optional)';

  @override
  String get quickReasonHelp =>
      'Choose a reason or write a description. These are starter options for the trial; report production state separately.';

  @override
  String get reasonMachineStopped => 'Machine stopped';

  @override
  String get reasonMaterialJam => 'Product / material jam';

  @override
  String get reasonMachineAlarm => 'Machine alarm';

  @override
  String get reasonShapeSize => 'Shape / size issue';

  @override
  String get reasonBakingColour => 'Baking / colour issue';

  @override
  String get reasonPackagingSeal => 'Package not sealing';

  @override
  String get reasonMaterialEmpty => 'Production material depleted';

  @override
  String get reasonPackagingEmpty => 'Packaging material depleted';

  @override
  String get reasonOperatorHelp => 'Operator support';

  @override
  String get reasonTechnicalCheck => 'Technical check needed';
}
