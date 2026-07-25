
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'passthrough_enabled_notifier.g.dart';

@riverpod
class PassThroughEnabledNotifier extends Notifier<bool>{
    @override
    bool build() => true;


    void set(bool val){
      state = val;
    }
}