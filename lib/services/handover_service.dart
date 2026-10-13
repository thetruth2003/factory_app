import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workflow.dart';

class HandoverService {
  HandoverService(this.db);
  final FirebaseFirestore db;
  static const teams = ['watcher', ...Workflow.teams];
  // Keep the atomic transfer within Firestore's rules document-access budget.
  static const maxCalls = 6;
  static bool canReceive(FactoryUser actor, String team) =>
      actor.canReport &&
      (actor.canSupervise ||
          (actor.role == 'technician' ? 'maintenance' : actor.role) == team);

  CollectionReference<Map<String, dynamic>> records(String companyId) =>
      db.collection('companies').doc(companyId).collection('handovers');

  /// The form keeps one ID across retries so a lost response cannot duplicate it.
  Future<void> create({
    required String id,
    required FactoryUser actor,
    required String shift,
    required String team,
    required String notes,
    required List<String> incidentIds,
  }) async {
    Workflow.validateActor(actor);
    if (shift.trim().isEmpty || notes.trim().isEmpty) {
      throw const WorkflowException('noteRequired');
    }
    final ids = incidentIds.toSet().toList()..sort();
    if (shift.trim().length > 80 ||
        notes.trim().length > 2000 ||
        ids.length > maxCalls ||
        !teams.contains(team)) {
      throw const WorkflowException('invalidHandover');
    }
    final ref = records(actor.companyId).doc(id);
    await db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) {
        if (existing.data()?['createdByUid'] != actor.uid ||
            existing.data()?['companyId'] != actor.companyId) {
          throw const WorkflowException('forbidden');
        }
        return;
      }
      final calls = <Map<String, dynamic>>[];
      for (final id in ids) {
        final snap = await tx.get(db.collection('incidents').doc(id));
        final data = snap.data();
        if (data == null) throw const WorkflowException('notFound');
        if (data['createdByCompanyId'] != actor.companyId) {
          throw const WorkflowException('forbidden');
        }
        if (!Workflow.isActive((data['status'] ?? '').toString())) {
          throw const WorkflowException('handoverChanged');
        }
        calls.add({
          'incidentId': id,
          'machineId': data['machineId'],
          'machineKey': data['machineKey'],
          'status': data['status'],
          'canRun': data['canRun'],
          'targetTeam': data['targetTeam'],
          'assignedToUid': data['assignedToUid'],
          'assignedToName': data['assignedToName'],
          'description': (data['description'] ?? '').toString(),
        });
      }
      tx.set(ref, {
        'schemaVersion': 1,
        'environment': actor.isTraining ? 'training' : 'production',
        'companyId': actor.companyId,
        'shift': shift.trim(),
        'team': team,
        'notes': notes.trim(),
        'createdByUid': actor.uid,
        'createdByName': actor.name,
        'createdByRole': actor.role,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'calls': calls,
        'incidentIds': ids,
        'acceptedByUid': null,
        'acceptedAt': null,
      });
    });
  }

  Future<void> accept({required String id, required FactoryUser actor}) async {
    Workflow.validateActor(actor);
    final ref = records(actor.companyId).doc(id);
    await db.runTransaction((tx) async {
      final data = (await tx.get(ref)).data();
      if (data == null) throw const WorkflowException('notFound');
      if (data['companyId'] != actor.companyId) {
        throw const WorkflowException('forbidden');
      }
      if (data['status'] == 'accepted') {
        if (data['acceptedByUid'] == actor.uid) return;
        throw const WorkflowException('handoverAccepted');
      }
      if (data['createdByUid'] == actor.uid) {
        throw const WorkflowException('handoverSelf');
      }
      if (!canReceive(actor, (data['team'] ?? '').toString())) {
        throw const WorkflowException('handoverTeam');
      }
      final transfers = <DocumentSnapshot<Map<String, dynamic>>>[];
      // Read every potential transfer before issuing transaction writes.
      if (actor.canManage) {
        final ids = (data['calls'] as List? ?? [])
            .map((c) => (c as Map)['incidentId'] as String)
            .toSet();
        for (final callId in ids) {
          final call = await tx.get(db.collection('incidents').doc(callId));
          final current = call.data();
          if (current == null) continue;
          if (current['createdByCompanyId'] != actor.companyId) {
            throw const WorkflowException('forbidden');
          }
          if (Workflow.isActive((current['status'] ?? '').toString()) &&
              current['assignedToUid'] == data['createdByUid']) {
            transfers.add(call);
          }
        }
      }
      for (final call in transfers) {
        tx.update(call.reference, {
          'assignedToUid': actor.uid,
          'assignedToName': actor.name,
          'updatedAt': FieldValue.serverTimestamp(),
          'lastHandoverId': id,
        });
        tx.set(call.reference.collection('events').doc(), {
          'type': 'handover_received',
          'at': FieldValue.serverTimestamp(),
          'byUid': actor.uid,
          'byName': actor.name,
          'byRole': actor.role,
          'previousAssignedToUid': data['createdByUid'],
          'previousAssignedToName': data['createdByName'],
          'handoverId': id,
          'message': data['shift'],
        });
      }
      tx.update(ref, {
        'status': 'accepted',
        'acceptedByUid': actor.uid,
        'acceptedByName': actor.name,
        'acceptedAt': FieldValue.serverTimestamp(),
        'transferredCalls': transfers.length,
      });
    });
  }
}
