import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/period_report.dart';
import '../models/workflow.dart';
import '../ui/call_widgets.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.actor, required this.db});
  final FactoryUser actor;
  final FirebaseFirestore db;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late DateTimeRange _range = _days(7);
  Timer? _timer;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _calls;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _intervals;

  DateTimeRange _days(int days) {
    final today = DateTime.now();
    return DateTimeRange(
      start: DateTime(today.year, today.month, today.day - days + 1),
      end: DateTime(today.year, today.month, today.day),
    );
  }

  void _subscribe() {
    _calls = widget.db
        .collection('incidents')
        .where('createdByCompanyId', isEqualTo: widget.actor.companyId)
        .snapshots(includeMetadataChanges: true);
    // All intervals are needed to include stops that began before the range.
    // Pilot scale; move aggregation server-side before large deployments.
    _intervals = widget.db
        .collection('downtime_intervals')
        .where('companyId', isEqualTo: widget.actor.companyId)
        .snapshots(includeMetadataChanges: true);
  }

  @override
  void initState() {
    super.initState();
    _subscribe();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickDates() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (range != null && mounted) setState(() => _range = range);
  }

  Widget _error(Object error) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(errorLabel(AppLocalizations.of(context), error)),
        TextButton(
          onPressed: () => setState(_subscribe),
          child: Text(AppLocalizations.of(context).retry),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: SessionTitle(title: t.reports, actor: widget.actor),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _calls,
        builder: (context, calls) {
          if (calls.hasError) return _error(calls.error!);
          if (!calls.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _intervals,
            builder: (context, intervals) {
              if (intervals.hasError) return _error(intervals.error!);
              if (!intervals.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final now = DateTime.now();
              final report = PeriodReport(
                calls: {for (final d in calls.data!.docs) d.id: d.data()},
                intervals: intervals.data!.docs.map((d) => d.data()),
                start: _range.start,
                end: DateTime(
                  _range.end.year,
                  _range.end.month,
                  _range.end.day + 1,
                ),
                now: now,
              );
              String minutes(int seconds) =>
                  '${(seconds / 60).toStringAsFixed(1)} ${t.minutes}';
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (calls.data!.metadata.isFromCache ||
                      intervals.data!.metadata.isFromCache)
                    const CacheNotice(),
                  Text(t.reportIntro),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickDates,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      '${DateFormat('dd.MM.yyyy').format(_range.start)} — ${DateFormat('dd.MM.yyyy').format(_range.end)}',
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final days in [1, 7, 30])
                        ActionChip(
                          label: Text(
                            days == 1
                                ? t.today
                                : days == 7
                                ? t.lastSevenDays
                                : t.lastThirtyDays,
                          ),
                          onPressed: () => setState(() => _range = _days(days)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth >= 700
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth;
                      Widget metric(
                        String label,
                        String value,
                        IconData icon,
                      ) => SizedBox(
                        width: width,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  icon,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        value,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                      Text(label),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      return Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          metric(
                            t.callsOpenedInPeriod,
                            '${report.opened}',
                            Icons.add_alert_outlined,
                          ),
                          metric(
                            t.callsResolvedInPeriod,
                            '${report.resolved}',
                            Icons.task_alt,
                          ),
                          metric(
                            t.machineDowntimeTotal,
                            minutes(report.downtimeSeconds),
                            Icons.pause_circle_outline,
                          ),
                          metric(
                            t.firstResponseAverage,
                            report.averageResponseSeconds == null
                                ? '—'
                                : minutes(report.averageResponseSeconds!),
                            Icons.timer_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.responseSampleCount(report.responseSamples),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.reportMethodHelp,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (report.incompleteCalls > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Card(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            t.reportIncomplete(report.incompleteCalls),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    t.machineBreakdown,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (report.machines.isEmpty)
                    EmptyState(message: t.noPeriodData),
                  ...report.machines.map(
                    (machine) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              machine.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${t.downtime}: ${minutes(machine.downtimeSeconds)}',
                            ),
                            Text(
                              '${t.callsOpenedInPeriod}: ${machine.opened} · ${t.callsResolvedInPeriod}: ${machine.resolved}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${t.reportUpdated}: ${DateFormat('dd.MM.yyyy HH:mm').format(now)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
