import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(dynamic value) => value is Timestamp ? value.toDate() : null;

class MachineReport {
  MachineReport(this.id, this.name);
  final String id;
  final String name;
  int opened = 0;
  int resolved = 0;
  int downtimeSeconds = 0;
}

/// Calendar range [start, end), clipped at now, in the device's local timezone.
/// Counts calls by their own timestamps; downtime by interval overlap, not age.
class PeriodReport {
  PeriodReport({
    required Map<String, Map<String, dynamic>> calls,
    required Iterable<Map<String, dynamic>> intervals,
    required DateTime start,
    required DateTime end,
    required DateTime now,
  }) {
    final until = end.isBefore(now) ? end : now;
    if (!start.isBefore(until)) return;
    bool inside(DateTime? date) =>
        date != null && !date.isBefore(start) && date.isBefore(until);
    final rows = <String, MachineReport>{};
    MachineReport row(Map<String, dynamic> data) {
      final id = (data['machineId'] ?? '').toString();
      return rows.putIfAbsent(
        id,
        () => MachineReport(id, (data['machineKey'] ?? id).toString()),
      );
    }

    var responseTotal = 0;
    for (final entry in calls.entries) {
      final data = entry.value;
      final openedAt = _date(
        data['openedAt'] ?? data['reportedAt'] ?? data['createdAt'],
      );
      final resolvedAt = _date(data['resolvedAt']);
      if (inside(openedAt)) {
        opened++;
        row(data).opened++;
        final ack = _date(data['ackAt']);
        if (ack != null && !ack.isBefore(openedAt!) && !ack.isAfter(now)) {
          responseTotal += ack.difference(openedAt).inSeconds;
          responseSamples++;
        }
      }
      if (inside(resolvedAt)) {
        resolved++;
        row(data).resolved++;
      }
      // Incomplete legacy history must never silently appear to be zero loss.
      if ((data['schemaVersion'] as num? ?? 0) < 3 &&
          (openedAt == null || openedAt.isBefore(until)) &&
          (resolvedAt == null || resolvedAt.isAfter(start))) {
        incompleteCalls++;
      }
    }
    averageResponseSeconds = responseSamples == 0
        ? null
        : (responseTotal / responseSamples).round();

    // Merge the last known legacy interval only if no explicit interval has it.
    final known = intervals.toList();
    final keys = known
        .map(
          (d) =>
              '${d['incidentId']}/${_date(d['startAt'])?.microsecondsSinceEpoch}',
        )
        .toSet();
    for (final entry in calls.entries) {
      final data = entry.value;
      final stop = _date(data['downtimeStartedAt']);
      if (stop == null || (data['schemaVersion'] as num? ?? 0) >= 3) continue;
      final ended = _date(data['downtimeEndedAt']);
      if (ended == null &&
          (data['canRun'] != false || data['status'] == 'resolved')) {
        continue;
      }
      final key = '${entry.key}/${stop.microsecondsSinceEpoch}';
      if (keys.add(key)) {
        known.add({
          ...data,
          'incidentId': entry.key,
          'startAt': data['downtimeStartedAt'],
          'endAt': data['downtimeEndedAt'],
        });
      }
    }
    for (final data in known) {
      final from = _date(data['startAt']);
      final to = _date(data['endAt']) ?? now;
      if (from == null || to.isBefore(from)) continue;
      final clippedStart = from.isAfter(start) ? from : start;
      final clippedEnd = to.isBefore(until) ? to : until;
      if (!clippedEnd.isAfter(clippedStart)) continue;
      final seconds = clippedEnd.difference(clippedStart).inSeconds;
      downtimeSeconds += seconds;
      row(data).downtimeSeconds += seconds;
    }
    machines = rows.values.toList()
      ..sort((a, b) {
        final byDuration = b.downtimeSeconds.compareTo(a.downtimeSeconds);
        return byDuration != 0 ? byDuration : a.name.compareTo(b.name);
      });
  }

  int opened = 0;
  int resolved = 0;
  int downtimeSeconds = 0;
  int incompleteCalls = 0;
  int responseSamples = 0;
  int? averageResponseSeconds;
  List<MachineReport> machines = [];
}
