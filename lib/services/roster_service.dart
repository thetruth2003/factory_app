import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/roster.dart';
import '../models/workflow.dart';

class RosterService {
  RosterService(this.db, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  final FirebaseFirestore db;
  final DateTime Function() now;
  DocumentReference<Map<String, dynamic>> week(String company, DateTime day) =>
      db
          .collection('companies')
          .doc(company)
          .collection('roster_weeks')
          .doc(FactoryCalendar.key(FactoryCalendar.week(day)));
  CollectionReference<Map<String, dynamic>> shifts(
    String company,
    DateTime day,
  ) => week(company, day).collection('shifts');
  Query<Map<String, dynamic>> roster(FactoryUser actor, DateTime day) {
    if (!FactoryCalendar.admin(actor) &&
        FactoryCalendar.week(day) !=
            FactoryCalendar.week(FactoryCalendar.today(now()))) {
      throw const WorkflowException('forbidden');
    }
    final q = shifts(actor.companyId, day);
    return FactoryCalendar.admin(actor)
        ? q
        : q.where('team', isEqualTo: FactoryCalendar.team(actor));
  }

  DocumentReference<Map<String, dynamic>> assignment(
    String company,
    DateTime day,
    String uid,
  ) => shifts(company, day).doc('${FactoryCalendar.key(day)}_$uid');

  Future<void> saveShift({
    required FactoryUser actor,
    required String uid,
    required DateTime day,
    required int startMinute,
    required int endMinute,
    required String label,
  }) async {
    if (!FactoryCalendar.admin(actor)) {
      throw const WorkflowException('forbidden');
    }
    if (label.trim().isEmpty ||
        label.trim().length > 80 ||
        startMinute < 0 ||
        startMinute >= 1440 ||
        endMinute < 0 ||
        endMinute >= 1440 ||
        startMinute == endMinute) {
      throw const WorkflowException('invalidShift');
    }
    final d = FactoryCalendar.date(day);
    final start = FactoryCalendar.instant(d, startMinute);
    final end = FactoryCalendar.instant(
      endMinute <= startMinute ? d.add(const Duration(days: 1)) : d,
      endMinute,
    );
    if (end.difference(start) > const Duration(hours: 16)) {
      throw const WorkflowException('invalidShift');
    }
    final ref = assignment(actor.companyId, d, uid);
    final w = week(actor.companyId, d);
    await db.runTransaction((tx) async {
      final employee = (await tx.get(db.collection('users').doc(uid))).data();
      final before = (await tx.get(ref)).data();
      final report = await tx.get(ref.collection('reports').doc('end'));
      final prev = (await tx.get(
        assignment(actor.companyId, d.subtract(const Duration(days: 1)), uid),
      )).data();
      final next = (await tx.get(
        assignment(actor.companyId, d.add(const Duration(days: 1)), uid),
      )).data();
      if (employee == null ||
          employee['companyId'] != actor.companyId ||
          employee['isActive'] == false ||
          (employee['environment'] == 'training') != actor.isTraining) {
        throw const WorkflowException('forbidden');
      }
      final role = employee['role'] == 'technician'
          ? 'maintenance'
          : employee['role'];
      if (!FactoryCalendar.teams.contains(role)) {
        throw const WorkflowException('forbidden');
      }
      if (report.exists) throw const WorkflowException('reportLocked');
      for (final other in [prev, next]) {
        if (other != null &&
            other['cancelled'] != true &&
            start.isBefore((other['endAt'] as Timestamp).toDate()) &&
            end.isAfter((other['startAt'] as Timestamp).toDate())) {
          throw const WorkflowException('shiftOverlap');
        }
      }
      final monday = FactoryCalendar.week(d);
      tx.set(w, {
        'startAt': Timestamp.fromDate(FactoryCalendar.instant(monday, 0)),
        'endAt': Timestamp.fromDate(
          FactoryCalendar.instant(monday.add(const Duration(days: 7)), 0),
        ),
      });
      tx.set(ref, {
        'uid': uid,
        'name': employee['displayName'] ?? employee['name'] ?? uid,
        'team': role,
        'day': Timestamp.fromDate(d),
        'label': label.trim(),
        'startAt': Timestamp.fromDate(start),
        'endAt': Timestamp.fromDate(end),
        'cancelled': false,
        'createdAt': before?['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedByUid': actor.uid,
      });
    });
  }

  Future<void> cancelShift(
    FactoryUser actor,
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    if (!FactoryCalendar.admin(actor) ||
        !ref.path.startsWith('companies/${actor.companyId}/roster_weeks/')) {
      throw const WorkflowException('forbidden');
    }
    await db.runTransaction((tx) async {
      final old = await tx.get(ref);
      final report = await tx.get(ref.collection('reports').doc('end'));
      if (!old.exists) throw const WorkflowException('notFound');
      if (report.exists) throw const WorkflowException('reportLocked');
      tx.update(ref, {
        'cancelled': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedByUid': actor.uid,
      });
    });
  }

  Future<void> saveReport({
    required FactoryUser actor,
    required DocumentReference<Map<String, dynamic>> shift,
    required String summary,
    required String problems,
    required String followUp,
  }) async {
    if (!shift.path.startsWith('companies/${actor.companyId}/roster_weeks/') ||
        !actor.canReport) {
      throw const WorkflowException('forbidden');
    }
    if (summary.trim().isEmpty ||
        [summary, problems, followUp].any((s) => s.trim().length > 2000)) {
      throw const WorkflowException('noteRequired');
    }
    final ref = shift.collection('reports').doc('end');
    await db.runTransaction((tx) async {
      final s = (await tx.get(shift)).data();
      final previous = await tx.get(ref);
      if (s == null || s['uid'] != actor.uid || s['cancelled'] == true) {
        throw const WorkflowException('forbidden');
      }
      if (previous.exists) return; // Stable id makes a retry safe.
      if (now().isBefore((s['startAt'] as Timestamp).toDate()) ||
          now().isAfter(
            (s['endAt'] as Timestamp).toDate().add(const Duration(hours: 24)),
          )) {
        throw const WorkflowException('reportTime');
      }
      tx.set(ref, {
        'summary': summary.trim(),
        'problems': problems.trim(),
        'followUp': followUp.trim(),
        'createdByUid': actor.uid,
        'createdByName': actor.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  CollectionReference<Map<String, dynamic>> notes(String company) =>
      db.collection('companies').doc(company).collection('team_notes');
  Query<Map<String, dynamic>> dayNotes(FactoryUser actor, DateTime day) {
    Query<Map<String, dynamic>> q = notes(actor.companyId).where(
      'targetDay',
      isEqualTo: Timestamp.fromDate(FactoryCalendar.date(day)),
    );
    if (!FactoryCalendar.admin(actor)) {
      q = q.where('team', isEqualTo: FactoryCalendar.team(actor));
    }
    return q;
  }

  Future<void> leaveNote({
    required FactoryUser actor,
    required String id,
    required DateTime day,
    required String team,
    required String body,
    required bool important,
  }) async {
    final target = FactoryCalendar.date(day),
        today = FactoryCalendar.today(now());
    if (!actor.canReport ||
        !FactoryCalendar.teams.contains(team) ||
        (!FactoryCalendar.admin(actor) &&
            team != FactoryCalendar.team(actor))) {
      throw const WorkflowException('forbidden');
    }
    if (target != today && target != today.add(const Duration(days: 1))) {
      throw const WorkflowException('invalidTime');
    }
    if (body.trim().isEmpty || body.trim().length > 2000) {
      throw const WorkflowException('noteRequired');
    }
    final ref = notes(actor.companyId).doc(id);
    await db.runTransaction((tx) async {
      final old = await tx.get(ref);
      if (old.exists) {
        if (old.data()!['createdByUid'] != actor.uid) {
          throw const WorkflowException('forbidden');
        }
        return;
      }
      tx.set(ref, {
        'team': team,
        'targetDay': Timestamp.fromDate(target),
        'body': body.trim(),
        'important': important,
        'createdByUid': actor.uid,
        'createdByName': actor.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markRead(
    FactoryUser actor,
    DocumentReference<Map<String, dynamic>> note,
  ) async {
    final ref = note.collection('reads').doc(actor.uid);
    await db.runTransaction((tx) async {
      if ((await tx.get(ref)).exists) return;
      tx.set(ref, {'name': actor.name, 'at': FieldValue.serverTimestamp()});
    });
  }
}
