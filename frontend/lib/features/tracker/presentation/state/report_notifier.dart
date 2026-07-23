import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_notifier.g.dart';

@riverpod
class ReportNotifier extends Notifier<int>{
  @override
  int build() {
    // default current month
    return DateTime.now().month;
  }


  void set(int month){
    state = month;
  }

}