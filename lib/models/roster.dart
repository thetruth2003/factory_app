import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'workflow.dart';

/// Calendar dates are UTC date-only values, not instants. Shift times are UTC
/// instants converted from Europe/Warsaw, independent of the phone's zone.
abstract final class FactoryCalendar {
  static final location = _load();
  static tz.Location _load() {
    tzdata.initializeTimeZones();
    return tz.getLocation('Europe/Warsaw');
  }

  static DateTime local(DateTime instant) =>
      tz.TZDateTime.from(instant, location);
  static DateTime today([DateTime? now]) {
    final d = local(now ?? DateTime.now());
    return DateTime.utc(d.year, d.month, d.day);
  }

  static DateTime date(DateTime d) => DateTime.utc(d.year, d.month, d.day);
  static DateTime week(DateTime d) =>
      date(d).subtract(Duration(days: d.weekday - 1));
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static DateTime instant(DateTime day, int minutes) {
    final value = tz.TZDateTime(
      location,
      day.year,
      day.month,
      day.day,
      minutes ~/ 60,
      minutes % 60,
    );
    // Reject nonexistent spring-forward wall times instead of moving the shift.
    if (value.hour != minutes ~/ 60 || value.minute != minutes % 60) {
      throw const WorkflowException('dstTime');
    }
    // Choose the first occurrence of a repeated autumn wall time explicitly;
    // timezone's constructor otherwise chooses the second occurrence here.
    final earlier = local(value.subtract(const Duration(hours: 1)));
    if (earlier.year == value.year &&
        earlier.month == value.month &&
        earlier.day == value.day &&
        earlier.hour == value.hour &&
        earlier.minute == value.minute) {
      return earlier.toUtc();
    }
    return value.toUtc();
  }

  static String team(FactoryUser actor) =>
      actor.role == 'technician' ? 'maintenance' : actor.role;
  static const teams = [
    'operator',
    'watcher',
    'maintenance',
    'quality',
    'warehouse',
    'supervisor',
    'admin',
  ];
  static bool admin(FactoryUser actor) => actor.role == 'admin';
  static bool canRead(
    FactoryUser actor,
    DateTime day,
    String team, {
    DateTime? now,
  }) =>
      admin(actor) ||
      (FactoryCalendar.team(actor) == team && week(day) == week(today(now)));
}
