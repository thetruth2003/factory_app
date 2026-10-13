import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../ui/call_widgets.dart';

class IncidentTimeline extends StatelessWidget {
  const IncidentTimeline({super.key, required this.events});
  final Stream<QuerySnapshot<Map<String, dynamic>>> events;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: events,
      builder: (context, snap) {
        if (snap.hasError) return Text(errorLabel(t, snap.error!));
        if (!snap.hasData) return const LinearProgressIndicator();
        if (snap.data!.docs.isEmpty) return EmptyState(message: t.noActivity);
        return Column(
          children: snap.data!.docs.map((doc) {
            final data = doc.data();
            final type = (data['type'] ?? '').toString();
            final title = switch (type) {
              'created' => t.createdEvent,
              'note_added' => t.noteEvent,
              'photo_added' => t.photoEvent,
              'production_stopped' => t.productionStopped,
              'production_resumed' => t.productionResume,
              'handover_received' => t.handoverEvent,
              _ => t.changedEvent,
            };
            final from = data['fromStatus'];
            final to = data['toStatus'];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${dateLabel(data['at'])} · ${data['byName'] ?? ''}'),
                    if (to != null)
                      Text(
                        (from == null
                                ? ''
                                : '${statusLabel(t, from.toString())} → ') +
                            statusLabel(t, to.toString()),
                      ),
                    if ((data['message'] ?? '').toString().isNotEmpty &&
                        type != 'photo_added')
                      Text(data['message'].toString()),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
