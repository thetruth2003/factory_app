import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/report_incident_page.dart';
import 'package:factory_check_app/services/incident_service.dart';
import 'package:factory_check_app/services/locale_controller.dart';

const actor = FactoryUser(
  uid: 'watch',
  name: 'Watch',
  role: 'watcher',
  companyId: 'factory',
);
void main() {
  late FakeFirebaseFirestore db;
  setUp(() async {
    db = FakeFirebaseFirestore();
    LocaleController.instance.locale.value = const Locale('tr');
    await db.collection('machines').doc('m').set({
      'companyId': 'factory',
      'name': 'M',
    });
  });
  test(
    'reason codes must match call type and unowned machines cannot be claimed',
    () async {
      final service = IncidentService(db);
      Future<CreateIncidentResult> create(String machine, String? reason) =>
          service.createIncident(
            actor: actor,
            machineId: machine,
            machineKey: machine,
            description: 'Note',
            kind: 'fault',
            targetTeam: 'operator',
            productionStopped: false,
            reportedAt: DateTime.now(),
            reasonCode: reason,
          );
      await expectLater(
        create('m', 'packaging_seal'),
        throwsA(isA<WorkflowException>()),
      );
      await db.collection('machines').doc('unowned').set({'name': 'Unowned'});
      await expectLater(
        create('unowned', null),
        throwsA(isA<WorkflowException>()),
      );
      final result = await create('m', 'material_jam');
      expect(
        (await db
            .collection('incidents')
            .doc(result.incidentId)
            .get())['reasonCode'],
        'material_jam',
      );
    },
  );
  testWidgets(
    'suggestions fill empty text without erasing a workers own details',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MyApp(
          home: ReportIncidentPage(
            actor: actor,
            machineId: 'm',
            machineKey: 'M',
            db: db,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ürün / malzeme sıkıştı'));
      await tester.pumpAndSettle();
      final description = find.byType(TextFormField).first;
      expect(
        tester.widget<TextFormField>(description).controller!.text,
        'Ürün / malzeme sıkıştı',
      );
      await tester.ensureVisible(description);
      await tester.pumpAndSettle();
      await tester.enterText(description, 'Film soldaki makaraya takıldı.');
      await tester.ensureVisible(find.text('Makine alarm veriyor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makine alarm veriyor'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(description).controller!.text,
        'Film soldaki makaraya takıldı.',
      );
      // Changing kind clears the previous reason, while preserving manually entered text.
      await tester.ensureVisible(
        find.byType(DropdownButtonFormField<String>).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kalite sorunu').last);
      await tester.pumpAndSettle();
      expect(find.text('Paket kapanmıyor'), findsOneWidget);
      expect(find.text('Makine alarm veriyor'), findsNothing);
      expect(
        tester.widget<TextFormField>(description).controller!.text,
        'Film soldaki makaraya takıldı.',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
