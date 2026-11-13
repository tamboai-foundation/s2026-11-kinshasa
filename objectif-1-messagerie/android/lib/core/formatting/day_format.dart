import 'package:intl/intl.dart';

/// The one way a list names a day: « Aujourd’hui », « Hier », the weekday
/// within the last week, then « Lundi 5 octobre ». Activity, Pay and the
/// driver's rides all group by day with this label.
///
/// Past a week, [withYear] gives « 5 octobre 2025 » (a conversation spans
/// years) instead of « Lundi 5 octobre ». [locale] is the app language
/// (`fr_FR` by default, `en` gives « Today », « Yesterday »).
String dayLabel(
  DateTime date, {
  DateTime? now,
  bool withYear = false,
  String locale = 'fr_FR',
}) {
  final en = locale.startsWith('en');
  final local = date.toLocal();
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return en ? 'Today' : 'Aujourd’hui';
  if (diff == 1) return en ? 'Yesterday' : 'Hier';
  if (diff >= 7 && withYear) {
    return DateFormat('d MMMM yyyy', locale).format(local);
  }
  final label = DateFormat(
    diff < 7 ? 'EEEE' : 'EEEE d MMMM',
    locale,
  ).format(local);
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

/// Consecutive items sharing a day, in the order given (most recent first).
List<(String label, List<T> items)> groupByDay<T>(
  Iterable<T> items,
  DateTime Function(T item) dateOf, {
  DateTime? now,
  String locale = 'fr_FR',
}) {
  final groups = <(String, List<T>)>[];
  for (final item in items) {
    final label = dayLabel(dateOf(item), now: now, locale: locale);
    if (groups.isEmpty || groups.last.$1 != label) {
      groups.add((label, [item]));
    } else {
      groups.last.$2.add(item);
    }
  }
  return groups;
}

/// The day of something still to come (a reservation): « Aujourd’hui »,
/// « Demain », then « Mercredi 7 octobre ». [dayLabel] looks backwards and
/// would call every future day « Aujourd’hui ».
String upcomingDayLabel(
  DateTime date, {
  DateTime? now,
  String locale = 'fr_FR',
}) {
  final en = locale.startsWith('en');
  final local = date.toLocal();
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = day.difference(today).inDays;
  if (diff <= 0) return en ? 'Today' : 'Aujourd’hui';
  if (diff == 1) return en ? 'Tomorrow' : 'Demain';
  final label = DateFormat('EEEE d MMMM', locale).format(local);
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

/// Consecutive items sharing an upcoming day, soonest first.
List<(String label, List<T> items)> groupByUpcomingDay<T>(
  Iterable<T> items,
  DateTime Function(T item) dateOf, {
  DateTime? now,
  String locale = 'fr_FR',
}) {
  final groups = <(String, List<T>)>[];
  for (final item in items) {
    final label = upcomingDayLabel(dateOf(item), now: now, locale: locale);
    if (groups.isEmpty || groups.last.$1 != label) {
      groups.add((label, [item]));
    } else {
      groups.last.$2.add(item);
    }
  }
  return groups;
}
