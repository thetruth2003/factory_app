import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/roster.dart';
import '../models/workflow.dart';
import '../services/roster_service.dart';
import '../ui/call_widgets.dart';
import 'handover_page.dart';
import 'incident_detail.dart';

String calendarLabel(DateTime day) => DateFormat('dd.MM.yyyy').format(day);
String calendarMoment(dynamic value) => value is Timestamp
    ? DateFormat(
        'dd.MM.yyyy HH:mm',
      ).format(FactoryCalendar.local(value.toDate()))
    : '—';
String shiftTime(Map<String, dynamic> data) =>
    '${DateFormat('dd.MM HH:mm').format(FactoryCalendar.local((data['startAt'] as Timestamp).toDate()))} – ${DateFormat('dd.MM HH:mm').format(FactoryCalendar.local((data['endAt'] as Timestamp).toDate()))}';
typedef Rows = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

/// A Sunday overnight worker can finish their own report on Monday without
/// exposing the previous week's team calendar.
class PreviousShiftReport extends StatefulWidget {
  const PreviousShiftReport({
    super.key,
    required this.actor,
    required this.db,
    required this.today,
  });
  final FactoryUser actor;
  final FirebaseFirestore db;
  final DateTime today;
  @override
  State<PreviousShiftReport> createState() => _PreviousShiftReportState();
}

class _PreviousShiftReportState extends State<PreviousShiftReport> {
  late final ref = RosterService(widget.db).assignment(
    widget.actor.companyId,
    widget.today.subtract(const Duration(days: 1)),
    widget.actor.uid,
  );
  late final stream = ref.snapshots(includeMetadataChanges: true);
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (!snap.hasData ||
              snap.hasError ||
              snap.data!.metadata.isFromCache) {
            return const SizedBox.shrink();
          }
          final data = snap.data!.data();
          if (data == null ||
              data['cancelled'] == true ||
              DateTime.now().isAfter(
                (data['endAt'] as Timestamp).toDate().add(
                  const Duration(hours: 24),
                ),
              )) {
            return const SizedBox.shrink();
          }
          return Card(
            child: ListTile(
              leading: const Icon(Icons.nightlight_outlined),
              title: Text(AppLocalizations.of(context).endReport),
              subtitle: Text(shiftTime(data)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ShiftDetailPage(
                    actor: widget.actor,
                    db: widget.db,
                    reference: ref,
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// Reuses subscriptions across rebuilds and never displays a cached roster to
/// workers before the server has checked their current-week access.
class LiveRows extends StatefulWidget {
  const LiveRows({
    super.key,
    required this.query,
    required this.builder,
    this.serverOnly = false,
  });
  final Query<Map<String, dynamic>> query;
  final Widget Function(Rows) builder;
  final bool serverOnly;
  @override
  State<LiveRows> createState() => _LiveRowsState();
}

class _LiveRowsState extends State<LiveRows> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> stream;
  void subscribe() =>
      stream = widget.query.snapshots(includeMetadataChanges: true);
  @override
  void initState() {
    super.initState();
    subscribe();
  }

  @override
  void didUpdateWidget(covariant LiveRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) subscribe();
  }

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          final t = AppLocalizations.of(context);
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(errorLabel(t, snap.error!)),
            );
          }
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            );
          }
          if (widget.serverOnly && snap.data!.metadata.isFromCache) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(t.onlineRoster),
            );
          }
          return widget.builder(snap.data!.docs);
        },
      );
}

class _WeekRows extends StatefulWidget {
  const _WeekRows({
    super.key,
    required this.actor,
    required this.db,
    required this.day,
    required this.builder,
  });
  final FactoryUser actor;
  final FirebaseFirestore db;
  final DateTime day;
  final Widget Function(Rows) builder;
  @override
  State<_WeekRows> createState() => _WeekRowsState();
}

class _WeekRowsState extends State<_WeekRows> {
  late final service = RosterService(widget.db);
  late final header = service
      .week(widget.actor.companyId, widget.day)
      .snapshots(includeMetadataChanges: true);
  Widget rows() => LiveRows(
    query: service.roster(widget.actor, widget.day),
    serverOnly: !FactoryCalendar.admin(widget.actor),
    builder: widget.builder,
  );
  @override
  Widget build(BuildContext context) {
    if (FactoryCalendar.admin(widget.actor)) return rows();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: header,
      builder: (context, snap) {
        final t = AppLocalizations.of(context);
        if (snap.hasError) return Text(errorLabel(t, snap.error!));
        if (!snap.hasData) return const LinearProgressIndicator();
        if (snap.data!.metadata.isFromCache) return Text(t.onlineRoster);
        return snap.data!.exists ? rows() : widget.builder([]);
      },
    );
  }
}

