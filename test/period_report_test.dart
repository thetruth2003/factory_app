import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:factory_check_app/models/period_report.dart';

Timestamp at(int day, int hour, [int minute = 0]) =>
    Timestamp.fromDate(DateTime(2026, 10, day, hour, minute));
Map<String, dynamic> interval(
  int day,
  int hour,
  int? endDay,
  int? endHour, {
  String machine = '1A',
}) => {
  'incidentId': machine,
  'machineId': machine,
  'machineKey': machine,
  'startAt': at(day, hour),
  'endAt': endDay == null ? null : at(endDay, endHour!),
};
PeriodReport report({
  Map<String, Map<String, dynamic>> calls = const {},
  List<Map<String, dynamic>> intervals = const [],
}) => PeriodReport(
  calls: calls,
  intervals: intervals,
  start: DateTime(2026, 10, 10),
  end: DateTime(2026, 10, 11),
  now: DateTime(2026, 10, 12, 12),
);

void main() {
  test('clips a midnight-crossing stop and excludes the next day boundary', () {
    final result = report(
      intervals: [interval(9, 23, 10, 2), interval(11, 0, 11, 2)],
    );
    expect(result.downtimeSeconds, 7200);
    expect(result.machines.single.downtimeSeconds, 7200);
  });
  test('ongoing intervals end at now, never at a future range end', () {
    final result = PeriodReport(
      calls: {},
      intervals: [interval(10, 10, null, null)],
      start: DateTime(2026, 10, 10),
      end: DateTime(2026, 10, 12),
      now: DateTime(2026, 10, 10, 11, 30),
    );
    expect(result.downtimeSeconds, 5400);
  });
  test(
    'a call opened before the period contributes downtime but not a new call',
    () {
      final result = report(
        calls: {
          '1A': {
            'schemaVersion': 3,
            'machineId': '1A',
            'openedAt': at(9, 23),
            'resolvedAt': at(10, 2),
          },
        },
        intervals: [interval(9, 23, 10, 2)],
      );
      expect(result.opened, 0);
      expect(result.resolved, 1);
      expect(result.downtimeSeconds, 7200);
      expect(result.incompleteCalls, 0);
    },
  );
  test(
    'separate intervals and machines sum independently without counting call age',
    () {
      final result = report(
        intervals: [
          interval(10, 1, 10, 2),
          interval(10, 5, 10, 6),
          interval(10, 1, 10, 4, machine: '2B'),
        ],
      );
      expect(result.downtimeSeconds, 5 * 3600);
      expect(result.machines.first.id, '2B');
      expect(result.machines.last.downtimeSeconds, 2 * 3600);
    },
  );
  test(
    'legacy lifetime total is not falsely attributed to the selected day',
    () {
      final result = report(
        calls: {
          '1A': {
            'schemaVersion': 2,
            'machineId': '1A',
            'openedAt': at(9, 0),
            'resolvedAt': at(11, 0),
            'downtimeSeconds': 50000,
            'downtimeStartedAt': at(10, 1),
            'downtimeEndedAt': at(10, 2),
          },
        },
      );
      expect(result.downtimeSeconds, 3600);
      expect(result.incompleteCalls, 1);
    },
  );
  test(
    'known legacy interval is not counted twice after it has been persisted',
    () {
      final result = report(
        calls: {
          '1A': {
            'schemaVersion': 2,
            'machineId': '1A',
            'openedAt': at(9, 0),
            'downtimeStartedAt': at(10, 1),
            'downtimeEndedAt': at(10, 2),
          },
        },
        intervals: [interval(10, 1, 10, 2)],
      );
      expect(result.downtimeSeconds, 3600);
      expect(result.incompleteCalls, 1);
    },
  );
  test(
    'first acknowledgement uses valid samples from calls opened in the range',
    () {
      final result = report(
        calls: {
          'a': {
            'schemaVersion': 3,
            'machineId': '1A',
            'openedAt': at(10, 1),
            'ackAt': at(10, 1, 10),
          },
          'b': {'schemaVersion': 3, 'machineId': '1A', 'openedAt': at(10, 2)},
          'c': {
            'schemaVersion': 3,
            'machineId': '1A',
            'openedAt': at(10, 3),
            'ackAt': at(10, 2),
          },
          'd': {
            'schemaVersion': 3,
            'machineId': '1A',
            'openedAt': at(9, 1),
            'ackAt': at(10, 1),
          },
        },
      );
      expect(result.opened, 3);
      expect(result.responseSamples, 1);
      expect(result.averageResponseSeconds, 600);
    },
  );
  test('no known history shows unknown response rather than zero response', () {
    final result = report();
    expect(result.averageResponseSeconds, isNull);
    expect(result.machines, isEmpty);
    expect(result.downtimeSeconds, 0);
  });
}
