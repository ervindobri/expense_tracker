import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String get formatDate {
    final format = DateFormat('EEEE, y.MM.dd HH:MM ');
    return format.format(this);
  }

  String get formatDayShort {
    final format = DateFormat('E, y.MM.dd HH:MM ');
    return format.format(this);
  }

  bool isDayAfterOrSame(DateTime other) {
    return day >= other.day;
  }

  bool isDayBeforeOrsame(DateTime other) {
    return day <=
        other.day;
  }
}

extension NaiveDateTime on DateTime {
  DateTime get ignoringTimezone => DateTime(
    year,
    month,
    day,
    hour,
    minute,
    second,
    millisecond,
    microsecond,
  );
}
