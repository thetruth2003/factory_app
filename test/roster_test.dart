import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/roster.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/roster_page.dart';
import 'package:factory_check_app/services/locale_controller.dart';
import 'package:factory_check_app/services/roster_service.dart';

const admin = FactoryUser(
  uid: 'admin',
  name: 'Admin',
  role: 'admin',
  companyId: 'factory',
);
const op = FactoryUser(
  uid: 'op',
  name: 'Anna',
  role: 'operator',
  companyId: 'factory',
);
const other = FactoryUser(
  uid: 'other',
  name: 'Eva',
  role: 'operator',
  companyId: 'factory',
);
const watcher = FactoryUser(
  uid: 'watch',
  name: 'Watch',
  role: 'watcher',
  companyId: 'factory',
);

void main() {
  late FakeFirebaseFirestore db;
  late RosterService service;
  final day = DateTime.utc(2026, 10, 13);
  var now = DateTime.utc(2026, 10, 13, 8);
  setUp(() async {
    db = FakeFirebaseFirestore();
    now = DateTime.utc(2026, 10, 13, 8);
    service = RosterService(db, now: () => now);
    for (final user in [admin, op, other, watcher]) {
      await db.collection('users').doc(user.uid).set({
        'companyId': user.companyId,
        'role': user.role,
        'displayName': user.name,
      });
    }
    LocaleController.instance.locale.value = const Locale('tr');
  });
  Future<void> plan({
    FactoryUser actor = admin,
    String uid = 'op',
    DateTime? date,
    int start = 360,
    int end = 840,
  }) => service.saveShift(
    actor: actor,
    uid: uid,
    day: date ?? day,
    startMinute: start,
    endMinute: end,
    label: 'Packing',
  );

  test(
    'Poland day/week boundaries ignore device time zone and span new year',
    () {
      expect(
        FactoryCalendar.today(DateTime.utc(2026, 7, 5, 22, 5)),
        DateTime.utc(2026, 7, 6),
      );
      expect(
        FactoryCalendar.today(DateTime.utc(2026, 12, 31, 23, 5)),
        DateTime.utc(2027),
      );
      expect(
        FactoryCalendar.week(DateTime.utc(2027, 1, 1)),
        DateTime.utc(2026, 12, 28),
      );
      expect(FactoryCalendar.canRead(op, day, 'watcher', now: now), isFalse);
      expect(
        FactoryCalendar.canRead(
          op,
          day.add(const Duration(days: 7)),
          'operator',
          now: now,
        ),
        isFalse,
      );
      expect(
        FactoryCalendar.canRead(
          admin,
          DateTime.utc(2020),
          'operator',
          now: now,
        ),
        isTrue,
      );
    },
  );
  test('DST weeks are 167/169 hours and nonexistent time is rejected', () {
    final spring = DateTime.utc(2026, 3, 23),
        autumn = DateTime.utc(2026, 10, 19);
    expect(
      FactoryCalendar.instant(
        spring.add(const Duration(days: 7)),
        0,
      ).difference(FactoryCalendar.instant(spring, 0)).inHours,
      167,
    );
    expect(
      FactoryCalendar.instant(
        autumn.add(const Duration(days: 7)),
        0,
      ).difference(FactoryCalendar.instant(autumn, 0)).inHours,
      169,
    );
    expect(
      () => FactoryCalendar.instant(DateTime.utc(2026, 3, 29), 150),
      throwsA(isA<WorkflowException>()),
    );
    expect(
      FactoryCalendar.instant(DateTime.utc(2026, 10, 25), 150),
      DateTime.utc(2026, 10, 25, 0, 30),
    );
  });
  test(
    'night shifts cross days, overlap is rejected, cancelled shifts free the slot',
    () async {
      await plan(start: 1320, end: 360);
      final ref = service.assignment('factory', day, 'op');
      final data = (await ref.get()).data()!;
      expect(
        (data['endAt'] as Timestamp).toDate().toUtc(),
        DateTime.utc(2026, 10, 14, 4),
      );
      await expectLater(
        plan(date: day.add(const Duration(days: 1)), start: 300),
        throwsA(isA<WorkflowException>()),
      );
      await service.cancelShift(admin, ref);
      await plan(date: day.add(const Duration(days: 1)), start: 300);
    },
  );
  test('overlap checks also cover Sunday to Monday partitions', () async {
    final sunday = DateTime.utc(2026, 10, 18);
    await plan(date: sunday, start: 1320, end: 360);
    await expectLater(
      plan(date: sunday.add(const Duration(days: 1)), start: 240),
      throwsA(isA<WorkflowException>()),
    );
  });
  test(
    'only admin schedules; inactive/foreign employees and invalid lengths fail',
    () async {
      await expectLater(plan(actor: op), throwsA(isA<WorkflowException>()));
      await db.collection('users').doc('op').update({'isActive': false});
      await expectLater(plan(), throwsA(isA<WorkflowException>()));
      await db.collection('users').doc('op').update({
        'isActive': true,
        'companyId': 'foreign',
      });
      await expectLater(plan(), throwsA(isA<WorkflowException>()));
      await expectLater(
        plan(uid: 'other', start: 360, end: 350),
        throwsA(isA<WorkflowException>()),
      );
      await expectLater(
        plan(uid: 'other', start: 360, end: 360),
        throwsA(isA<WorkflowException>()),
      );
    },
  );
  test('report ownership, timing, retry safety and schedule locking', () async {
    await plan();
    final ref = service.assignment('factory', day, op.uid);
    Future<void> report(FactoryUser actor, String summary) =>
        service.saveReport(
          actor: actor,
          shift: ref,
          summary: summary,
          problems: 'Film jam',
          followUp: 'Check conveyor',
        );
    await expectLater(report(other, 'Fake'), throwsA(isA<WorkflowException>()));
    now = DateTime.utc(2026, 10, 13, 2);
    await expectLater(report(op, 'Early'), throwsA(isA<WorkflowException>()));
    now = DateTime.utc(2026, 10, 13, 12);
    await report(op, 'Complete');
    await report(op, 'Retry');
    expect(
      (await ref.collection('reports').doc('end').get()).data()!['summary'],
      'Complete',
    );
    await expectLater(plan(), throwsA(isA<WorkflowException>()));
    await expectLater(
      service.cancelShift(admin, ref),
      throwsA(isA<WorkflowException>()),
    );
  });
  test(
    'notes target only own team today/tomorrow; read receipts are separate and idempotent',
    () async {
      Future<void> note({
        String team = 'operator',
        DateTime? target,
        String text = 'Check roll',
      }) => service.leaveNote(
        actor: op,
        id: 'note',
        day: target ?? day.add(const Duration(days: 1)),
        team: team,
        body: text,
        important: true,
      );
      await expectLater(
        note(team: 'watcher'),
        throwsA(isA<WorkflowException>()),
      );
      await expectLater(
        note(target: day.add(const Duration(days: 2))),
        throwsA(isA<WorkflowException>()),
      );
      await note();
      await note(text: 'Retry');
      final ref = service.notes('factory').doc('note');
      expect((await ref.get()).data()!['body'], 'Check roll');
      await service.markRead(other, ref);
      await service.markRead(other, ref);
      expect((await ref.collection('reads').get()).docs.length, 1);
      expect((await ref.collection('reads').doc('op').get()).exists, isFalse);
      expect(
        (await service.dayNotes(op, day.add(const Duration(days: 1))).get())
            .docs
            .length,
        1,
      );
      expect(
        (await service
                .dayNotes(watcher, day.add(const Duration(days: 1)))
                .get())
            .docs,
        isEmpty,
      );
    },
  );
  testWidgets('worker calendar hides admin controls and other teams', (
    tester,
  ) async {
    final today = FactoryCalendar.today();
    await plan(date: today);
    await plan(date: today, uid: 'watch');
    await tester.pumpWidget(
      MyApp(
        home: RosterPage(actor: op, db: db),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Anna · Packing'), findsOneWidget);
    expect(find.text('Watch · Packing'), findsNothing);
    expect(find.text('Vardiya planla'), findsNothing);
    expect(find.text('Tarih seç'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  for (final lang in ['tr', 'en', 'pl']) {
    testWidgets('admin calendar and shift form fit a small phone in $lang', (
      tester,
    ) async {
      LocaleController.instance.locale.value = Locale(lang);
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MyApp(
          home: RosterPage(actor: admin, db: db),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets(
    'important note is shown and receipt persists after acknowledgement',
    (tester) async {
      final target = FactoryCalendar.today();
      await RosterService(db).leaveNote(
        actor: op,
        id: 'note',
        day: target,
        team: 'operator',
        body: 'Check conveyor before restart',
        important: true,
      );
      await tester.pumpWidget(
        MyApp(
          home: Scaffold(
            body: TeamNotesPanel(actor: other, db: db, day: target),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Check conveyor before restart'), findsOneWidget);
      await tester.tap(find.text('Okudum'));
      await tester.pumpAndSettle();
      expect(find.text('✓ Okundu'), findsOneWidget);
      expect(
        (await service
                .notes('factory')
                .doc('note')
                .collection('reads')
                .doc(other.uid)
                .get())
            .exists,
        isTrue,
      );
    },
  );
}
