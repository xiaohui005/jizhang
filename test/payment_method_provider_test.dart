import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledger_flutter/models/payment_method.dart';
import 'package:ledger_flutter/providers/payment_method_provider.dart';

void main() {
  test('last payment method defaults to wechat and can be updated', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(lastPaymentMethodProvider), PaymentMethod.wechat);

    container.read(lastPaymentMethodProvider.notifier).set(PaymentMethod.bank);

    expect(container.read(lastPaymentMethodProvider), PaymentMethod.bank);
  });
}
