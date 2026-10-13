import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/workflow.dart';
import '../models/call_alert_tracker.dart';
import '../services/notification_service.dart';
import '../ui/call_widgets.dart';
import 'incident_detail.dart';
import 'login_screen.dart';
import 'report_incident_page.dart';
import 'handover_page.dart';
import 'reports_page.dart';
import 'test_feedback_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.actor,
    this.db,
    this.onSignOut,
    this.enableNotifications = true,
  });
  final FactoryUser actor;
  final FirebaseFirestore? db;
  final Future<void> Function()? onSignOut;
  final bool enableNotifications;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FirebaseFirestore _db = widget.db ?? FirebaseFirestore.instance;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _calls;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _machines;
  Timer? _timer;
  int _page = 0;
  bool _mine = false;
  bool _map = false;
  String _team = '';
  String _search = '';
  bool _notificationError = false;
  bool _testingSound = false;
  late final _alerts = CallAlertTracker(widget.actor);
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callAlerts;
  int _subscription = 0;
  bool get _isForeground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  @override
  void initState() {
    super.initState();
    _subscribe();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    if (widget.enableNotifications) _initNotifications();
  }

  void _subscribe() {
    final subscription = ++_subscription;
    _callAlerts?.cancel();
    _machines = _db
        .collection('machines')
        .where('companyId', isEqualTo: widget.actor.companyId)
        .snapshots(includeMetadataChanges: true);
    final callsQuery = _db
        .collection('incidents')
        .where('createdByCompanyId', isEqualTo: widget.actor.companyId);
    _calls = callsQuery.snapshots(includeMetadataChanges: true);
    // Each listener gets its own initial snapshot, even if machines load later.
    _callAlerts = callsQuery
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            if (!mounted || subscription != _subscription) return;
            final incoming = _alerts.consume(
              snapshot.docs.map((d) => CallAlert(d.id, d.data())),
              fromCache: snapshot.metadata.isFromCache,
              hasPendingWrites: snapshot.metadata.hasPendingWrites,
              foreground: _isForeground,
            );
            if (incoming.isEmpty) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_isForeground || subscription != _subscription) {
                return;
              }
              _showIncoming(incoming);
            });
          },
          onError: (Object _) {
            /* The page displays the query error and retry. */
          },
        );
  }

  void _showIncoming(List<CallAlert> incoming) {
    final t = AppLocalizations.of(context);
    final call = incoming.last;
    final machine = (call.data['machineKey'] ?? call.data['machineId'] ?? '')
        .toString();
    final title = incoming.length == 1
        ? t.incomingCall(machine)
        : t.incomingCallCount(incoming.length);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 12),
        content: Text(title),
        action: SnackBarAction(
          label: t.openCall,
          onPressed: () => _openCall(call.id),
        ),
      ),
    );
    if (widget.enableNotifications) {
      unawaited(
        NotificationService.instance
            .showCall(
              companyId: widget.actor.companyId,
              incidentId: call.id,
              title: title,
              body: t.incomingCallHelp,
            )
            .then(
              (_) {},
              onError: (Object _) {
                if (mounted) setState(() => _notificationError = true);
              },
            ),
      );
    }
  }

  Future<void> _testSound() async {
    if (_testingSound) return;
    setState(() => _testingSound = true);
    final t = AppLocalizations.of(context);
    try {
      final sent =
          widget.enableNotifications &&
          await NotificationService.instance.testSound(
            companyId: widget.actor.companyId,
            title: t.soundTest,
            body: t.soundTestBody,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sent ? t.soundTestSent : t.soundTestDisabled),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _testingSound = false);
    }
  }

  Future<void> _feedback() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TestFeedbackPage(actor: widget.actor, db: _db),
      ),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).feedbackSaved)),
    );
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService.instance.init(
        companyId: widget.actor.companyId,
        onOpen: _openCall,
        foregroundCallsHandled: true,
      );
    } catch (_) {
      if (mounted) setState(() => _notificationError = true);
    }
  }

  @override
  void dispose() {
    _callAlerts?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _openCall(String id) {
    if (!mounted || id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            IncidentDetailPage(incidentId: id, actor: widget.actor, db: _db),
      ),
    );
  }

  Future<void> _newCall(
    QueryDocumentSnapshot<Map<String, dynamic>> machine,
  ) async {
    final data = machine.data();
    final active = (data['activeIncidentId'] ?? '').toString();
    if (active.isNotEmpty && data['activeStatus'] != 'resolved') {
      _openCall(active);
      return;
    }
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ReportIncidentPage(
          actor: widget.actor,
          machineId: machine.id,
          machineKey: _machineName(machine),
          db: _db,
        ),
      ),
    );
    if (mounted && id != null) _openCall(id);
  }

  String _machineName(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] ?? doc.id).toString();
    final section = (data['section'] ?? '').toString();
    return name.length == 1 && section.isNotEmpty ? section + name : name;
  }

  Widget _error(Object error) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorLabel(AppLocalizations.of(context), error),
            textAlign: TextAlign.center,
          ),
        ),
        FilledButton(
          onPressed: () => setState(_subscribe),
          child: Text(AppLocalizations.of(context).retry),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SessionTitle(title: t.appTitle, actor: widget.actor),
        actions: [
          IconButton(
            tooltip: t.reports,
            icon: const Icon(Icons.assessment_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportsPage(actor: widget.actor, db: _db),
              ),
            ),
          ),
          const LanguageMenu(),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: t.logout,
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  // Clear detail routes, so a signed-out session cannot remain visible.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  await widget.onSignOut!();
                } catch (e) {
                  if (context.mounted) showFailure(context, e);
                }
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _machines,
        builder: (context, machinesSnap) {
          if (machinesSnap.hasError) return _error(machinesSnap.error!);
          if (!machinesSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final machines =
              machinesSnap.data!.docs
                  .where((d) => d.data()['companyId'] == widget.actor.companyId)
                  .toList()
                ..sort((a, b) => _machineName(a).compareTo(_machineName(b)));
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _calls,
            builder: (context, callsSnap) {
              if (callsSnap.hasError) return _error(callsSnap.error!);
              if (!callsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final calls = callsSnap.data!.docs.toList()
                ..sort((a, b) {
                  final aDate =
                      dateValue(a.data()['createdAt']) ?? DateTime(1970);
                  final bDate =
                      dateValue(b.data()['createdAt']) ?? DateTime(1970);
                  return bDate.compareTo(aDate);
                });
              final active = calls
                  .where((d) => d.data()['status'] != 'resolved')
                  .toList();
              final closed = calls
                  .where((d) => d.data()['status'] == 'resolved')
                  .toList();
              return Column(
                children: [
                  if (widget.actor.isTraining)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      color: const Color(0xFFFFE8AC),
                      child: Text(t.trainingBanner),
                    ),
                  if (machinesSnap.data!.metadata.isFromCache ||
                      callsSnap.data!.metadata.isFromCache)
                    const CacheNotice(),
                  if (_notificationError)
                    MaterialBanner(
                      content: Text(t.notificationUnavailable),
                      actions: [
                        TextButton(
                          onPressed: () {
                            setState(() => _notificationError = false);
                            _initNotifications();
                          },
                          child: Text(t.retry),
                        ),
                      ],
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      children: [
                        Text(
                          '${widget.actor.name} · ${teamLabel(t, widget.actor.role)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          [
                            t.overview,
                            t.machinesTitle,
                            t.history,
                            t.handover,
                          ][_page],
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (_page == 0) ...[
                          if (widget.actor.isTraining) ...[
                            Card(
                              child: ExpansionTile(
                                leading: const Icon(Icons.fact_check_outlined),
                                title: Text(t.trainingStepsTitle),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                children: [Text(t.trainingSteps)],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _testingSound ? null : _testSound,
                                  icon: const Icon(Icons.volume_up_outlined),
                                  label: Text(t.soundTest),
                                ),
                                if (widget.actor.canReport)
                                  OutlinedButton.icon(
                                    onPressed: _feedback,
                                    icon: const Icon(
                                      Icons.rate_review_outlined,
                                    ),
                                    label: Text(t.testFeedback),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          LayoutBuilder(
                            builder: (context, size) => Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _metric(
                                  t.activeCalls,
                                  active.length,
                                  Icons.notifications_active_outlined,
                                  size.maxWidth,
                                ),
                                _metric(
                                  t.stoppedMachines,
                                  active
                                      .where((d) => d.data()['canRun'] == false)
                                      .length,
                                  Icons.pause_circle_outline,
                                  size.maxWidth,
                                ),
                                _metric(
                                  t.unassigned,
                                  active
                                      .where(
                                        (d) => (d.data()['assignedToUid'] ?? '')
                                            .toString()
                                            .isEmpty,
                                      )
                                      .length,
                                  Icons.person_search_outlined,
                                  size.maxWidth,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FilterChip(
                                label: Text(t.mine),
                                selected: _mine,
                                onSelected: (v) => setState(() => _mine = v),
                              ),
                              DropdownButton<String>(
                                value: _team,
                                onChanged: (v) =>
                                    setState(() => _team = v ?? ''),
                                items: [
                                  DropdownMenuItem(
                                    value: '',
                                    child: Text(t.allTeams),
                                  ),
                                  ...Workflow.teams.map(
                                    (team) => DropdownMenuItem(
                                      value: team,
                                      child: Text(teamLabel(t, team)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _callGrid(
                            active
                                .where(
                                  (d) =>
                                      (!_mine ||
                                          d.data()['assignedToUid'] ==
                                              widget.actor.uid) &&
                                      (_team.isEmpty ||
                                          (d.data()['targetTeam'] ??
                                                  'maintenance') ==
                                              _team),
                                )
                                .toList(),
                            t.noActiveCalls,
                          ),
                        ],
                        if (_page == 1) ...[
                          TextField(
                            onChanged: (v) =>
                                setState(() => _search = v.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: t.searchMachines,
                              prefixIcon: const Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<bool>(
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text(t.machineList),
                                icon: const Icon(Icons.list),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text(t.factoryMap),
                                icon: const Icon(Icons.map_outlined),
                              ),
                            ],
                            selected: {_map},
                            onSelectionChanged: (v) =>
                                setState(() => _map = v.first),
                          ),
                          const SizedBox(height: 16),
                          if (_map)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      'asset/factory_kroki.png',
                                      height: 280,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: machines
                                          .map(
                                            (machine) => OutlinedButton(
                                              onPressed: () =>
                                                  _showMachine(machine, calls),
                                              child: Text(
                                                _machineName(machine),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ...machines
                              .where(
                                (m) =>
                                    ('${_machineName(m)} ${m.data()['section'] ?? ''}')
                                        .toLowerCase()
                                        .contains(_search),
                              )
                              .map((machine) {
                                final m = machine.data();
                                final state = m['reportedState'];
                                return Card(
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Icon(
                                      state == 'stopped'
                                          ? Icons.pause_circle
                                          : Icons
                                                .precision_manufacturing_outlined,
                                      color: state == 'stopped'
                                          ? Colors.red.shade700
                                          : null,
                                    ),
                                    title: Text(_machineName(machine)),
                                    subtitle: Text(
                                      state == 'stopped'
                                          ? t.productionStopped
                                          : state == 'running'
                                          ? t.productionRunning
                                          : t.stateUnknown,
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _showMachine(machine, calls),
                                  ),
                                );
                              }),
                          if (machines.isEmpty)
                            EmptyState(message: t.machinesEmpty),
                        ],
                        if (_page == 2) _callGrid(closed, t.noHistory),
                        if (_page == 3)
                          HandoverBoard(actor: widget.actor, db: _db),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: widget.actor.canReport && _page != 3
          ? FloatingActionButton.extended(
              onPressed: () => setState(() {
                _page = 1;
                _map = false;
              }),
              label: Text(t.newCall),
              icon: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _page,
        onDestinationSelected: (v) => setState(() => _page = v),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            label: t.overview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.precision_manufacturing_outlined),
            label: t.machinesTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: t.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz),
            label: t.handover,
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int count, IconData icon, double width) =>
      SizedBox(
        width: width >= 600
            ? (width - 20) / 3
            : width >= 340
            ? (width - 10) / 2
            : width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(label),
              ],
            ),
          ),
        ),
      );
  Widget _callGrid(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> calls,
    String empty,
  ) {
    if (calls.isEmpty) return EmptyState(message: empty);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          children: calls
              .map(
                (call) => SizedBox(
                  width: width,
                  child: CallCard(
                    data: call.data(),
                    onTap: () => _openCall(call.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _showMachine(
    QueryDocumentSnapshot<Map<String, dynamic>> machine,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> calls,
  ) {
    final t = AppLocalizations.of(context);
    final related = calls
        .where((d) => d.data()['machineId'] == machine.id)
        .toList();
    final active = related
        .where((d) => d.data()['status'] != 'resolved')
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _machineName(machine),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              if (widget.actor.canReport && active.isEmpty)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _newCall(machine);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(t.newCall),
                ),
              if (active.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(t.noActiveIncidentNote),
                ),
              ...related.map(
                (call) => CallCard(
                  data: call.data(),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openCall(call.id);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
