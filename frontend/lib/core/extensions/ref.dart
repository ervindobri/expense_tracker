  
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/state/currency_provider.dart';

extension CurrencyExt on WidgetRef {
  // Apply currency conversion
    double convertedAmount(double amount){
      return watch(convertedAmountProvider(amount)).value ?? amount;
    }
}