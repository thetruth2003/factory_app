import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/roster.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/home_page.dart';
import 'package:factory_check_app/screens/roster_page.dart';
import 'package:factory_check_app/services/locale_controller.dart';
import 'package:factory_check_app/services/roster_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android: plan, report, important note, receipt and role boundaries',
    (tester) async {
      // The named app and hard-coded demo project cannot use production data.
      final app = await Firebase.initializeApp(
        name: 'roster-emulator-test',
        options: const FirebaseOptions(
          apiKey: 'emulator-only',
          appId: '1:123456789:android:abcdef123456',
          messagingSenderId: '123456789',
          projectId: 'demo-factory-check',
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator(
        '127.0.0.1',
        9099,
        automaticHostMapping: false,
      );
      final db = FirebaseFirestore.instanceFor(app: app);
      db.settings = const Settings(persistenceEnabled: false);
      db.useFirestoreEmulator('127.0.0.1', 8180, automaticHostMapping: false);
      final service = RosterService(db), day = FactoryCalendar.today();
      LocaleController.instance.locale.value = const Locale('tr');
      Future<FactoryUser> login(String id) async {
        await tester.pumpWidget(const SizedBox.shrink());
        await auth.signOut();
        final credential = await auth.signInWithEmailAndPassword(
          email: '$id@roster.test',
          password: 'local-emulator-only',
        );
        final user = credential.user!;
        final profile = await db
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));
        return FactoryUser.fromProfile(
          uid: user.uid,
          email: user.email!,
          profile: profile.data()!,
        );
      }

      Future<void> visible(Finder finder) async {
        for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(finder, findsWidgets);
        await tester.ensureVisible(finder.first);
        await tester.pumpAndSettle();
      }

      Future<void> tapText(String value) async {
        final finder = find.text(value);
        await visible(finder);
        await tester.tap(finder.first);
        await tester.pumpAndSettle();
      }

      Future<void> showRoster(FactoryUser actor) async {
        await tester.pumpWidget(
          MyApp(
            key: ValueKey(actor.uid),
            home: RosterPage(actor: actor, db: db),
          ),
        );
        await tester.pumpAndSettle();
      }

      final first = await login('operator1'), second = await login('operator2');
      final admin = await login('admin');
      final employees = await db
          .collection('users')
          .where('companyId', isEqualTo: admin.companyId)
          .get(const GetOptions(source: Source.server));
      expect(employees.docs.length, 4);
      final local = FactoryCalendar.local(DateTime.now());
      final start = local.hour > 0 ? (local.hour - 1) * 60 : 0;
      for (final worker in [first, second]) {
        await service.saveShift(
          actor: admin,
          uid: worker.uid,
          day: day,
          startMinute: start,
          endMinute: (start + 480) % 1440,
          label: 'Android test',
        );
      }
      await showRoster(admin);
      await visible(find.text('Test Operator 1 · Android test'));
      expect(find.text('Vardiya planla'), findsOneWidget);
      expect(find.text('Tarih seç'), findsOneWidget);

      final operator = await login('operator1');
      await expectLater(
        db
            .collection('users')
            .where('companyId', isEqualTo: operator.companyId)
            .get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await expectLater(
        service
            .shifts(operator.companyId, day.add(const Duration(days: 7)))
            .where('team', isEqualTo: 'operator')
            .get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      await showRoster(operator);
      await visible(find.text('Test Operator 1 · Android test'));
      expect(find.text('Vardiya planla'), findsNothing);
      expect(find.text('Tarih seç'), findsNothing);
      await tapText('Test Operator 1 · Android test');
      await tapText('Gün sonu raporu yaz');
      await tester.enterText(
        find.byType(TextField).at(0),
        'Android vardiya kontrolü tamamlandı.',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'Film sıkışması giderildi.',
      );
      await tester.enterText(
        find.byType(TextField).at(2),
        'Yeni ruloyu kontrol edin.',
      );
      await tapText('Kaydet');
      await visible(find.text('Android vardiya kontrolü tamamlandı.'));
      final shift = service.assignment(operator.companyId, day, operator.uid);
      expect(
        (await shift
                .collection('reports')
                .doc('end')
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );
      await tapText('Devir notu bırak');
      await tapText('Bugün');
      await tester.enterText(
        find.byType(TextField),
        'ANDROID TEST: İlk ürünü kontrol edin.',
      );
      await tester.tap(find.byType(SwitchListTile));
      await tapText('Kaydet');
      await visible(find.text('Android vardiya kontrolü tamamlandı.'));
      final notes = await service
          .dayNotes(operator, day)
          .get(const GetOptions(source: Source.server));
      expect(notes.docs.length, 1);
      expect(notes.docs.single.data()['important'], isTrue);

      final receiver = await login('operator2');
      await tester.pumpWidget(
        MyApp(
          key: ValueKey(receiver.uid),
          home: HomePage(actor: receiver, db: db, enableNotifications: false),
        ),
      );
      await visible(find.text('ANDROID TEST: İlk ürünü kontrol edin.'));
      await tapText('Okudum');
      await visible(find.text('✓ Okundu'));
      expect(
        (await notes.docs.single.reference
                .collection('reads')
                .doc(receiver.uid)
                .get(const GetOptions(source: Source.server)))
            .exists,
        isTrue,
      );

      final watcher = await login('watcher');
      expect(
        (await service
                .roster(watcher, day)
                .get(const GetOptions(source: Source.server)))
            .docs,
        isEmpty,
      );
      await expectLater(
        shift.get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );
      final outsider = await login('outsider');
      expect(outsider.companyId, isNot(admin.companyId));
      await expectLater(
        shift.get(const GetOptions(source: Source.server)),
        throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        ),
      );

      final manager = await login('admin');
      await showRoster(manager);
      await tapText('Test Operator 1 · Android test');
      await visible(find.text('Android vardiya kontrolü tamamlandı.'));
      expect(find.text('Vardiyayı düzenle'), findsNothing);
      expect(
        (await notes.docs.single.reference
                .collection('reads')
                .get(const GetOptions(source: Source.server)))
            .docs
            .single
            .id,
        receiver.uid,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await auth.signOut();
      await db.terminate();
      await app.delete();
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
