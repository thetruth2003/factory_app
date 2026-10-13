import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/workflow.dart';
import '../services/handover_service.dart';
import '../ui/call_widgets.dart';
import 'incident_detail.dart';

class HandoverBoard extends StatefulWidget {
  const HandoverBoard({super.key, required this.actor, required this.db});
  final FactoryUser actor;
  final FirebaseFirestore db;
  @override
  State<HandoverBoard> createState() => _HandoverBoardState();
}

class _HandoverBoardState extends State<HandoverBoard> {
  int _limit = 30;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _records = _stream();
  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() =>
      HandoverService(widget.db)
          .records(widget.actor.companyId)
          .orderBy('createdAt', descending: true)
          .limit(_limit)
          .snapshots(includeMetadataChanges: true);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.handoverHelp),
        const SizedBox(height: 12),
        if (widget.actor.canReport)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CreateHandoverPage(actor: widget.actor, db: widget.db),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(t.newHandover),
            ),
          ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _records,
          builder: (context, snap) {
            if (snap.hasError) {
              return Column(
                children: [
                  Text(errorLabel(t, snap.error!)),
                  TextButton(
                    onPressed: () => setState(() => _records = _stream()),
                    child: Text(t.retry),
                  ),
                ],
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data!.docs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (snap.data!.metadata.isFromCache) const CacheNotice(),
                if (docs.isEmpty)
                  EmptyState(message: t.noHandovers, icon: Icons.swap_horiz),
                ...docs.map((doc) {
                  final data = doc.data();
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text((data['shift'] ?? '').toString()),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            '${teamLabel(t, (data['team'] ?? '').toString())} · ${dateLabel(data['createdAt'])}',
                          ),
                          Text(
                            '${t.handoverFrom}: ${data['createdByName'] ?? ''}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (data['notes'] ?? '').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['status'] == 'accepted'
                                ? '${t.handoverReceived}: ${data['acceptedByName'] ?? ''}'
                                : t.handoverPending,
                            style: TextStyle(
                              color: data['status'] == 'accepted'
                                  ? Colors.teal.shade700
                                  : Colors.deepOrange.shade800,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => HandoverDetailPage(
                            id: doc.id,
                            actor: widget.actor,
                            db: widget.db,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                if (docs.length == _limit)
                  TextButton(
                    onPressed: () => setState(() {
                      _limit += 30;
                      _records = _stream();
                    }),
                    child: Text(t.loadMore),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CreateHandoverPage extends StatefulWidget {
  const CreateHandoverPage({super.key, required this.actor, required this.db});
  final FactoryUser actor;
  final FirebaseFirestore db;
  @override
  State<CreateHandoverPage> createState() => _CreateHandoverPageState();
}

class _CreateHandoverPageState extends State<CreateHandoverPage> {
  final _form = GlobalKey<FormState>();
  final _shift = TextEditingController();
  final _notes = TextEditingController();
  final _selected = <String>{};
  bool _busy = false;
  late String _team = widget.actor.role == 'technician'
      ? 'maintenance'
      : HandoverService.teams.contains(widget.actor.role)
      ? widget.actor.role
      : 'operator';
  late final _service = HandoverService(widget.db);
  late final _id = _service.records(widget.actor.companyId).doc().id;
  late final _calls = widget.db
      .collection('incidents')
      .where('createdByCompanyId', isEqualTo: widget.actor.companyId)
      .snapshots();

  @override
  void dispose() {
    _shift.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await _service.create(
        id: _id,
        actor: widget.actor,
        shift: _shift.text,
        team: _team,
        notes: _notes.text,
        incidentIds: _selected.toList(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        if (e is WorkflowException && e.code == 'handoverChanged') {
          _selected.clear();
        }
        showFailure(context, e);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: SessionTitle(title: t.newHandover, actor: widget.actor),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _calls,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text(errorLabel(t, snap.error!)));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final calls =
                snap.data!.docs
                    .where(
                      (d) => Workflow.isActive(
                        (d.data()['status'] ?? '').toString(),
                      ),
                    )
                    .toList()
                  ..sort(
                    (a, b) => (a.data()['machineKey'] ?? '')
                        .toString()
                        .compareTo((b.data()['machineKey'] ?? '').toString()),
                  );
            return Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (snap.data!.metadata.isFromCache) const CacheNotice(),
                  Text(t.newHandoverHelp),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _shift,
                    enabled: !_busy,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: t.shiftLabel,
                      hintText: t.shiftHint,
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? t.errorNote : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _team,
                    decoration: InputDecoration(labelText: t.team),
                    items: HandoverService.teams
                        .map(
                          (team) => DropdownMenuItem(
                            value: team,
                            child: Text(teamLabel(t, team)),
                          ),
                        )
                        .toList(),
                    onChanged: _busy ? null : (v) => setState(() => _team = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notes,
                    enabled: !_busy,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: InputDecoration(
                      labelText: t.handoverNotes,
                      hintText: t.handoverNotesHint,
                    ),
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? t.errorNote : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.selectHandoverCalls(_selected.length),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(t.handoverSelectionHelp),
                  if (calls.isEmpty) EmptyState(message: t.noActiveCalls),
                  ...calls.map((doc) {
                    final data = doc.data();
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _selected.contains(doc.id),
                      onChanged: _busy
                          ? null
                          : (v) => setState(() {
                              if (v == true &&
                                  _selected.length < HandoverService.maxCalls) {
                                _selected.add(doc.id);
                              } else if (v == false) {
                                _selected.remove(doc.id);
                              }
                            }),
                      title: Text((data['machineKey'] ?? doc.id).toString()),
                      subtitle: Text(
                        '${statusLabel(t, (data['status'] ?? '').toString())} · ${data['assignedToName'] ?? t.unassigned}\n${data['description'] ?? ''}',
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(t.saveHandover),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class HandoverDetailPage extends StatefulWidget {
  const HandoverDetailPage({
    super.key,
    required this.id,
    required this.actor,
    required this.db,
  });
  final String id;
  final FactoryUser actor;
  final FirebaseFirestore db;
  @override
  State<HandoverDetailPage> createState() => _HandoverDetailPageState();
}

class _HandoverDetailPageState extends State<HandoverDetailPage> {
  late final _service = HandoverService(widget.db);
  late final _record = _service
      .records(widget.actor.companyId)
      .doc(widget.id)
      .snapshots(includeMetadataChanges: true);
  bool _busy = false;
  Future<void> _accept() async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.acceptHandover),
        content: Text(
          widget.actor.canManage
              ? t.handoverAcceptHelp
              : t.handoverReadReceiptHelp,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.acceptHandover),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _service.accept(id: widget.id, actor: widget.actor);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: SessionTitle(title: t.handover, actor: widget.actor),
        ),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _record,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text(errorLabel(t, snap.error!)));
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data!.data();
            if (data == null) return EmptyState(message: t.notFound);
            final calls = (data['calls'] as List? ?? []).cast<Map>();
            final accepted = data['status'] == 'accepted';
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (snap.data!.metadata.isFromCache) const CacheNotice(),
                Text(
                  (data['shift'] ?? '').toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${teamLabel(t, (data['team'] ?? '').toString())} · ${dateLabel(data['createdAt'])}',
                ),
                Text('${t.handoverFrom}: ${data['createdByName'] ?? ''}'),
                const SizedBox(height: 20),
                Text(
                  t.handoverNotes,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text((data['notes'] ?? '').toString()),
                const SizedBox(height: 20),
                if (accepted)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.handoverReceived}: ${data['acceptedByName'] ?? ''}',
                          ),
                          Text(dateLabel(data['acceptedAt'])),
                          Text(
                            t.handoverTransferred(
                              (data['transferredCalls'] as num? ?? 0).toInt(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!accepted) Text(t.handoverPending),
                if (!accepted &&
                    data['createdByUid'] != widget.actor.uid &&
                    !HandoverService.canReceive(
                      widget.actor,
                      (data['team'] ?? '').toString(),
                    ))
                  Text(t.handoverTeamOnly),
                if (!accepted &&
                    HandoverService.canReceive(
                      widget.actor,
                      (data['team'] ?? '').toString(),
                    ) &&
                    data['createdByUid'] != widget.actor.uid)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _accept,
                      icon: const Icon(Icons.task_alt),
                      label: Text(t.acceptHandover),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  t.handoverSnapshotHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (calls.isEmpty) EmptyState(message: t.noHandoverCalls),
                ...calls.map(
                  (call) => Card(
                    child: ListTile(
                      title: Text(
                        (call['machineKey'] ?? call['machineId'] ?? '')
                            .toString(),
                      ),
                      subtitle: Text(
                        '${statusLabel(t, (call['status'] ?? '').toString())} · ${call['assignedToName'] ?? t.unassigned}\n${call['description'] ?? ''}',
                      ),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IncidentDetailPage(
                            incidentId: call['incidentId'] as String,
                            actor: widget.actor,
                            db: widget.db,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
