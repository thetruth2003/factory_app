import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/home_page.dart';
import 'package:factory_check_app/services/incident_service.dart';
import 'package:factory_check_app/services/locale_controller.dart';

const watcher = FactoryUser(
  uid: 'watch',
  name: 'Test İzleme',
  role: 'watcher',
  companyId: 'pilot',
  isTraining: true,
);
const operatorUser = FactoryUser(
  uid: 'op',
  name: 'Test Operatör',
  role: 'operator',
  companyId: 'pilot',
  isTraining: true,
);

void main() {
  late FakeFirebaseFirestore db;
  setUp(() async {
    LocaleController.instance.locale.value = const Locale('tr');
    db = FakeFirebaseFirestore();
    await db.collection('machines').doc('legacy').set({'name': 'Gerçek hat'});
    await db.collection('machines').doc('test').set({
      'name': 'TEST-1',
      'companyId': 'pilot',
      'environment': 'training',
    });
  });
  test('profile flag is distinct from the earlier admin testAccount flag', () {
    expect(
      FactoryUser.fromProfile(
        uid: 'x',
        email: 'x@company.local',
        profile: {
          'companyId': 'pilot',
          'environment': 'training',
          'role': 'watcher',
        },
      ).isTraining,
      isTrue,
    );
    expect(
      FactoryUser.fromProfile(
        uid: 'x',
        email: 'x@company.local',
        profile: {'companyId': 'real', 'testAccount': true, 'role': 'admin'},
      ).isTraining,
      isFalse,
    );
  });
  test(
    'training users cannot report against a legacy or foreign machine',
    () async {
      final service = IncidentService(db);
      for (final machineId in ['legacy', 'foreign']) {
        if (machineId == 'foreign') {
          await db.collection('machines').doc('foreign').set({
            'companyId': 'real',
          });
        }
        await expectLater(
          service.createIncident(
            actor: watcher,
            machineId: machineId,
            machineKey: machineId,
            description: 'Example',
            kind: 'fault',
            targetTeam: 'operator',
            productionStopped: true,
            reportedAt: DateTime.now(),
          ),
          throwsA(
            isA<WorkflowException>().having((e) => e.code, 'code', 'forbidden'),
          ),
        );
      }
      expect((await db.collection('incidents').get()).size, 0);
    },
  );
  test(
    'two test actors complete a shared call without changing a real machine',
    () async {
      final service = IncidentService(db);
      final call = await service.createIncident(
        actor: watcher,
        machineId: 'test',
        machineKey: 'TEST-1',
        description: 'Test film jam',
        kind: 'fault',
        targetTeam: 'operator',
        productionStopped: true,
        reportedAt: DateTime.now(),
      );
      for (final status in ['acknowledged', 'in_progress']) {
        await service.transition(
          incidentId: call.incidentId,
          actor: operatorUser,
          to: status,
        );
      }
      await service.transition(
        incidentId: call.incidentId,
        actor: operatorUser,
        to: 'resolved',
        message: 'Test completed',
        machineRunning: true,
      );
      final data = (await db.collection('incidents').doc(call.incidentId).get())
          .data()!;
      expect(data['environment'], 'training');
      expect(data['status'], 'resolved');
      expect(data['createdByCompanyId'], 'pilot');
      expect(
        (await db.collection('downtime_intervals').get()).docs.single
            .data()['environment'],
        'training',
      );
      expect((await db.collection('machines').doc('legacy').get()).data(), {
        'name': 'Gerçek hat',
      });
    },
  );
  testWidgets(
    'test home hides legacy machines and live home hides training machines',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MyApp(
          home: HomePage(actor: watcher, db: db, enableNotifications: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SAHA TESTİ'), findsOneWidget);
      expect(find.text('İki cihazla test adımları'), findsOneWidget);
      await tester.tap(
        find.byIcon(Icons.precision_manufacturing_outlined).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Gerçek hat'), findsNothing);
      expect(find.text('TEST-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await db.collection('machines').doc('legacy').update({
        'companyId': 'real',
      });
      const liveActor = FactoryUser(
        uid: 'live',
        name: 'Live',
        role: 'operator',
        companyId: 'real',
      );
      await tester.pumpWidget(
        MyApp(
          home: HomePage(actor: liveActor, db: db, enableNotifications: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byIcon(Icons.precision_manufacturing_outlined).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('TEST-1'), findsNothing);
      expect(find.text('Gerçek hat'), findsOneWidget);
      expect(find.text('SAHA TESTİ'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
