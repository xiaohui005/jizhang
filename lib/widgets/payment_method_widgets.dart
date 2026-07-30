import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import '../theme/app_theme.dart';

List<String> paymentMethodFilterValues() => <String>['', ...PaymentMethod.values];

String paymentMethodLabel(String method) {
  switch (PaymentMethod.normalize(method)) {
    case PaymentMethod.alipay:
      return '支付宝';
    case PaymentMethod.bank:
      return '银行卡';
    case PaymentMethod.wechat:
    default:
      return '微信';
  }
}

IconData paymentMethodIcon(String method) {
  switch (PaymentMethod.normalize(method)) {
    case PaymentMethod.alipay:
      return Icons.payments_outlined;
    case PaymentMethod.bank:
      return Icons.credit_card_outlined;
    case PaymentMethod.wechat:
    default:
      return Icons.chat_bubble_outline;
  }
}

Color paymentMethodColor(String method) {
  switch (PaymentMethod.normalize(method)) {
    case PaymentMethod.alipay:
      return const Color(0xFF1677FF);
    case PaymentMethod.bank:
      return const Color(0xFF596277);
    case PaymentMethod.wechat:
    default:
      return const Color(0xFF07C160);
  }
}

class PaymentMethodBadge extends StatelessWidget {
  const PaymentMethodBadge({
    super.key,
    required this.method,
    this.compact = true,
  });

  final String method;
  final bool compact;

  @override
  Widget build(BuildContext context) {
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
