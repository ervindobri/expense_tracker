import 'package:intl/intl.dart';

extension DateTimeExt on DateTime {
  String get formatDate{
    final format = DateFormat('y.MM.dd hh:mm');
    return format.format(this);
  }
}