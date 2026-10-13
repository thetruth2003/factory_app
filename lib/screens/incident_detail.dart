import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/workflow.dart';
import '../services/incident_service.dart';
import '../ui/call_widgets.dart';
import 'add_note_page.dart';
import 'incident_timeline_page.dart';
import 'repair_incident_page.dart';

class IncidentDetailPage extends StatefulWidget {
  const IncidentDetailPage({
    super.key,
    required this.incidentId,
    required this.actor,
    this.db,
  });
  final String incidentId;
  final FactoryUser actor;
  final FirebaseFirestore? db;
  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  late final _db = widget.db ?? FirebaseFirestore.instance;
  late final _service = IncidentService(_db);
  late final _ref = _db.collection('incidents').doc(widget.incidentId);
  late final _stream = _ref.snapshots(includeMetadataChanges: true);
  Timer? _timer;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change(String to) async {
    String message = '';
    String? targetTeam;
    if (to == 'waiting') {
      final value = await showDialog<NoteSubmission>(
        context: context,
        builder: (_) => NoteDialog(waiting: true),
      );
      if (!mounted || value == null) return;
      message = value.message;
      targetTeam = value.team;
    }
    await _perform(
      () => _service.transition(
        incidentId: widget.incidentId,
        actor: widget.actor,
        to: to,
        message: message,
        targetTeam: targetTeam,
      ),
    );
  }

  Future<void> _note() async {
    final value = await showDialog<NoteSubmission>(
      context: context,
      builder: (_) => const NoteDialog(),
    );
    if (!mounted || value == null) return;
    await _perform(
      () => _service.addNote(
        incidentId: widget.incidentId,
        actor: widget.actor,
        message: value.message,
      ),
    );
  }

