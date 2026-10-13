import 'workflow.dart';

class CallAlert {
  const CallAlert(this.id, this.data);
  final String id;
  final Map<String, dynamic> data;
}

/// The first confirmed snapshot is a baseline, not a batch of new calls.
class CallAlertTracker {
  CallAlertTracker(this.actor);
  final FactoryUser actor;
  final Set<String> _seen = {};
  bool _initialized = false;

  List<CallAlert> consume(
    Iterable<CallAlert> calls, {
    required bool fromCache,
    required bool hasPendingWrites,
    bool foreground = true,
  }) {
    if (fromCache || hasPendingWrites) return [];
    final incoming = <CallAlert>[];
    for (final call in calls) {
      final isNew = _seen.add(call.id);
      if (_initialized && foreground && isNew && _relevant(call.data)) {
        incoming.add(call);
      }
    }
    _initialized = true;
    return incoming;
  }

  bool _relevant(Map<String, dynamic> data) {
    if (!actor.canReport ||
        data['createdByCompanyId'] != actor.companyId ||
        data['createdByUid'] == actor.uid ||
        data['status'] != 'open' ||
        (actor.isTraining && data['environment'] != 'training')) {
      return false;
    }
    final team = actor.role == 'technician' ? 'maintenance' : actor.role;
    return actor.canSupervise ||
        actor.role == 'watcher' ||
        (data['targetTeam'] ?? 'maintenance') == team;
  }
}
