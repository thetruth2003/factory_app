// Reproducible UI previews with local fixtures, never live factory records.
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/main.dart';
import 'package:factory_check_app/models/roster.dart';
import 'package:factory_check_app/models/workflow.dart';
import 'package:factory_check_app/screens/roster_page.dart';
import 'package:factory_check_app/services/locale_controller.dart';
import 'package:factory_check_app/services/roster_service.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final font = FontLoader('Roboto');
      for (final weight in ['regular', 'bold']) {
        final file = File(
          '$root/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
        );
        if (file.existsSync()) {
          font.addFont(
            Future.value(ByteData.sublistView(file.readAsBytesSync())),
          );
        }
      }
      await font.load();
    }
  });
  testWidgets('calendar, reports and notes previews', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LocaleController.instance.locale.value = const Locale('tr');
    final db = FakeFirebaseFirestore(), today = FactoryCalendar.today();
    const admin = FactoryUser(
      uid: 'admin',
      name: 'Yönetici',
      role: 'admin',
      companyId: 'demo',
    );
    const op = FactoryUser(
      uid: 'op',
      name: 'Anna Kowalska',
      role: 'operator',
      companyId: 'demo',
    );
    const next = FactoryUser(
      uid: 'next',
      name: 'Marek Nowak',
      role: 'operator',
      companyId: 'demo',
    );
    for (final actor in [admin, op, next]) {
      await db.collection('users').doc(actor.uid).set({
        'displayName': actor.name,
        'role': actor.role,
        'companyId': actor.companyId,
      });
    }
    final service = RosterService(db);
    for (final (actor, day, start, end) in [
      (op, today, 360, 840),
      (next, today, 840, 1320),
      (next, today.add(const Duration(days: 1)), 360, 840),
    ]) {
      await service.saveShift(
        actor: admin,
        uid: actor.uid,
        day: day,
        startMinute: start,
        endMinute: end,
        label: start == 360 ? 'Sabah vardiyası' : 'Akşam vardiyası',
      );
    }
    final ref = service.assignment('demo', today, op.uid);
    await ref.collection('reports').doc('end').set({
      'createdByUid': op.uid,
      'createdByName': op.name,
      'createdAt': Timestamp.now(),
      'summary':
          'Paketleme hattı vardiya sonunda çalışır durumda teslim edildi.',
      'problems':
          'Paketleme 1: film sıkışması giderildi. İlk ürün kontrolü tamamlandı.',
      'followUp': 'Yeni film rulosunun hizasını başlangıçta kontrol edin.',
    });
    await service.leaveNote(
      actor: op,
      id: 'note',
      day: today,
      team: 'operator',
      body:
          'Paketleme 1: yeni film rulosunun hizasını ilk çalıştırmada kontrol edin.',
      important: true,
    );
    for (final (name, screen) in <(String, Widget)>[
      ('roster-admin', RosterPage(actor: admin, db: db)),
      ('roster-worker', RosterPage(actor: op, db: db)),
      ('roster-report', ShiftDetailPage(actor: admin, db: db, reference: ref)),
      (
        'roster-alert',
        Scaffold(
          appBar: AppBar(title: const Text('Vardiya başlangıcı')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TeamNotesPanel(actor: next, db: db, day: today),
          ),
        ),
      ),
    ]) {
      await tester.pumpWidget(MyApp(key: ValueKey(name), home: screen));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('../build/verification/$name.png'),
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
