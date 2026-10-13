import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/home_page.dart';
import 'package:factory_check_app/services/locale_controller.dart';

const outgoing = FactoryUser(
  uid: 'op1',
  name: 'Ali',
  role: 'operator',
  companyId: 'factory',
);
const incoming = FactoryUser(
  uid: 'op2',
  name: 'Ewa',
  role: 'operator',
  companyId: 'factory',
);

void main() {
  setUp(() => LocaleController.instance.locale.value = const Locale('tr'));
  testWidgets(
    'worker saves handover and another worker receives its outstanding call',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FakeFirebaseFirestore();
      await db.collection('machines').doc('1A').set({
        'companyId': 'factory',
        'name': '1A',
      });
      await db.collection('incidents').doc('call').set({
        'createdByCompanyId': 'factory',
        'machineId': '1A',
        'machineKey': '1A',
        'status': 'in_progress',
        'description': 'Film bekleniyor',
        'canRun': true,
        'assignedToUid': outgoing.uid,
        'assignedToName': outgoing.name,
        'createdAt': Timestamp.now(),
      });
      await tester.pumpWidget(
        MyApp(
          home: HomePage(actor: outgoing, db: db, enableNotifications: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.swap_horiz).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vardiya devri oluştur'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Gece 22–06');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Malzeme depodan gelecek.',
      );
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      final save = find.text('Devri kaydet');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final records = db
          .collection('companies')
          .doc('factory')
          .collection('handovers');
      expect((await records.get()).size, 1);
      expect(find.text('Gece 22–06'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Simulate another authenticated worker opening the same company's record.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MyApp(
          home: HomePage(actor: incoming, db: db, enableNotifications: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.swap_horiz).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gece 22–06'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vardiyayı teslim al'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vardiyayı teslim al').last);
      await tester.pumpAndSettle();
      expect(
        (await records.get()).docs.single.data()['acceptedByUid'],
        incoming.uid,
      );
      expect(
        (await db.collection('incidents').doc('call').get())
            .data()!['assignedToUid'],
        incoming.uid,
      );
      expect(find.text('Teslim alındı: Ewa'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'reports opens from home and shows period metrics on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FakeFirebaseFirestore();
      final now = DateTime.now();
      await db.collection('incidents').doc('call').set({
        'schemaVersion': 3,
        'createdByCompanyId': 'factory',
        'machineId': '1A',
        'machineKey': 'Paketleme',
        'openedAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'status': 'resolved',
        'resolvedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 1)),
        ),
      });
      await db.collection('downtime_intervals').doc('interval').set({
        'companyId': 'factory',
        'incidentId': 'call',
        'machineId': '1A',
        'machineKey': 'Paketleme',
        'startAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        'endAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      });
      await tester.pumpWidget(
        MyApp(
          home: HomePage(actor: outgoing, db: db, enableNotifications: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Raporlar'));
      await tester.pumpAndSettle();
      expect(find.text('Raporlar'), findsOneWidget);
      expect(find.text('60.0 dk'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Son 30 gün'));
      await tester.pumpAndSettle();
      expect(find.text('60.0 dk'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
