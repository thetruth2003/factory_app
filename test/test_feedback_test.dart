import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/home_page.dart';
import 'package:factory_check_app/screens/test_feedback_page.dart';
import 'package:factory_check_app/services/locale_controller.dart';
import 'package:factory_check_app/services/test_feedback_service.dart';

const actor = FactoryUser(
  uid: 'op',
  name: 'Operatör',
  role: 'operator',
  companyId: 'pilot',
  isTraining: true,
);

void main() {
  late FakeFirebaseFirestore db;
  late TestFeedbackService service;
  setUp(() {
    db = FakeFirebaseFirestore();
    service = TestFeedbackService(db);
    LocaleController.instance.locale.value = const Locale('tr');
  });
  Future<void> submit({
    FactoryUser user = actor,
    String notes = 'Düğme küçük',
    int ease = 3,
  }) => service.submit(
    id: 'form',
    actor: user,
    ease: ease,
    notes: notes,
    locale: 'tr',
  );

  test(
    'feedback is attributed and retry cannot duplicate or overwrite it',
    () async {
      await submit(notes: '  Düğme küçük  ');
      await submit(notes: 'Changed retry');
      final result = await service.records('pilot').get();
      expect(result.size, 1);
      final data = result.docs.single.data();
      expect(data['notes'], 'Düğme küçük');
      expect(data['createdByUid'], 'op');
      expect(data['createdByRole'], 'operator');
      expect(data['environment'], 'training');
      expect(data['ease'], 3);
      expect(data['createdAt'], isNotNull);
      expect((await service.records('live').get()).size, 0);
    },
  );
  test(
    'normal accounts, invalid ratings and empty or overlong notes are rejected',
    () async {
      const live = FactoryUser(
        uid: 'op',
        name: 'Operator',
        role: 'operator',
        companyId: 'pilot',
      );
      await expectLater(submit(user: live), throwsA(isA<WorkflowException>()));
      await expectLater(submit(notes: '  '), throwsA(isA<WorkflowException>()));
      await expectLater(
        submit(notes: 'x' * 2001),
        throwsA(isA<WorkflowException>()),
      );
      await expectLater(submit(ease: 0), throwsA(isA<WorkflowException>()));
      await expectLater(submit(ease: 6), throwsA(isA<WorkflowException>()));
      expect((await service.records('pilot').get()).size, 0);
    },
  );
  test('another actor cannot reuse an existing feedback ID', () async {
    await submit();
    const other = FactoryUser(
      uid: 'watch',
      name: 'Watcher',
      role: 'watcher',
      companyId: 'pilot',
      isTraining: true,
    );
    await expectLater(submit(user: other), throwsA(isA<WorkflowException>()));
    expect(
      (await service.records('pilot').get()).docs.single['createdByUid'],
      'op',
    );
  });
  testWidgets(
    'training user can validate, submit and return home on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MyApp(
          home: HomePage(actor: actor, db: db, enableNotifications: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Test geri bildirimi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test geri bildirimi'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Geri bildirimi kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Geri bildirimi kaydet'));
      await tester.pumpAndSettle();
      expect(find.text('Lütfen bu alanı doldurun.'), findsNWidgets(2));
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 / 5').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Çağrı açmak kolaydı.',
      );
      await tester.ensureVisible(find.text('Geri bildirimi kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Geri bildirimi kaydet'));
      await tester.pumpAndSettle();
      expect(find.byType(TestFeedbackPage), findsNothing);
      expect(find.text('Geri bildiriminiz kaydedildi.'), findsOneWidget);
      final records = await service.records('pilot').get();
      expect(records.docs.single['ease'], 4);
      expect(records.docs.single['notes'], 'Çağrı açmak kolaydı.');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('new remote call is visible once and its action opens the call', (
    tester,
  ) async {
    final data = {
      'createdByCompanyId': 'pilot',
      'environment': 'training',
      'createdByUid': 'watch',
      'targetTeam': 'operator',
      'status': 'open',
      'machineKey': 'TEST-1',
      'machineId': 'test1',
      'description': 'Film sıkıştı',
      'canRun': false,
    };
    await db.collection('incidents').doc('old').set(data);
    await tester.pumpWidget(
      MyApp(
        home: HomePage(actor: actor, db: db, enableNotifications: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yeni çağrı: TEST-1'), findsNothing);
    await db.collection('incidents').doc('new').set(data);
    await tester.pumpAndSettle();
    expect(find.text('Yeni çağrı: TEST-1'), findsOneWidget);
    await tester.tap(find.text('Çağrıyı aç'));
    await tester.pumpAndSettle();
    expect(find.text('Film sıkıştı'), findsWidgets);
    expect(find.text('Yeni çağrı: TEST-1'), findsNothing);
    await db.collection('incidents').doc('new').update({
      'description': 'Not eklendi',
    });
    await tester.pumpAndSettle();
    expect(find.text('Yeni çağrı: TEST-1'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
