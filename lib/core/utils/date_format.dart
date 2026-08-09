import 'package:intl/intl.dart';

/// Medium date, e.g. `9 Aug 2026` / `9. aug. 2026`.
String formatDate(DateTime date, String localeName) =>
    DateFormat.yMMMd(localeName).format(date);

/// Month + year, e.g. `Aug 2026`.
String formatMonth(DateTime date, String localeName) =>
    DateFormat.yMMM(localeName).format(date);

/// Short weekday + day, used on dense chart axes.
String formatDayShort(DateTime date, String localeName) =>
    DateFormat.MMMd(localeName).format(date);
