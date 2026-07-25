import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String get formatDate {
    final format = DateFormat('EEEE, y.MM.dd HH:MM ');
    return format.format(this);
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
