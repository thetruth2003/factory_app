class WorkflowException implements Exception {
  const WorkflowException(this.code);
  final String code;
  @override
  String toString() => code;
}

class FactoryUser {
  const FactoryUser({
    required this.uid,
    required this.name,
    required this.role,
    required this.companyId,
    this.isTraining = false,
  });
  final String uid;
  final String name;
  final String role;
  final String companyId;
  final bool isTraining;
  bool get canReport => const {
    'operator',
    'watcher',
    'quality',
    'warehouse',
    'maintenance',
    'technician',
    'supervisor',
    'admin',
  }.contains(role);
  bool get canManage => const {
    'operator',
    'quality',
    'warehouse',
    'maintenance',
    'technician',
    'supervisor',
    'admin',
  }.contains(role);
  bool get canSupervise => role == 'supervisor' || role == 'admin';

  static FactoryUser fromProfile({
    required String uid,
    required String email,
    required Map<String, dynamic> profile,
  }) {
    final explicitCompany = (profile['companyId'] ?? '').toString().trim();
    final legacyCompany = email.endsWith('@company.local')
        ? email.split('@').first
        : '';
    final company = explicitCompany.isNotEmpty
        ? explicitCompany
        : legacyCompany;
    if (company.isEmpty) throw const WorkflowException('profile');
    final name = (profile['displayName'] ?? profile['name'] ?? '')
        .toString()
        .trim();
    return FactoryUser(
      uid: uid,
      name: name.isEmpty ? email.split('@').first : name,
      role: (profile['role'] ?? 'viewer').toString().trim().toLowerCase(),
      companyId: company,
      isTraining: profile['environment'] == 'training',
    );
  }
}

/// Business rules shared by the interface and transactional writes.
abstract final class Workflow {
  static const activeStatuses = {
    'open',
    'acknowledged',
    'in_progress',
    'waiting',
    'stop_required',
    'need_technician',
  };
  static const teams = ['operator', 'maintenance', 'quality', 'warehouse'];
  static const kinds = ['fault', 'quality', 'material', 'support'];
  static bool isActive(String status) => activeStatuses.contains(status);
  static void validateActor(FactoryUser actor, {bool manage = false}) {
    if (actor.uid.isEmpty ||
        actor.companyId.isEmpty ||
        !(manage ? actor.canManage : actor.canReport)) {
      throw const WorkflowException('forbidden');
    }
  }

  static void validateTime(DateTime value, {DateTime? after, DateTime? now}) {
    if (value.isAfter(
          (now ?? DateTime.now()).add(const Duration(minutes: 1)),
        ) ||
        (after != null && value.isBefore(after))) {
      throw const WorkflowException('invalidTime');
    }
  }

  static void validateOwnership({
    required FactoryUser actor,
    required String assignedUid,
  }) {
    validateActor(actor, manage: true);
    if (assignedUid.isNotEmpty &&
        assignedUid != actor.uid &&
        !actor.canSupervise) {
      throw const WorkflowException('assignedElsewhere');
    }
  }

  static void validateTransition(String from, String to) {
    final allowed = switch (from) {
      'open' => {'acknowledged'},
      'acknowledged' => {'in_progress', 'waiting'},
      'in_progress' => {'waiting', 'resolved'},
      'waiting' || 'stop_required' || 'need_technician' => {'in_progress'},
      _ => <String>{},
    };
    if (!allowed.contains(to)) {
      throw const WorkflowException('invalidTransition');
    }
  }

  static void validateResolution({
    required bool machineRunning,
    required bool needsTeam,
    required String notes,
  }) {
    if (!machineRunning || needsTeam) {
      throw const WorkflowException('notRunning');
    }
    if (notes.trim().isEmpty) throw const WorkflowException('noteRequired');
  }
}
