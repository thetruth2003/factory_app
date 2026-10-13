import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/services/handover_service.dart';

const sender = FactoryUser(
  uid: 'first',
  name: 'Ali',
  role: 'operator',
  companyId: 'factory',
);
const receiver = FactoryUser(
  uid: 'second',
  name: 'Ewa',
  role: 'operator',
  companyId: 'factory',
);
const third = FactoryUser(
  uid: 'third',
  name: 'Jan',
  role: 'maintenance',
  companyId: 'factory',
);
Matcher code(String code) =>
    isA<WorkflowException>().having((e) => e.code, 'code', code);

void main() {
  late FakeFirebaseFirestore db;
  late HandoverService service;
  setUp(() async {
    db = FakeFirebaseFirestore();
    service = HandoverService(db);
    await db.collection('incidents').doc('call').set({
      'createdByCompanyId': 'factory',
      'machineId': '1A',
      'machineKey': 'Paketleme',
      'description': 'Film bekleniyor',
      'status': 'in_progress',
      'canRun': false,
      'assignedToUid': sender.uid,
      'assignedToName': sender.name,
    });
  });
  Future<void> create({
    List<String> ids = const ['call'],
    String notes = 'Kontrol edilecek',
    FactoryUser actor = sender,
    String team = 'operator',
  }) => service.create(
    id: 'shift',
    actor: actor,
    shift: 'Gece 22–06',
    team: team,
    notes: notes,
    incidentIds: ids,
  );
  Future<Map<String, dynamic>> record() async =>
      (await service.records('factory').doc('shift').get()).data()!;

  test(
    'handover stores an immutable snapshot and retries do not duplicate it',
    () async {
      await create(ids: ['call', 'call']);
      await db.collection('incidents').doc('call').update({
        'description': 'Changed',
        'status': 'resolved',
      });
      await create(notes: 'Retry');
      final data = await record();
      expect((data['calls'] as List).length, 1);
      expect(data['calls'][0]['description'], 'Film bekleniyor');
      expect(data['calls'][0]['status'], 'in_progress');
      expect(data['notes'], 'Kontrol edilecek');
      expect(data['createdAt'], isA<Timestamp>());
      expect((await service.records('factory').get()).size, 1);
    },
  );
  test('handover without calls still records a shift note', () async {
    await create(ids: []);
    await service.accept(id: 'shift', actor: receiver);
    expect((await record())['status'], 'accepted');
    expect((await record())['transferredCalls'], 0);
  });
  test(
    'receipt transfers a still assigned active call and records its audit event',
    () async {
      await create();
      await service.accept(id: 'shift', actor: receiver);
      final call = (await db.collection('incidents').doc('call').get()).data()!;
      expect(call['assignedToUid'], receiver.uid);
      expect(call['status'], 'in_progress');
      expect(call['canRun'], isFalse);
      expect((await record())['acceptedByName'], 'Ewa');
      expect((await record())['transferredCalls'], 1);
      expect((await record())['calls'][0]['assignedToUid'], sender.uid);
      final events = await db
          .collection('incidents')
          .doc('call')
          .collection('events')
          .get();
      expect(events.docs.single.data()['type'], 'handover_received');
      await service.accept(id: 'shift', actor: receiver);
      expect(
        (await db
                .collection('incidents')
                .doc('call')
                .collection('events')
                .get())
            .size,
        1,
      );
      await expectLater(
        service.accept(id: 'shift', actor: third),
        throwsA(code('handoverAccepted')),
      );
      expect((await record())['acceptedByUid'], receiver.uid);
    },
  );
  test(
    'receipt preserves a newer assignee and skips completed calls',
    () async {
      await db.collection('incidents').doc('closedLater').set({
        'createdByCompanyId': 'factory',
        'machineId': '2A',
        'status': 'in_progress',
        'assignedToUid': sender.uid,
      });
      await create(ids: ['call', 'closedLater']);
      await db.collection('incidents').doc('call').update({
        'assignedToUid': third.uid,
      });
      await db.collection('incidents').doc('closedLater').update({
        'status': 'resolved',
      });
      await service.accept(id: 'shift', actor: receiver);
      expect((await record())['transferredCalls'], 0);
      expect(
        (await db.collection('incidents').doc('call').get())
            .data()!['assignedToUid'],
        third.uid,
      );
      expect(
        (await db.collection('incidents').doc('closedLater').get())
            .data()!['assignedToUid'],
        sender.uid,
      );
    },
  );
  test(
    'watcher can receive notes without taking operational ownership',
    () async {
      await create(team: 'watcher');
      const watcher = FactoryUser(
        uid: 'watch',
        name: 'Control',
        role: 'watcher',
        companyId: 'factory',
      );
      await service.accept(id: 'shift', actor: watcher);
      expect((await record())['transferredCalls'], 0);
      expect(
        (await db.collection('incidents').doc('call').get())
            .data()!['assignedToUid'],
        sender.uid,
      );
    },
  );
  test(
    'rejects self receipt, viewer writes and foreign call selection',
    () async {
      const viewer = FactoryUser(
        uid: 'v',
        name: 'View',
        role: 'viewer',
        companyId: 'factory',
      );
      const foreign = FactoryUser(
        uid: 'f',
        name: 'Foreign',
        role: 'operator',
        companyId: 'other',
      );
      await expectLater(create(actor: viewer), throwsA(code('forbidden')));
      await expectLater(create(actor: foreign), throwsA(code('forbidden')));
      await create();
      await expectLater(
        service.accept(id: 'shift', actor: sender),
        throwsA(code('handoverSelf')),
      );
      await expectLater(
        service.accept(id: 'shift', actor: viewer),
        throwsA(code('forbidden')),
      );
      await expectLater(
        service.accept(id: 'shift', actor: foreign),
        throwsA(code('notFound')),
      );
      expect((await record())['status'], 'pending');
    },
  );
  test(
    'changed or missing selected calls and empty notes do not save partial handovers',
    () async {
      await expectLater(create(notes: '  '), throwsA(code('noteRequired')));
      await expectLater(create(ids: ['missing']), throwsA(code('notFound')));
      await db.collection('incidents').doc('call').update({
        'status': 'resolved',
      });
      await expectLater(create(), throwsA(code('handoverChanged')));
      expect((await service.records('factory').get()).size, 0);
    },
  );
  test('cannot replace a handover created by someone else', () async {
    await create();
    await expectLater(create(actor: receiver), throwsA(code('forbidden')));
    expect((await record())['createdByUid'], sender.uid);
  });
  test('another team cannot consume an operator handover', () async {
    await create();
    await expectLater(
      service.accept(id: 'shift', actor: third),
      throwsA(code('handoverTeam')),
    );
    expect((await record())['status'], 'pending');
    expect(
      (await db.collection('incidents').doc('call').get())
          .data()!['assignedToUid'],
      sender.uid,
    );
  });
}
