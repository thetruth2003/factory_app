import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workflow.dart';
import '../models/call_reasons.dart';

class IncidentService {
  IncidentService(this.db);
  final FirebaseFirestore db;
  DocumentReference<Map<String, dynamic>> _machine(String id) =>
      db.collection('machines').doc(id);
  DocumentReference<Map<String, dynamic>> _incident(String id) =>
      db.collection('incidents').doc(id);
  Map<String, dynamic> _interval(
    String incidentId,
    Map<String, dynamic> data,
    Timestamp start, {
    Timestamp? end,
  }) => {
    'companyId': data['createdByCompanyId'] ?? data['companyId'],
    'environment': data['environment'] ?? 'production',
    'incidentId': incidentId,
    'machineId': data['machineId'],
    'machineKey': data['machineKey'],
    'startAt': start,
    'endAt': end,
  };

  void _finishInterval(
    Transaction tx,
    String incidentId,
    Map<String, dynamic> data,
    Timestamp start,
    DateTime end,
    Map<String, dynamic> updates,
  ) {
    final intervalId = data['activeDowntimeId'] as String?;
    // Legacy calls have no interval ID. Preserve their last known stop only.
    final ref = db.collection('downtime_intervals').doc(intervalId);
    tx.set(
      ref,
      _interval(incidentId, data, start, end: Timestamp.fromDate(end)),
    );
    updates['activeDowntimeId'] = null;
  }

  Map<String, dynamic> _event(
    FactoryUser actor,
    String type,
    String message, {
    String? from,
    String? to,
  }) => {
    'type': type,
    'at': FieldValue.serverTimestamp(),
    'byUid': actor.uid,
    'byName': actor.name,
    'byRole': actor.role,
    'fromStatus': from,
    'toStatus': to,
    'message': message.trim(),
  };
  void _checkCompany(Map<String, dynamic> incident, FactoryUser actor) {
    final company = incident['createdByCompanyId'] ?? incident['companyId'];
    if (company != actor.companyId) throw const WorkflowException('forbidden');
    if (actor.isTraining && incident['environment'] != 'training') {
      throw const WorkflowException('forbidden');
    }
  }

