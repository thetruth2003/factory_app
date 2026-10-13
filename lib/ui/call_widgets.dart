import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/workflow.dart';

class SessionTitle extends StatelessWidget {
  const SessionTitle({super.key, required this.title, required this.actor});
  final String title;
  final FactoryUser actor;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      if (actor.isTraining)
        Text(
          AppLocalizations.of(context).trainingMode,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF805500),
            fontWeight: FontWeight.bold,
          ),
        ),
    ],
  );
}

String statusLabel(AppLocalizations t, String value) => switch (value) {
  'open' => t.statusOpen,
  'acknowledged' => t.statusAcknowledged,
  'in_progress' => t.statusInProgress,
  'waiting' => t.statusWaiting,
  'resolved' => t.statusResolved,
  'stop_required' => t.statusStopRequired,
  'need_technician' => t.statusNeedTechnician,
  _ => value,
};
String teamLabel(AppLocalizations t, String value) => switch (value) {
  'operator' => t.teamOperator,
  'maintenance' || 'technician' => t.teamMaintenance,
  'quality' => t.teamQuality,
  'warehouse' => t.teamWarehouse,
  'watcher' => t.roleWatcher,
  'supervisor' => t.roleSupervisor,
  'admin' => t.roleAdmin,
  _ => t.roleViewer,
};
String kindLabel(AppLocalizations t, String value) => switch (value) {
  'quality' => t.kindQuality,
  'material' => t.kindMaterial,
  'support' => t.kindSupport,
  _ => t.kindFault,
};
DateTime? dateValue(dynamic value) =>
    value is Timestamp ? value.toDate() : null;
String dateLabel(dynamic value) {
  final date = dateValue(value);
  return date == null ? '—' : DateFormat('dd.MM.yyyy HH:mm').format(date);
}

String durationLabel(AppLocalizations t, dynamic start, {dynamic end}) {
  final date = dateValue(start);
  if (date == null) return '—';
  final minutes = (dateValue(end) ?? DateTime.now()).difference(date).inMinutes;
  return '${minutes < 0 ? 0 : minutes} ${t.minutes}';
}

String errorLabel(AppLocalizations t, Object error) {
  if (error is WorkflowException) {
    return switch (error.code) {
      'forbidden' => t.errorForbidden,
      'assignedElsewhere' => t.errorAssigned,
      'staleCall' => t.errorStale,
      'invalidTransition' => t.errorTransition,
      'invalidTime' => t.errorTime,
      'noteRequired' => t.errorNote,
      'invalidFeedback' => t.feedbackRequired,
      'notRunning' => t.errorRunning,
      'notFound' => t.notFound,
      'profile' => t.sessionError,
      'invalidHandover' => t.errorHandover,
      'handoverChanged' => t.errorHandoverChanged,
      'handoverAccepted' => t.errorHandoverAccepted,
      'handoverSelf' => t.errorHandoverSelf,
      'handoverTeam' => t.handoverTeamOnly,
      _ => t.onlineRequired,
    };
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return t.errorForbidden;
  }
  return t.onlineRequired;
}

String reasonLabel(AppLocalizations t, String code) => switch (code) {
  'machine_stopped' => t.reasonMachineStopped,
  'material_jam' => t.reasonMaterialJam,
  'machine_alarm' => t.reasonMachineAlarm,
  'shape_size' => t.reasonShapeSize,
  'baking_colour' => t.reasonBakingColour,
  'packaging_seal' => t.reasonPackagingSeal,
  'material_empty' => t.reasonMaterialEmpty,
  'packaging_empty' => t.reasonPackagingEmpty,
  'operator_help' => t.reasonOperatorHelp,
  'technical_check' => t.reasonTechnicalCheck,
  _ => code,
};

void showFailure(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorLabel(AppLocalizations.of(context), error))),
    );

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'resolved' => Colors.teal,
      'in_progress' => Colors.blue,
      'acknowledged' => Colors.indigo,
      'open' => Colors.deepOrange,
      _ => Colors.brown,
    };
    return Chip(
      avatar: Icon(
        status == 'resolved' ? Icons.check_circle : Icons.circle,
        color: color,
        size: 15,
      ),
      label: Text(statusLabel(AppLocalizations.of(context), status)),
      backgroundColor: color.withValues(alpha: .08),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

class CallCard extends StatelessWidget {
  const CallCard({super.key, required this.data, required this.onTap});
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final status = (data['status'] ?? 'open').toString();
    final stopped = data['canRun'] == false && status != 'resolved';
    final assigned = (data['assignedToName'] ?? '').toString();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: stopped
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFE0F2F1),
                    child: Icon(
                      stopped
                          ? Icons.pause_circle_outline
                          : Icons.precision_manufacturing_outlined,
                      color: stopped
                          ? Colors.red.shade700
                          : Colors.teal.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (data['machineKey'] ?? data['machineId'] ?? '')
                          .toString(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(status: status),
                  if (stopped)
                    Text(
                      t.productionStopped,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (data['description'] ?? '').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                '${t.assignedTo}: ${assigned.isEmpty ? t.unassigned : assigned}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '${teamLabel(t, (data['targetTeam'] ?? 'maintenance').toString())} · ${t.elapsed}: ${durationLabel(t, data['openedAt'] ?? data['createdAt'], end: data['resolvedAt'])}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Column(
      children: [
        Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class CacheNotice extends StatelessWidget {
  const CacheNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: Text(AppLocalizations.of(context).cachedData),
  );
}
