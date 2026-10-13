import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/services/incident_service.dart';

const operatorUser = FactoryUser(
  uid: 'op1',
  name: 'Ali',
  role: 'operator',
  companyId: 'factory',
);
const otherOperator = FactoryUser(
  uid: 'op2',
  name: 'Ewa',
  role: 'operator',
  companyId: 'factory',
);
const watcher = FactoryUser(
  uid: 'watch1',
  name: 'Control',
  role: 'watcher',
  companyId: 'factory',
);
const foreignUser = FactoryUser(
  uid: 'other',
  name: 'Other',
  role: 'operator',
  companyId: 'other',
);
Matcher code(String value) =>
    isA<WorkflowException>().having((error) => error.code, 'code', value);

void main() {
  late FakeFirebaseFirestore db;
  late IncidentService service;
  setUp(() async {
    db = FakeFirebaseFirestore();
    service = IncidentService(db);
    await db.collection('machines').doc('1A').set({
      'companyId': 'factory',
      'name': '1A',
      'section': '1',
    });
  });
  Future<CreateIncidentResult> create({
    bool stopped = true,
    FactoryUser actor = watcher,
  }) => service.createIncident(
    actor: actor,
    machineId: '1A',
    machineKey: '1A',
    description: 'Packaging stopped',
    kind: 'fault',
    targetTeam: 'operator',
    productionStopped: stopped,
    reportedAt: DateTime.now().subtract(const Duration(minutes: 10)),
  );
  Future<void> start(String id) async {
    await service.transition(
      incidentId: id,
      actor: operatorUser,
      to: 'acknowledged',
    );
    await service.transition(
      incidentId: id,
      actor: operatorUser,
      to: 'in_progress',
    );
  }

  Future<Map<String, dynamic>> incident(String id) async =>
      (await db.collection('incidents').doc(id).get()).data()!;

  test(
    'each stop has a distinct interval closed once by resume or resolution',
    () async {
      final call = await create();
      await start(call.incidentId);
      var intervals = await db.collection('downtime_intervals').get();
      expect(intervals.size, 1);
      final firstId = intervals.docs.single.id;
      expect(intervals.docs.single.data()['companyId'], 'factory');
      expect(intervals.docs.single.data()['endAt'], isNull);
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: false,
      );
      final first =
          (await db.collection('downtime_intervals').doc(firstId).get())
              .data()!;
      expect(first['endAt'], isA<Timestamp>());
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: false,
      );
      expect((await db.collection('downtime_intervals').get()).size, 1);
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: true,
      );
      expect((await db.collection('downtime_intervals').get()).size, 2);
      await service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'resolved',
        machineRunning: true,
        message: 'Done',
      );
      intervals = await db.collection('downtime_intervals').get();
      expect(
        intervals.docs.every((d) => d.data()['endAt'] is Timestamp),
        isTrue,
      );
      expect(
        (await db.collection('downtime_intervals').doc(firstId).get()).data(),
        first,
      );
      expect((await incident(call.incidentId))['activeDowntimeId'], isNull);
    },
  );
  test(
    'a running call creates an interval only when production actually stops',
    () async {
      final call = await create(stopped: false);
      expect((await db.collection('downtime_intervals').get()).size, 0);
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: true,
      );
      expect((await db.collection('downtime_intervals').get()).size, 1);
      final before = await incident(call.incidentId);
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: true,
      );
      expect(
        (await incident(call.incidentId))['activeDowntimeId'],
        before['activeDowntimeId'],
      );
      expect((await db.collection('downtime_intervals').get()).size, 1);
    },
  );
  test(
    'legacy stop is preserved on resume without claiming full historical coverage',
    () async {
      await db.collection('incidents').doc('legacy').set({
        'schemaVersion': 2,
        'machineId': '1A',
        'machineKey': '1A',
        'createdByCompanyId': 'factory',
        'status': 'in_progress',
        'canRun': false,
        'downtimeStartedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        'downtimeSeconds': 900,
      });
      await db.collection('machines').doc('1A').update({
        'activeIncidentId': 'legacy',
      });
      await service.setProductionState(
        incidentId: 'legacy',
        actor: operatorUser,
        stopped: false,
      );
      expect((await incident('legacy'))['schemaVersion'], 2);
      expect(
        (await incident('legacy'))['downtimeSeconds'],
        greaterThanOrEqualTo(1020),
      );
      final intervals = await db.collection('downtime_intervals').get();
      expect(intervals.size, 1);
      expect(intervals.docs.single.data()['incidentId'], 'legacy');
      expect(intervals.docs.single.data()['endAt'], isA<Timestamp>());
    },
  );

  test(
    'creation writes the machine pointer, company, actor and audit event',
    () async {
      final call = await create();
      final data = await incident(call.incidentId);
      expect(call.created, isTrue);
      expect(data['createdByCompanyId'], 'factory');
      expect(data['reportedByName'], 'Control');
      expect(data['targetTeam'], 'operator');
      expect(data['downtimeStartedAt'], isA<Timestamp>());
      expect(
        (await db.collection('machines').doc('1A').get())
            .data()!['activeIncidentId'],
        call.incidentId,
      );
      expect(
        (await db
                .collection('incidents')
                .doc(call.incidentId)
                .collection('events')
                .get())
            .size,
        1,
      );
    },
  );
  test(
    'duplicate report returns the existing call without additional records',
    () async {
      final first = await create();
      final second = await create();
      expect(second.created, isFalse);
      expect(second.incidentId, first.incidentId);
      expect((await db.collection('incidents').get()).size, 1);
    },
  );
  test('a missing machine cannot silently be created by a report', () async {
    await db.collection('machines').doc('1A').delete();
    await expectLater(create(), throwsA(code('notFound')));
    expect((await db.collection('incidents').get()).size, 0);
  });
  test(
    'foreign company cannot create, change or add notes to a call',
    () async {
      await db.collection('machines').doc('1A').update({
        'companyId': 'factory',
      });
      await expectLater(create(actor: foreignUser), throwsA(code('forbidden')));
      final call = await create();
      await expectLater(
        service.transition(
          incidentId: call.incidentId,
          actor: foreignUser,
          to: 'acknowledged',
        ),
        throwsA(code('forbidden')),
      );
      await expectLater(
        service.addNote(
          incidentId: call.incidentId,
          actor: foreignUser,
          message: 'x',
        ),
        throwsA(code('forbidden')),
      );
    },
  );
  test(
    'watchers report and add notes, but cannot perform operator work',
    () async {
      final call = await create();
      await expectLater(
        service.transition(
          incidentId: call.incidentId,
          actor: watcher,
          to: 'acknowledged',
        ),
        throwsA(code('forbidden')),
      );
      await service.addNote(
        incidentId: call.incidentId,
        actor: watcher,
        message: 'Shift handover',
      );
      final notes = await db
          .collection('incidents')
          .doc(call.incidentId)
          .collection('events')
          .where('type', isEqualTo: 'note_added')
          .get();
      expect(notes.docs.single.data()['byName'], 'Control');
    },
  );
  test('another operator cannot take over an assigned call', () async {
    final call = await create();
    await service.transition(
      incidentId: call.incidentId,
      actor: operatorUser,
      to: 'acknowledged',
    );
    await expectLater(
      service.transition(
        incidentId: call.incidentId,
        actor: otherOperator,
        to: 'in_progress',
      ),
      throwsA(code('assignedElsewhere')),
    );
    expect((await incident(call.incidentId))['assignedToUid'], 'op1');
  });
  test('an open call cannot skip acknowledgement and work', () async {
    final call = await create();
    await expectLater(
      service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'resolved',
        message: 'Fixed',
        machineRunning: true,
      ),
      throwsA(code('invalidTransition')),
    );
  });
  test(
    'resolution rejects a stopped machine and preserves the active pointer',
    () async {
      final call = await create();
      await start(call.incidentId);
      await expectLater(
        service.transition(
          incidentId: call.incidentId,
          actor: operatorUser,
          to: 'resolved',
          message: 'Still broken',
          machineRunning: false,
        ),
        throwsA(code('notRunning')),
      );
      expect((await incident(call.incidentId))['status'], 'in_progress');
      expect(
        (await db.collection('machines').doc('1A').get())
            .data()!['activeIncidentId'],
        call.incidentId,
      );
    },
  );
  test(
    'waiting requires a reason and can resume without losing its owner',
    () async {
      final call = await create();
      await start(call.incidentId);
      await expectLater(
        service.transition(
          incidentId: call.incidentId,
          actor: operatorUser,
          to: 'waiting',
        ),
        throwsA(code('noteRequired')),
      );
      await service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'waiting',
        message: 'Need film',
      );
      expect((await incident(call.incidentId))['waitingReason'], 'Need film');
      await service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'in_progress',
      );
      expect((await incident(call.incidentId))['assignedToUid'], 'op1');
      expect((await incident(call.incidentId))['waitingReason'], isNull);
    },
  );
  test(
    'valid resolution records audit, time, notes and releases the machine',
    () async {
      final call = await create();
      await start(call.incidentId);
      await service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'resolved',
        message: 'Film replaced',
        machineRunning: true,
      );
      final data = await incident(call.incidentId);
      expect(data['status'], 'resolved');
      expect(data['canRun'], isTrue);
      expect(data['resolvedAt'], isA<Timestamp>());
      expect(data['downtimeSeconds'], greaterThanOrEqualTo(600));
      final machine = (await db.collection('machines').doc('1A').get()).data()!;
      expect(machine.containsKey('activeIncidentId'), isFalse);
      expect(machine['reportedState'], 'running');
      expect(
        (await db
                .collection('incidents')
                .doc(call.incidentId)
                .collection('events')
                .get())
            .size,
        4,
      );
    },
  );
  test('a stale detail screen cannot clear a newer machine call', () async {
    final call = await create();
    await start(call.incidentId);
    await db.collection('machines').doc('1A').update({
      'activeIncidentId': 'new-call',
    });
    await expectLater(
      service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'resolved',
        message: 'Fixed',
        machineRunning: true,
      ),
      throwsA(code('staleCall')),
    );
    expect(
      (await db.collection('machines').doc('1A').get())
          .data()!['activeIncidentId'],
      'new-call',
    );
    expect((await incident(call.incidentId))['status'], 'in_progress');
  });
  test(
    'resuming production stops downtime even while the call stays open',
    () async {
      final call = await create();
      await start(call.incidentId);
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: false,
      );
      final before = await incident(call.incidentId);
      expect(before['status'], 'in_progress');
      expect(before['canRun'], isTrue);
      final stoppedSeconds = before['downtimeSeconds'];
      await service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'resolved',
        message: 'Done',
        machineRunning: true,
      );
      expect(
        (await incident(call.incidentId))['downtimeSeconds'],
        stoppedSeconds,
      );
    },
  );
  test(
    'repeated stop/resume cycles accumulate without recounting old intervals',
    () async {
      final call = await create();
      await start(call.incidentId);
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: false,
      );
      final firstTotal =
          (await incident(call.incidentId))['downtimeSeconds'] as int;
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: true,
      );
      await db.collection('incidents').doc(call.incidentId).update({
        'downtimeStartedAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      });
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: false,
      );
      expect(
        (await incident(call.incidentId))['downtimeSeconds'],
        greaterThanOrEqualTo(firstTotal + 120),
      );
      final total = (await incident(call.incidentId))['downtimeSeconds'];
      await service.setProductionState(
        incidentId: call.incidentId,
        actor: operatorUser,
        stopped: false,
      );
      expect((await incident(call.incidentId))['downtimeSeconds'], total);
    },
  );
  test('running-machine requests have no invented downtime', () async {
    final call = await create(stopped: false);
    await start(call.incidentId);
    await service.transition(
      incidentId: call.incidentId,
      actor: operatorUser,
      to: 'resolved',
      message: 'Checked',
      machineRunning: true,
    );
    expect((await incident(call.incidentId))['downtimeSeconds'], 0);
  });
  test(
    'support handover releases assignment and a new worker takes the call',
    () async {
      const technician = FactoryUser(
        uid: 'tech1',
        name: 'Jan',
        role: 'maintenance',
        companyId: 'factory',
      );
      final call = await create();
      await start(call.incidentId);
      await service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'waiting',
        message: 'Motor needs inspection',
        targetTeam: 'maintenance',
      );
      final waiting = await incident(call.incidentId);
      expect(waiting['assignedToUid'], isNull);
      expect(waiting['targetTeam'], 'maintenance');
      await service.transition(
        incidentId: call.incidentId,
        actor: technician,
        to: 'in_progress',
      );
      expect((await incident(call.incidentId))['assignedToUid'], 'tech1');
      await expectLater(
        service.transition(
          incidentId: call.incidentId,
          actor: operatorUser,
          to: 'resolved',
          message: 'done',
          machineRunning: true,
        ),
        throwsA(code('assignedElsewhere')),
      );
    },
  );
  test('invalid repair time leaves the entire transaction unchanged', () async {
    final call = await create();
    await start(call.incidentId);
    await expectLater(
      service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'resolved',
        message: 'Fixed',
        machineRunning: true,
        repairedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      throwsA(code('invalidTime')),
    );
    expect((await incident(call.incidentId))['status'], 'in_progress');
  });
  test(
    'legacy email login preserves company, personal profiles use explicit company',
    () {
      expect(
        FactoryUser.fromProfile(
          uid: 'x',
          email: 'factory@company.local',
          profile: {'role': 'operator'},
        ).companyId,
        'factory',
      );
      expect(
        FactoryUser.fromProfile(
          uid: 'x',
          email: 'worker@example.com',
          profile: {'role': 'operator', 'companyId': 'factory', 'name': 'Ewa'},
        ).name,
        'Ewa',
      );
      expect(
        () => FactoryUser.fromProfile(
          uid: 'x',
          email: 'worker@example.com',
          profile: {},
        ),
        throwsA(code('profile')),
      );
    },
  );
}