class RosterPage extends StatefulWidget {
  const RosterPage({super.key, required this.actor, required this.db});
  final FactoryUser actor;
  final FirebaseFirestore db;
  @override
  State<RosterPage> createState() => _RosterPageState();
}

class _RosterPageState extends State<RosterPage> with WidgetsBindingObserver {
  DateTime day = FactoryCalendar.today();
  DateTime today = FactoryCalendar.today();
  Timer? timer;
  bool get admin => FactoryCalendar.admin(widget.actor);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshDay());
  }

  void refreshDay() {
    final next = FactoryCalendar.today();
    if (next != today && mounted) {
      setState(() {
        today = next;
        if (!admin && FactoryCalendar.week(day) != FactoryCalendar.week(next)) {
          day = next;
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshDay();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => day = FactoryCalendar.date(selected));
    }
  }

  void openShift(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShiftDetailPage(
            actor: widget.actor,
            db: widget.db,
            reference: doc.reference,
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context), monday = FactoryCalendar.week(day);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.roster),
        actions: [
          if (admin)
            IconButton(
              tooltip: t.staff,
              icon: const Icon(Icons.people_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StaffPage(actor: widget.actor, db: widget.db),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: admin
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: Text(t.addShift),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditShiftPage(
                    actor: widget.actor,
                    db: widget.db,
                    day: day,
                  ),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Text(t.rosterHelp),
          if (!admin)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(t.weekOnly),
            ),
          const SizedBox(height: 12),
          if (admin)
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => setState(
                    () => day = today.subtract(const Duration(days: 1)),
                  ),
                  child: Text(t.yesterday),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => day = today),
                  child: Text(t.today),
                ),
                OutlinedButton(
                  onPressed: () =>
                      setState(() => day = today.add(const Duration(days: 1))),
                  child: Text(t.tomorrow),
                ),
                OutlinedButton.icon(
                  onPressed: chooseDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(t.chooseDate),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            '${calendarLabel(monday)} – ${calendarLabel(monday.add(const Duration(days: 6)))}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: List.generate(7, (i) {
              final date = monday.add(Duration(days: i));
              return ChoiceChip(
                label: Text(DateFormat('EEE dd', t.localeName).format(date)),
                selected: day == date,
                onSelected: (_) => setState(() => day = date),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            calendarLabel(day),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (!admin && today.weekday == DateTime.monday)
            PreviousShiftReport(
              actor: widget.actor,
              db: widget.db,
              today: today,
            ),
          _WeekRows(
            key: ValueKey('roster-${FactoryCalendar.key(monday)}'),
            actor: widget.actor,
            db: widget.db,
            day: day,
            builder: (rows) {
              final selected =
                  rows
                      .where(
                        (d) =>
                            (d.data()['day'] as Timestamp).toDate().toUtc() ==
                            day,
                      )
                      .toList()
                    ..sort(
                      (a, b) => (a.data()['startAt'] as Timestamp).compareTo(
                        b.data()['startAt'] as Timestamp,
                      ),
                    );
              final tomorrow = today.add(const Duration(days: 1));
              final next = rows
                  .where(
                    (d) =>
                        (d.data()['day'] as Timestamp).toDate().toUtc() ==
                            tomorrow &&
                        d.data()['cancelled'] != true,
                  )
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selected.isEmpty) EmptyState(message: t.noShifts),
                  ...selected.map((doc) {
                    final s = doc.data();
                    return Card(
                      child: ListTile(
                        onTap: () => openShift(doc),
                        leading: Icon(
                          s['cancelled'] == true
                              ? Icons.event_busy
                              : Icons.badge_outlined,
                        ),
                        title: Text('${s['name']} · ${s['label']}'),
                        subtitle: Text(
                          '${teamLabel(t, s['team'])}\n${shiftTime(s)}\n${s['cancelled'] == true ? t.shiftCancelled : t.scheduled}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  }),
                  if (!admin) ...[
                    const SizedBox(height: 16),
                    Text(
                      t.nextTeam,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (FactoryCalendar.week(tomorrow) != monday)
                      Text(t.nextWeekHidden)
                    else if (next.isEmpty)
                      Text(t.noShifts)
                    else
                      ...next.map(
                        (doc) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(doc.data()['name']),
                          subtitle: Text(shiftTime(doc.data())),
                          onTap: () => openShift(doc),
                        ),
                      ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (admin ||
              day == today ||
              day == today.add(const Duration(days: 1)))
            TeamNotesPanel(actor: widget.actor, db: widget.db, day: day),
          if (widget.actor.canReport)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      LeaveNotePage(actor: widget.actor, db: widget.db),
                ),
              ),
              icon: const Icon(Icons.edit_note),
              label: Text(t.leaveNote),
            ),
        ],
      ),
    );
  }
}

class StaffPage extends StatelessWidget {
  const StaffPage({super.key, required this.actor, required this.db});
  final FactoryUser actor;
  final FirebaseFirestore db;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (!FactoryCalendar.admin(actor)) {
      return Scaffold(body: Center(child: Text(t.errorForbidden)));
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.staff)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t.staffHelp),
          LiveRows(
            query: db
                .collection('users')
                .where('companyId', isEqualTo: actor.companyId),
            builder: (rows) {
              final sorted = rows.toList()
                ..sort(
                  (a, b) => (a.data()['displayName'] ?? '')
                      .toString()
                      .compareTo((b.data()['displayName'] ?? '').toString()),
                );
              return Column(
                children: sorted.map((doc) {
                  final p = doc.data(), active = p['isActive'] != false;
                  return Card(
                    child: SwitchListTile(
                      title: Text(p['displayName'] ?? p['name'] ?? doc.id),
                      subtitle: Text(
                        '${teamLabel(t, p['role'] ?? '')} · ${active ? t.activeEmployee : t.inactiveEmployee}',
                      ),
                      value: active,
                      onChanged: doc.id == actor.uid || p['role'] == 'admin'
                          ? null
                          : (value) async {
                              final accepted = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(t.changeEmployeeStatus),
                                  content: Text(t.staffHelp),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: Text(t.cancel),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(t.save),
                                    ),
                                  ],
                                ),
                              );
                              if (accepted != true) return;
                              try {
                                await doc.reference.update({'isActive': value});
                              } catch (e) {
                                if (context.mounted) showFailure(context, e);
                              }
                            },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class EditShiftPage extends StatefulWidget {
  const EditShiftPage({
    super.key,
    required this.actor,
    required this.db,
    required this.day,
    this.existing,
  });
  final FactoryUser actor;
  final FirebaseFirestore db;
  final DateTime day;
  final Map<String, dynamic>? existing;
  @override
  State<EditShiftPage> createState() => _EditShiftPageState();
}

class _EditShiftPageState extends State<EditShiftPage> {
  late final label = TextEditingController(
    text: widget.existing?['label'] ?? '',
  );
  late String? uid = widget.existing?['uid'];
  late TimeOfDay start = widget.existing == null
      ? const TimeOfDay(hour: 6, minute: 0)
      : TimeOfDay.fromDateTime(
          FactoryCalendar.local(
            (widget.existing!['startAt'] as Timestamp).toDate(),
          ),
        );
  late TimeOfDay end = widget.existing == null
      ? const TimeOfDay(hour: 14, minute: 0)
      : TimeOfDay.fromDateTime(
          FactoryCalendar.local(
            (widget.existing!['endAt'] as Timestamp).toDate(),
          ),
        );
  bool busy = false;
  @override
  void dispose() {
    label.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (uid == null) return;
    setState(() => busy = true);
    try {
      await RosterService(widget.db).saveShift(
        actor: widget.actor,
        uid: uid!,
        day: widget.day,
        startMinute: start.hour * 60 + start.minute,
        endMinute: end.hour * 60 + end.minute,
        label: label.text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? t.addShift : t.editShift),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('${calendarLabel(widget.day)} · Europe/Warsaw'),
            const SizedBox(height: 16),
            LiveRows(
              query: widget.db
                  .collection('users')
                  .where('companyId', isEqualTo: widget.actor.companyId),
              builder: (rows) {
                final active = rows
                    .where(
                      (d) =>
                          d.data()['isActive'] != false &&
                          FactoryCalendar.teams.contains(
                            d.data()['role'] == 'technician'
                                ? 'maintenance'
                                : d.data()['role'],
                          ) &&
                          (d.data()['environment'] == 'training') ==
                              widget.actor.isTraining,
                    )
                    .toList();
                if (active.isEmpty) return Text(t.noEmployees);
                return DropdownButtonFormField<String>(
                  initialValue: active.any((d) => d.id == uid) ? uid : null,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: t.staff),
                  items: active
                      .map(
                        (d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(
                            '${d.data()['displayName'] ?? d.id} · ${teamLabel(t, d.data()['role'])}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: busy || widget.existing != null
                      ? null
                      : (v) => setState(() => uid = v),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: label,
              enabled: !busy,
              maxLength: 80,
              decoration: InputDecoration(labelText: t.shiftLabel),
            ),
            for (final first in [true, false])
              ListTile(
                title: Text(first ? t.shiftStart : t.shiftEnd),
                trailing: Text((first ? start : end).format(context)),
                onTap: busy
                    ? null
                    : () async {
                        final value = await showTimePicker(
                          context: context,
                          initialTime: first ? start : end,
                        );
                        if (value != null && mounted) {
                          setState(() {
                            if (first) {
                              start = value;
                            } else {
                              end = value;
                            }
                          });
                        }
                      },
              ),
            Text(t.nightShiftHelp),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy || uid == null ? null : save,
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}

class ShiftDetailPage extends StatefulWidget {
  const ShiftDetailPage({
    super.key,
    required this.actor,
    required this.db,
    required this.reference,
  });
  final FactoryUser actor;
  final FirebaseFirestore db;
  final DocumentReference<Map<String, dynamic>> reference;
  @override
  State<ShiftDetailPage> createState() => _ShiftDetailPageState();
}

class _ShiftDetailPageState extends State<ShiftDetailPage>
    with WidgetsBindingObserver {
  late final stream = widget.reference.snapshots(includeMetadataChanges: true);
  Timer? timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.shiftLabel)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(errorLabel(t, snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snap.data!.data();
          if (s == null) return EmptyState(message: t.notFound);
          final day = (s['day'] as Timestamp).toDate().toUtc();
          final ownRecent =
              s['uid'] == widget.actor.uid &&
              !DateTime.now().isBefore((s['startAt'] as Timestamp).toDate()) &&
              !DateTime.now().isAfter(
                (s['endAt'] as Timestamp).toDate().add(
                  const Duration(hours: 24),
                ),
              );
          if (!FactoryCalendar.canRead(widget.actor, day, s['team']) &&
              !ownRecent) {
            return Center(child: Text(t.weekOnly));
          }
          if (!FactoryCalendar.admin(widget.actor) &&
              snap.data!.metadata.isFromCache) {
            return Center(child: Text(t.onlineRoster));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${s['name']} · ${s['label']}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                '${teamLabel(t, s['team'])}\n${shiftTime(s)} · Europe/Warsaw',
              ),
              if (s['cancelled'] == true) Text(t.shiftCancelled),
              if (FactoryCalendar.admin(widget.actor))
                LiveRows(
                  query: widget.reference.collection('reports'),
                  builder: (records) => records.isNotEmpty
                      ? Text(t.reportLocked)
                      : Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(t.editShift),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditShiftPage(
                                    actor: widget.actor,
                                    db: widget.db,
                                    day: day,
                                    existing: s,
                                  ),
                                ),
                              ),
                            ),
                            if (s['cancelled'] != true)
                              TextButton(
                                onPressed: () async {
                                  final yes = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(t.cancelShift),
                                      content: Text(t.cancelShiftHelp),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(t.cancel),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(t.cancelShift),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (yes != true) return;
                                  try {
                                    await RosterService(widget.db).cancelShift(
                                      widget.actor,
                                      widget.reference,
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      showFailure(context, e);
                                    }
                                  }
                                },
                                child: Text(t.cancelShift),
                              ),
                          ],
                        ),
                ),
              const SizedBox(height: 20),
              Text(t.endReport, style: Theme.of(context).textTheme.titleLarge),
              LiveRows(
                query: widget.reference.collection('reports'),
                serverOnly: !FactoryCalendar.admin(widget.actor),
                builder: (reports) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (reports.isEmpty) Text(t.noReport),
                    ...reports.map(
                      (r) => Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${r.data()['createdByName']} · ${calendarMoment(r.data()['createdAt'])}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                t.reportSummary,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(r.data()['summary']),
                              const SizedBox(height: 8),
                              Text(
                                t.reportProblems,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(r.data()['problems']),
                              const SizedBox(height: 8),
                              Text(
                                t.reportFollowUp,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(r.data()['followUp']),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (reports.isEmpty &&
                        s['uid'] == widget.actor.uid &&
                        s['cancelled'] != true)
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WriteShiftReportPage(
                              actor: widget.actor,
                              db: widget.db,
                              reference: widget.reference,
                            ),
                          ),
                        ),
                        child: Text(t.writeReport),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t.dailyIssues,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(t.dailyIssuesHelp),
              LiveRows(
                query: widget.db
                    .collection('incidents')
                    .where(
                      'createdByCompanyId',
                      isEqualTo: widget.actor.companyId,
                    ),
                builder: (rows) {
                  final start = (s['startAt'] as Timestamp).toDate(),
                      end = (s['endAt'] as Timestamp).toDate();
                  final calls = rows.where((r) {
                    final c = r.data();
                    final opened =
                        dateValue(c['openedAt']) ?? dateValue(c['createdAt']);
                    final closed = dateValue(c['resolvedAt']);
                    return (c['createdByUid'] == s['uid'] ||
                            c['assignedToUid'] == s['uid']) &&
                        opened != null &&
                        opened.isBefore(end) &&
                        (closed == null || !closed.isBefore(start));
                  }).toList();
                  return Column(
                    children: calls
                        .map(
                          (c) => Card(
                            child: ListTile(
                              title: Text(
                                '${c.data()['machineKey'] ?? ''} · ${statusLabel(t, c.data()['status'] ?? '')}',
                              ),
                              subtitle: Text(c.data()['description'] ?? ''),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => IncidentDetailPage(
                                    incidentId: c.id,
                                    actor: widget.actor,
                                    db: widget.db,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                t.dayHandovers,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              LiveRows(
                query: widget.db
                    .collection('companies')
                    .doc(widget.actor.companyId)
                    .collection('handovers')
                    .where('createdByUid', isEqualTo: s['uid']),
                builder: (rows) {
                  final start = (s['startAt'] as Timestamp).toDate(),
                      end = (s['endAt'] as Timestamp).toDate();
                  final reports = rows.where((r) {
                    final at = dateValue(r.data()['createdAt']);
                    return at != null &&
                        !at.isBefore(start) &&
                        at.isBefore(end.add(const Duration(hours: 2)));
                  });
                  return Column(
                    children: reports
                        .map(
                          (r) => Card(
                            child: ListTile(
                              title: Text(r.data()['shift']),
                              subtitle: Text(r.data()['notes']),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => HandoverDetailPage(
                                    id: r.id,
                                    actor: widget.actor,
                                    db: widget.db,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (widget.actor.canReport)
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: Text(t.leaveNote),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          LeaveNotePage(actor: widget.actor, db: widget.db),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class WriteShiftReportPage extends StatefulWidget {
  const WriteShiftReportPage({
    super.key,
    required this.actor,
    required this.db,
    required this.reference,
  });
  final FactoryUser actor;
  final FirebaseFirestore db;
  final DocumentReference<Map<String, dynamic>> reference;
  @override
  State<WriteShiftReportPage> createState() => _WriteShiftReportPageState();
}

class _WriteShiftReportPageState extends State<WriteShiftReportPage> {
  final summary = TextEditingController(),
      problems = TextEditingController(),
      followUp = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    summary.dispose();
    problems.dispose();
    followUp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: Text(t.writeReport)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(t.reportHelp),
            const SizedBox(height: 16),
            for (final entry in [
              (summary, t.reportSummary),
              (problems, t.reportProblems),
              (followUp, t.reportFollowUp),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: entry.$1,
                  enabled: !busy,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: InputDecoration(labelText: entry.$2),
                ),
              ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        await RosterService(widget.db).saveReport(
                          actor: widget.actor,
                          shift: widget.reference,
                          summary: summary.text,
                          problems: problems.text,
                          followUp: followUp.text,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) showFailure(context, e);
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}

class TeamNotesPanel extends StatelessWidget {
  const TeamNotesPanel({
    super.key,
    required this.actor,
    required this.db,
    required this.day,
    this.compact = false,
  });
  final FactoryUser actor;
  final FirebaseFirestore db;
  final DateTime day;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return LiveRows(
      key: ValueKey('notes-${FactoryCalendar.key(day)}'),
      query: RosterService(db).dayNotes(actor, day),
      serverOnly: !FactoryCalendar.admin(actor),
      builder: (rows) {
        if (compact && rows.isEmpty) return const SizedBox.shrink();
        final sorted = rows.toList()
          ..sort((a, b) {
            final importance =
                (b.data()['important'] == true ? 1 : 0) -
                (a.data()['important'] == true ? 1 : 0);
            return importance != 0
                ? importance
                : (dateValue(b.data()['createdAt']) ?? DateTime(1970))
                      .compareTo(
                        dateValue(a.data()['createdAt']) ?? DateTime(1970),
                      );
          });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.teamNotes, style: Theme.of(context).textTheme.titleLarge),
            if (rows.isEmpty) Text(t.noNotes),
            ...sorted.map(
              (doc) => _NoteCard(
                key: ValueKey(doc.id),
                actor: actor,
                db: db,
                doc: doc,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatefulWidget {
  const _NoteCard({
    super.key,
    required this.actor,
    required this.db,
    required this.doc,
  });
  final FactoryUser actor;
  final FirebaseFirestore db;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  late final receipt = widget.doc.reference
      .collection('reads')
      .doc(widget.actor.uid)
      .snapshots();
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context), n = widget.doc.data();
    return Card(
      color: n['important'] == true ? const Color(0xFFFFE6DA) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (n['important'] == true)
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.importantNote,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            Text('${n['createdByName']} · ${teamLabel(t, n['team'])}'),
            const SizedBox(height: 8),
            Text(n['body']),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: receipt,
              builder: (context, snap) {
                if (snap.hasError) return Text(errorLabel(t, snap.error!));
                if (!snap.hasData) return const SizedBox.shrink();
                if (snap.data!.exists &&
                    !snap.data!.metadata.hasPendingWrites) {
                  return Text('✓ ${t.readNote}');
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() => busy = true);
                            try {
                              await RosterService(
                                widget.db,
                              ).markRead(widget.actor, widget.doc.reference);
                            } catch (e) {
                              if (context.mounted) showFailure(context, e);
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                    icon: const Icon(Icons.done),
                    label: Text(t.markRead),
                  ),
                );
              },
            ),
            if (FactoryCalendar.admin(widget.actor) ||
                n['createdByUid'] == widget.actor.uid)
              ExpansionTile(
                title: Text(t.readReceipts),
                children: [
                  LiveRows(
                    query: widget.doc.reference.collection('reads'),
                    builder: (rows) => Column(
                      children: rows.isEmpty
                          ? [Text(t.noReaders)]
                          : rows
                                .map(
                                  (r) => ListTile(
                                    title: Text(r.data()['name']),
                                    subtitle: Text(
                                      calendarMoment(r.data()['at']),
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class LeaveNotePage extends StatefulWidget {
  const LeaveNotePage({super.key, required this.actor, required this.db});
  final FactoryUser actor;
  final FirebaseFirestore db;
  @override
  State<LeaveNotePage> createState() => _LeaveNotePageState();
}

class _LeaveNotePageState extends State<LeaveNotePage> {
  final body = TextEditingController();
  late final service = RosterService(widget.db);
  late final id = service.notes(widget.actor.companyId).doc().id;
  late String team = FactoryCalendar.team(widget.actor);
  bool tomorrow = true, important = false, busy = false;
  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(title: Text(t.leaveNote)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(t.noteHelp),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(t.today)),
                ButtonSegment(value: true, label: Text(t.tomorrow)),
              ],
              selected: {tomorrow},
              onSelectionChanged: busy
                  ? null
                  : (v) => setState(() => tomorrow = v.first),
            ),
            const SizedBox(height: 16),
            if (FactoryCalendar.admin(widget.actor))
              DropdownButtonFormField<String>(
                initialValue: team,
                decoration: InputDecoration(labelText: t.team),
                items: FactoryCalendar.teams
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(teamLabel(t, r)),
                      ),
                    )
                    .toList(),
                onChanged: busy ? null : (v) => setState(() => team = v!),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: body,
              enabled: !busy,
              maxLines: 6,
              maxLength: 2000,
              decoration: InputDecoration(labelText: t.handoverNotes),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.importantNote),
              value: important,
              onChanged: busy ? null : (v) => setState(() => important = v),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        await service.leaveNote(
                          actor: widget.actor,
                          id: id,
                          day: FactoryCalendar.today().add(
                            Duration(days: tomorrow ? 1 : 0),
                          ),
                          team: team,
                          body: body.text,
                          important: important,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) showFailure(context, e);
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
  }
}
