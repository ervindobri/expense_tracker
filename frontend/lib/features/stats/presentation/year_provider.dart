

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'year_provider.g.dart';


@riverpod
class YearNotifier extends Notifier<int> {
  @override
  int build() {
    return DateTime.now().year;
  }


  void set(int year){
    state = year;
  }

}