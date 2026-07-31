import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/payment_method_catalog.dart';
import '../theme/app_theme.dart';
import '../providers/payment_method_provider.dart';

List<String> paymentMethodFilterValues() => PaymentMethodCatalog.instance.filterValues;

String paymentMethodLabel(String method) {
  return PaymentMethodCatalog.instance.label(method);
}

IconData paymentMethodIcon(String method) {
  return PaymentMethodCatalog.instance.icon(method);
}

Color paymentMethodColor(String method) {
  return PaymentMethodCatalog.instance.color(method);
}

class PaymentMethodBadge extends ConsumerWidget {
  const PaymentMethodBadge({
    super.key,
    required this.method,
    this.compact = true,
  });

  final String method;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(paymentMethodsProvider);
    final color = paymentMethodColor(method);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 1.5 : 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              paymentMethodIcon(method),
              size: compact ? 11 : 13,
              color: color,
            ),
            SizedBox(width: compact ? 3 : 4),
            Text(
              paymentMethodLabel(method),
              style: TextStyle(
                fontSize: compact ? 9.5 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
