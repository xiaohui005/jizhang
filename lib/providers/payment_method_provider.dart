import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_method.dart';

class LastPaymentMethodNotifier extends Notifier<String> {
  @override
  String build() => PaymentMethod.wechat;

  void set(String value) => state = PaymentMethod.normalize(value);
}

final lastPaymentMethodProvider =
    NotifierProvider<LastPaymentMethodNotifier, String>(
      LastPaymentMethodNotifier.new,
    );
