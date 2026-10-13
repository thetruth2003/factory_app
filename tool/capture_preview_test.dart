// Renders the real dashboard with local fake data, without accessing Firebase.
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/home_page.dart';
import 'package:factory_check_app/services/locale_controller.dart';

void main() {
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final loader = FontLoader('Roboto');
      for (final weight in ['regular', 'bold']) {
        final file = File(
          '$root/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
        );
        if (file.existsSync()) {
          loader.addFont(
            Future.value(ByteData.sublistView(file.readAsBytesSync())),
          );
        }
      }
      await loader.load();
    }
  });
  for (final wide in [false, true]) {
    testWidgets(wide ? 'wide dashboard preview' : 'phone dashboard preview', (
      tester,
    ) async {
      debugDisableShadows = false;
      tester.view.physicalSize = wide
          ? const Size(1280, 800)
          : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      LocaleController.instance.locale.value = const Locale('tr');
      final db = FakeFirebaseFirestore();
      final now = DateTime.now();
      for (var i = 0; i < 3; i++) {
        final machine = ['Paketleme 1', 'Pişirme 2', 'Soğutma 3'][i];
        await db.collection('machines').doc('m$i').set({
          'companyId': 'demo',
          'name': machine,
          'section': '1',
          'activeIncidentId': 'c$i',
          'activeStatus': ['open', 'in_progress', 'waiting'][i],
          'reportedState': i == 0 ? 'stopped' : 'running',
        });
        await db.collection('incidents').doc('c$i').set({
          'schemaVersion': 3,
          'machineId': 'm$i',
          'machineKey': machine,
          'createdByCompanyId': 'demo',
          'status': ['open', 'in_progress', 'waiting'][i],
          'description': [
            'Paketleme filmi sıkıştı. Operatör kontrolü gerekiyor.',
            'Ürün görünümü kontrol ediliyor.',
            'Sonraki vardiya için malzeme desteği gerekiyor.',
          ][i],
          'targetTeam': ['operator', 'quality', 'warehouse'][i],
          'canRun': i != 0,
          'assignedToUid': i == 1 ? 'op1' : null,
          'assignedToName': i == 1 ? 'Ali' : null,
          'createdAt': Timestamp.fromDate(
            now.subtract(Duration(minutes: i * 10)),
          ),
          'openedAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(minutes: 8 + i * 5)),
          ),
          'ackAt': i == 0
              ? null
              : Timestamp.fromDate(now.subtract(Duration(minutes: 4 + i * 5))),
        });
        await db.collection('downtime_intervals').doc('d$i').set({
          'companyId': 'demo',
          'incidentId': 'c$i',
          'machineId': 'm$i',
          'machineKey': machine,
          'startAt': Timestamp.fromDate(
            now.subtract(Duration(minutes: 20 + i * 15)),
          ),
          'endAt': i == 0
              ? null
              : Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
        });
      }
      await db
          .collection('companies')
          .doc('demo')
          .collection('handovers')
          .doc('h1')
          .set({
            'companyId': 'demo',
            'shift': 'Gece vardiyası · 22:00–06:00',
            'team': 'operator',
            'createdByUid': 'op0',
            'createdByName': 'Mehmet',
            'createdAt': Timestamp.fromDate(now),
            'status': 'pending',
            'notes':
                'Paketleme 1 için yeni film rulosu bekleniyor. Sabah ekibi ilk ürünü kontrol etsin.',
            'calls': [],
          });
      await db
          .collection('companies')
          .doc('demo')
          .collection('handovers')
          .doc('h2')
          .set({
            'companyId': 'demo',
            'shift': 'Akşam vardiyası · 14:00–22:00',
            'team': 'maintenance',
            'createdByUid': 'tech0',
            'createdByName': 'Jan',
            'createdAt': Timestamp.fromDate(
              now.subtract(const Duration(hours: 8)),
            ),
            'status': 'accepted',
            'acceptedByName': 'Ewa',
            'notes':
                'Soğutma hattının kontrolü tamamlandı. Açık bakım işi yok.',
            'calls': [],
          });
      await tester.pumpWidget(
        MyApp(
          home: HomePage(
            actor: const FactoryUser(
              uid: 'op1',
              name: 'Ali',
              role: 'operator',
              companyId: 'demo',
            ),
            db: db,
            enableNotifications: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile(
          wide
              ? '../build/verification/dashboard-wide.png'
              : '../build/verification/dashboard-phone.png',
        ),
      );
      await tester.tap(find.byIcon(Icons.swap_horiz).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile(
          wide
              ? '../build/verification/handover-wide.png'
              : '../build/verification/handover-phone.png',
        ),
      );
      await tester.tap(find.byTooltip('Raporlar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).last,
        matchesGoldenFile(
          wide
              ? '../build/verification/reports-wide.png'
              : '../build/verification/reports-phone.png',
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await db.collection('machines').doc('training').set({
        'name': 'TEST-1 · Paketleme',
        'companyId': 'pilot',
        'environment': 'training',
      });
      await tester.pumpWidget(
        MyApp(
          home: HomePage(
            actor: const FactoryUser(
              uid: 'watch',
              name: 'Test İzleme',
              role: 'watcher',
              companyId: 'pilot',
              isTraining: true,
            ),
            db: db,
            enableNotifications: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile(
          wide
              ? '../build/verification/field-test-wide.png'
              : '../build/verification/field-test-phone.png',
        ),
      );
      await tester.ensureVisible(find.text('Test geri bildirimi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test geri bildirimi'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).last,
        matchesGoldenFile(
          wide
              ? '../build/verification/feedback-wide.png'
              : '../build/verification/feedback-phone.png',
        ),
      );
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