  /// A duplicate report opens the existing call. Firestore retries atomically.
  Future<CreateIncidentResult> createIncident({
    required FactoryUser actor,
    required String machineId,
    required String machineKey,
    required String description,
    required String kind,
    required String targetTeam,
    required bool productionStopped,
    required DateTime reportedAt,
    String errorCode = '',
    String? reasonCode,
  }) async {
    Workflow.validateActor(actor);
    Workflow.validateTime(reportedAt);
    if (description.trim().isEmpty) {
      throw const WorkflowException('noteRequired');
    }
    if (!Workflow.kinds.contains(kind) ||
        !Workflow.teams.contains(targetTeam) ||
        !CallReasons.valid(kind, reasonCode)) {
      throw const WorkflowException('invalidTransition');
    }
    final machineRef = _machine(machineId);
    final incidentRef = db.collection('incidents').doc();
    final eventRef = incidentRef.collection('events').doc();
    final downtimeRef = db.collection('downtime_intervals').doc();
    return db.runTransaction((tx) async {
      final machineSnap = await tx.get(machineRef);
      final machine = machineSnap.data();
      if (machine == null) throw const WorkflowException('notFound');
      if (machine['companyId'] != actor.companyId ||
          (actor.isTraining && machine['environment'] != 'training')) {
        throw const WorkflowException('forbidden');
      }
      final existing = (machine['activeIncidentId'] ?? '').toString().trim();
      if (existing.isNotEmpty) {
        final existingSnap = await tx.get(_incident(existing));
        final data = existingSnap.data();
        if (data != null && data['status'] != 'resolved') {
          _checkCompany(data, actor);
          return CreateIncidentResult(existing, created: false);
        }
      }
      final at = Timestamp.fromDate(reportedAt);
      final category = productionStopped ? 'red' : 'yellow';
      tx.set(incidentRef, {
        'schemaVersion': 3,
        'environment': actor.isTraining ? 'training' : 'production',
        'machineId': machineId,
        'machineKey': machineKey,
        'createdByCompanyId': actor.companyId,
        'createdByUid': actor.uid,
        'reportedByName': actor.name,
        'reportedByRole': actor.role,
        'description': description.trim(),
        'kind': kind,
        'reasonCode': reasonCode,
        'targetTeam': targetTeam,
        'errorCode': errorCode.trim(),
        'category': category,
        'status': 'open',
        'canRun': !productionStopped,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reportedAt': at,
        'openedAt': at,
        'ackAt': null,
        'resolvedAt': null,
        'assignedToUid': null,
        'assignedToName': null,
        'downtimeStartedAt': productionStopped ? at : null,
        'downtimeEndedAt': null,
        'downtimeSeconds': 0,
        'activeDowntimeId': productionStopped ? downtimeRef.id : null,
      });
      if (productionStopped) {
        tx.set(
          downtimeRef,
          _interval(incidentRef.id, {
            'createdByCompanyId': actor.companyId,
            'environment': actor.isTraining ? 'training' : 'production',
            'machineId': machineId,
            'machineKey': machineKey,
          }, at),
        );
      }
      tx.update(machineRef, {
        'activeIncidentId': incidentRef.id,
        'activeStatus': 'open',
        'activeCategory': category,
        'activeOpenedAt': at,
        'reportedState': productionStopped ? 'stopped' : 'running',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(eventRef, _event(actor, 'created', description, to: 'open'));
      return CreateIncidentResult(incidentRef.id, created: true);
    });
  }

  Future<void> transition({
    required String incidentId,
    required FactoryUser actor,
    required String to,
    String message = '',
    String? targetTeam,
    DateTime? repairedAt,
    bool machineRunning = false,
    bool needsTeam = false,
  }) async {
    Workflow.validateActor(actor, manage: true);
    if (targetTeam != null && !Workflow.teams.contains(targetTeam)) {
      throw const WorkflowException('invalidTransition');
    }
    if (to == 'waiting' && message.trim().isEmpty) {
      throw const WorkflowException('noteRequired');
    }
    if (to == 'resolved') {
      Workflow.validateResolution(
        machineRunning: machineRunning,
        needsTeam: needsTeam,
        notes: message,
      );
    }
    final incidentRef = _incident(incidentId);
    final eventRef = incidentRef.collection('events').doc();
    await db.runTransaction((tx) async {
      final snap = await tx.get(incidentRef);
      final data = snap.data();
      if (data == null) throw const WorkflowException('notFound');
      _checkCompany(data, actor);
      final machineRef = _machine(data['machineId'] as String);
      final machineSnap = await tx.get(machineRef);
      if (machineSnap.data()?['activeIncidentId'] != incidentId) {
        throw const WorkflowException('staleCall');
      }
      final from = (data['status'] ?? 'open').toString();
      Workflow.validateTransition(from, to);
      Workflow.validateOwnership(
        actor: actor,
        assignedUid: (data['assignedToUid'] ?? '').toString(),
      );
      final updates = <String, dynamic>{
        'status': to,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (to == 'acknowledged' ||
          (data['assignedToUid'] ?? '').toString().isEmpty) {
        updates.addAll({
          'assignedToUid': actor.uid,
          'assignedToName': actor.name,
          'ackAt': data['ackAt'] ?? FieldValue.serverTimestamp(),
        });
      }
      if (to == 'in_progress' && data['workStartedAt'] == null) {
        updates['workStartedAt'] = FieldValue.serverTimestamp();
      }
      updates['waitingReason'] = to == 'waiting' ? message.trim() : null;
      if (to == 'waiting' && targetTeam != null) {
        updates.addAll({
          'targetTeam': targetTeam,
          'assignedToUid': null,
          'assignedToName': null,
        });
      }
      final machineUpdates = <String, dynamic>{
        'activeStatus': to,
        'reportedState': data['canRun'] == false ? 'stopped' : 'running',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (to == 'resolved') {
        final end = repairedAt ?? DateTime.now();
        final openedAt =
            data['openedAt'] ?? data['reportedAt'] ?? data['createdAt'];
        Workflow.validateTime(
          end,
          after: openedAt is Timestamp ? openedAt.toDate() : null,
        );
        final stop = data['downtimeStartedAt'];
        if (stop is Timestamp) Workflow.validateTime(end, after: stop.toDate());
        updates.addAll({
          'resolvedAt': Timestamp.fromDate(end),
          'repairedAt': Timestamp.fromDate(end),
          'repairedByUid': actor.uid,
          'repairedByName': actor.name,
          'repairedByRole': actor.role,
          'repairNotes': message.trim(),
          'machineRunsAfter': true,
          'canRun': true,
          'needsTeam': false,
        });
        // Never interpret legacy call-open time as production downtime.
        if (stop is Timestamp && data['downtimeEndedAt'] == null) {
          updates['downtimeEndedAt'] = Timestamp.fromDate(end);
          updates['downtimeSeconds'] =
              (data['downtimeSeconds'] as num? ?? 0).toInt() +
              end.difference(stop.toDate()).inSeconds;
          _finishInterval(tx, incidentId, data, stop, end, updates);
        }
        machineUpdates.addAll({
          'activeIncidentId': FieldValue.delete(),
          'activeOpenedAt': FieldValue.delete(),
          'activeCategory': 'green',
          'reportedState': 'running',
        });
      }
      tx.update(incidentRef, updates);
      tx.update(machineRef, machineUpdates);
      tx.set(
        eventRef,
        _event(actor, 'status_changed', message, from: from, to: to),
      );
    });
  }

  Future<void> addNote({
    required String incidentId,
    required FactoryUser actor,
    required String message,
  }) async {
    Workflow.validateActor(actor);
    if (message.trim().isEmpty) throw const WorkflowException('noteRequired');
    final ref = _incident(incidentId);
    final eventRef = ref.collection('events').doc();
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw const WorkflowException('notFound');
      _checkCompany(data, actor);
      tx.update(ref, {'updatedAt': FieldValue.serverTimestamp()});
      tx.set(eventRef, _event(actor, 'note_added', message));
    });
  }

  /// Production may restart before the call is closed. Each interval is counted once.
  Future<void> setProductionState({
    required String incidentId,
    required FactoryUser actor,
    required bool stopped,
  }) async {
    Workflow.validateActor(actor, manage: true);
    final ref = _incident(incidentId);
    final event = ref.collection('events').doc();
    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null) throw const WorkflowException('notFound');
      _checkCompany(data, actor);
      if (data['status'] == 'resolved') {
        throw const WorkflowException('invalidTransition');
      }
      Workflow.validateOwnership(
        actor: actor,
        assignedUid: (data['assignedToUid'] ?? '').toString(),
      );
      final machineRef = _machine(data['machineId'] as String);
      final machine = await tx.get(machineRef);
      if (machine.data()?['activeIncidentId'] != incidentId) {
        throw const WorkflowException('staleCall');
      }
      if (data['canRun'] == !stopped) return;
      final now = DateTime.now();
      final updates = <String, dynamic>{
        'canRun': !stopped,
        'category': stopped ? 'red' : 'yellow',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (stopped) {
        updates['downtimeStartedAt'] = Timestamp.fromDate(now);
        updates['downtimeEndedAt'] = null;
        final intervalRef = db.collection('downtime_intervals').doc();
        updates['activeDowntimeId'] = intervalRef.id;
        tx.set(
          intervalRef,
          _interval(incidentId, data, Timestamp.fromDate(now)),
        );
      } else {
        final start = data['downtimeStartedAt'];
        if (start is Timestamp && data['downtimeEndedAt'] == null) {
          Workflow.validateTime(now, after: start.toDate());
          updates['downtimeSeconds'] =
              (data['downtimeSeconds'] as num? ?? 0).toInt() +
              now.difference(start.toDate()).inSeconds;
          updates['downtimeEndedAt'] = Timestamp.fromDate(now);
          _finishInterval(tx, incidentId, data, start, now, updates);
        }
      }
      tx.update(ref, updates);
      tx.update(machineRef, {
        'reportedState': stopped ? 'stopped' : 'running',
        'activeCategory': stopped ? 'red' : 'yellow',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        event,
        _event(
          actor,
          stopped ? 'production_stopped' : 'production_resumed',
          '',
        ),
      );
    });
  }
}

class CreateIncidentResult {
  const CreateIncidentResult(this.incidentId, {required this.created});
  final String incidentId;
  final bool created;
}
