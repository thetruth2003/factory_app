import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/models/call_alert_tracker.dart';
import 'package:factory_check_app/models/workflow.dart';

const actor = FactoryUser(
  uid: 'op',
  name: 'Operator',
  role: 'operator',
  companyId: 'pilot',
  isTraining: true,
);
CallAlert call(String id, [Map<String, dynamic> changes = const {}]) =>
    CallAlert(id, {
      'createdByCompanyId': 'pilot',
      'environment': 'training',
      'createdByUid': 'watch',
      'targetTeam': 'operator',
      'status': 'open',
      ...changes,
    });

void main() {
  late CallAlertTracker tracker;
  List<CallAlert> consume(
    List<CallAlert> calls, {
    bool cached = false,
    bool pending = false,
    bool foreground = true,
  }) => tracker.consume(
    calls,
    fromCache: cached,
    hasPendingWrites: pending,
    foreground: foreground,
  );
  setUp(() => tracker = CallAlertTracker(actor));

  test('first server snapshot is silent even after stale cache', () {
    expect(consume([call('cached')], cached: true), isEmpty);
    expect(consume([call('old1'), call('old2')]), isEmpty);
    expect(consume([call('old1'), call('old2'), call('new')]).single.id, 'new');
  });
  test('cache and pending writes do not consume a new confirmed call', () {
    consume([]);
    expect(consume([call('new')], cached: true), isEmpty);
    expect(consume([call('new')], pending: true), isEmpty);
    expect(consume([call('new')]).single.id, 'new');
  });
  test(
    'repeated snapshots, edits and deletion/recreation do not repeat alerts',
    () {
      consume([]);
      expect(consume([call('new')]), hasLength(1));
      expect(
        consume([
          call('new', {'description': 'updated'}),
        ]),
        isEmpty,
      );
      consume([]);
      expect(consume([call('new')]), isEmpty);
    },
  );
  test(
    'own, other team, resolved, foreign and non-training calls are silent',
    () {
      consume([]);
      expect(
        consume([
          call('own', {'createdByUid': 'op'}),
          call('other-team', {'targetTeam': 'maintenance'}),
          call('closed', {'status': 'resolved'}),
          call('foreign', {'createdByCompanyId': 'other'}),
          call('live', {'environment': 'production'}),
        ]),
        isEmpty,
      );
    },
  );
  test(
    'background arrivals are consumed silently and not replayed on resume',
    () {
      consume([]);
      expect(consume([call('background')], foreground: false), isEmpty);
      expect(consume([call('background')]), isEmpty);
      expect(consume([call('background'), call('fresh')]).single.id, 'fresh');
    },
  );
  test('batch arrivals are returned together', () {
    consume([]);
    expect(consume([call('a'), call('b')]).map((c) => c.id), ['a', 'b']);
  });
  test('technician receives maintenance, viewer receives nothing', () {
    for (final role in ['technician', 'viewer', 'watcher', 'admin']) {
      tracker = CallAlertTracker(
        FactoryUser(
          uid: 'other',
          name: 'Worker',
          role: role,
          companyId: 'pilot',
        ),
      );
      consume([]);
      expect(
        consume([
          call('a', {'targetTeam': 'maintenance'}),
        ]),
        hasLength(role == 'viewer' ? 0 : 1),
      );
    }
  });
}