  Future<void> _production(bool stopped) async {
    final t = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(stopped ? t.productionStop : t.productionResume),
        content: Text(t.confirmState),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.confirmSend),
          ),
        ],
      ),
    );
    if (!mounted || confirm != true) return;
    await _perform(
      () => _service.setProductionState(
        incidentId: widget.incidentId,
        actor: widget.actor,
        stopped: stopped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SessionTitle(
          title: t.activeFaultDetailTitle,
          actor: widget.actor,
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(errorLabel(t, snapshot.error!)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data();
          if (data == null) return Center(child: Text(t.notFound));
          if ((data['createdByCompanyId'] ?? data['companyId']) !=
              widget.actor.companyId) {
            return Center(child: Text(t.errorForbidden));
          }
          final status = (data['status'] ?? 'open').toString();
          final assigned = (data['assignedToUid'] ?? '').toString();
          final canAct =
              widget.actor.canManage &&
              status != 'resolved' &&
              (assigned.isEmpty ||
                  assigned == widget.actor.uid ||
                  widget.actor.canSupervise);
          var downtimeSeconds = (data['downtimeSeconds'] as num? ?? 0).toInt();
          final started = dateValue(data['downtimeStartedAt']);
          if (started != null &&
              data['downtimeEndedAt'] == null &&
              status != 'resolved') {
            final elapsed = DateTime.now().difference(started).inSeconds;
            downtimeSeconds += elapsed < 0 ? 0 : elapsed;
          }
          return Column(
            children: [
              if (snapshot.data!.metadata.isFromCache) const CacheNotice(),
              if (_busy) const LinearProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            (data['machineKey'] ?? data['machineId'] ?? '')
                                .toString(),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              StatusChip(status: status),
                              Chip(
                                label: Text(
                                  kindLabel(
                                    t,
                                    (data['kind'] ?? 'fault').toString(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (data['description'] ?? '').toString(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  const Divider(height: 28),
                                  _line(
                                    t.summaryReportedBy,
                                    (data['reportedByName'] ?? '').toString(),
                                  ),
                                  _line(
                                    t.team,
                                    teamLabel(
                                      t,
                                      (data['targetTeam'] ?? 'maintenance')
                                          .toString(),
                                    ),
                                  ),
                                  _line(
                                    t.assignedTo,
                                    (data['assignedToName'] ?? t.unassigned)
                                        .toString(),
                                  ),
                                  _line(
                                    t.recordedAt,
                                    dateLabel(data['createdAt']),
                                  ),
                                  _line(
                                    t.elapsed,
                                    durationLabel(
                                      t,
                                      data['openedAt'] ?? data['createdAt'],
                                      end: data['resolvedAt'],
                                    ),
                                  ),
                                  _line(
                                    t.downtime,
                                    data['schemaVersion'] == 2
                                        ? '${downtimeSeconds ~/ 60} ${t.minutes}'
                                        : '—',
                                  ),
                                  _line(
                                    t.productionState,
                                    status == 'resolved' ||
                                            data['canRun'] == true
                                        ? t.productionRunning
                                        : data['canRun'] == false
                                        ? t.productionStopped
                                        : t.stateUnknown,
                                  ),
                                  if ((data['errorCode'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _line(
                                      t.errorCodeLabel,
                                      data['errorCode'].toString(),
                                    ),
                                  if ((data['waitingReason'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _line(
                                      t.waitingReason,
                                      data['waitingReason'].toString(),
                                    ),
                                  if ((data['repairNotes'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    _line(
                                      t.resolutionNotes,
                                      data['repairNotes'].toString(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (canAct)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (status == 'open')
                                  FilledButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _change('acknowledged'),
                                    icon: const Icon(
                                      Icons.pan_tool_alt_outlined,
                                    ),
                                    label: Text(t.claim),
                                  ),
                                if (const [
                                  'acknowledged',
                                  'waiting',
                                  'stop_required',
                                  'need_technician',
                                ].contains(status))
                                  FilledButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _change('in_progress'),
                                    icon: const Icon(Icons.play_arrow),
                                    label: Text(
                                      status == 'acknowledged'
                                          ? t.startWork
                                          : t.resumeWork,
                                    ),
                                  ),
                                if (status == 'in_progress')
                                  FilledButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RepairIncidentPage(
                                                    actor: widget.actor,
                                                    incidentId:
                                                        widget.incidentId,
                                                    db: _db,
                                                  ),
                                            ),
                                          ),
                                    icon: const Icon(Icons.task_alt),
                                    label: Text(t.resolveCall),
                                  ),
                                if (status == 'acknowledged' ||
                                    status == 'in_progress')
                                  OutlinedButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _change('waiting'),
                                    icon: const Icon(Icons.hourglass_empty),
                                    label: Text(t.waitForSupport),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _production(
                                          data['canRun'] != false,
                                        ),
                                  icon: Icon(
                                    data['canRun'] == false
                                        ? Icons.play_circle_outline
                                        : Icons.pause_circle_outline,
                                  ),
                                  label: Text(
                                    data['canRun'] == false
                                        ? t.productionResume
                                        : t.productionStop,
                                  ),
                                ),
                              ],
                            ),
                          if (widget.actor.canReport)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: OutlinedButton.icon(
                                onPressed: _busy ? null : _note,
                                icon: const Icon(Icons.note_add_outlined),
                                label: Text(t.addNote),
                              ),
                            ),
                          _PhotoGallery(ref: _ref),
                          const SizedBox(height: 20),
                          Text(
                            t.timeline,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          IncidentTimeline(
                            events: _ref
                                .collection('events')
                                .orderBy('at', descending: true)
                                .snapshots(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text('$label: $value'),
  );
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({required this.ref});
  final DocumentReference<Map<String, dynamic>> ref;
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.collection('photos').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Text(errorLabel(AppLocalizations.of(context), snap.error!));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const SizedBox.shrink();
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: docs.map((doc) {
              final url = (doc.data()['url'] ?? '').toString();
              return InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => Dialog(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: InteractiveViewer(
                            child: Image.network(
                              url,
                              errorBuilder: (context, error, stack) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(AppLocalizations.of(context).cancel),
                        ),
                      ],
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    url,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox(
                      width: 100,
                      height: 100,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
}
