import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/home_page.dart';
import 'package:factory_check_app/screens/login_screen.dart';
import 'package:factory_check_app/services/locale_controller.dart';

const actor = FactoryUser(
  uid: 'op1',
  name: 'Ali',
  role: 'operator',
  companyId: 'factory',
);

void main() {
  setUp(() {
    LocaleController.instance.locale.value = const Locale('tr');
  });
  testWidgets('login fits a small phone without overflowing', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp(home: LoginPage()));
    await tester.pumpAndSettle();
    expect(find.text('Factory Check'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'operator sees, claims and starts a watcher call from the dashboard',
    (tester) async {
      final db = FakeFirebaseFirestore();
      await db.collection('machines').doc('1A').set({
        'companyId': 'factory',
        'name': '1A',
        'section': '1',
        'activeIncidentId': 'call',
        'activeStatus': 'open',
        'reportedState': 'stopped',
      });
      await db.collection('incidents').doc('call').set({
        'machineId': '1A',
        'machineKey': '1A',
        'createdByCompanyId': 'factory',
        'description': 'Paketleme filmi sıkıştı',
        'status': 'open',
        'targetTeam': 'operator',
        'canRun': false,
        'createdAt': Timestamp.now(),
        'openedAt': Timestamp.now(),
        'reportedByName': 'Control',
      });
      await tester.pumpWidget(
        MyApp(
          home: HomePage(actor: actor, db: db, enableNotifications: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Paketleme filmi sıkıştı'), findsOneWidget);
      await tester.tap(find.text('Paketleme filmi sıkıştı'));
      await tester.pumpAndSettle();
      final claim = find.text('Gördüm, üstlen');
      await tester.ensureVisible(claim);
      await tester.tap(claim);
      await tester.pumpAndSettle();
      expect(
        (await db.collection('incidents').doc('call').get())
            .data()!['assignedToUid'],
        actor.uid,
      );
      final start = find.text('Müdahaleye başla');
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(
        (await db.collection('incidents').doc('call').get()).data()!['status'],
        'in_progress',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'machine list includes machines outside the old nine-machine map',
    (tester) async {
      final db = FakeFirebaseFirestore();
      await db.collection('machines').doc('4A').set({
        'companyId': 'factory',
        'name': '4A',
        'section': '4',
      });
      await tester.pumpWidget(
        MyApp(
          home: HomePage(actor: actor, db: db, enableNotifications: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makineler').last);
      await tester.pumpAndSettle();
      expect(find.text('4A'), findsOneWidget);
      expect(find.text('Çalışma durumu doğrulanmadı'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('personal call filter excludes another operators call', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    await db.collection('incidents').doc('call').set({
      'machineId': '1A',
      'machineKey': '1A',
      'createdByCompanyId': 'factory',
      'description': 'Assigned to someone else',
      'status': 'in_progress',
      'assignedToUid': 'op2',
      'assignedToName': 'Ewa',
      'createdAt': Timestamp.now(),
    });
    await tester.pumpWidget(
      MyApp(
        home: HomePage(actor: actor, db: db, enableNotifications: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Assigned to someone else'), findsOneWidget);
    await tester.tap(find.text('Üstlendiğim'));
    await tester.pumpAndSettle();
    expect(find.text('Assigned to someone else'), findsNothing);
    expect(find.text('Aktif çağrı yok'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
