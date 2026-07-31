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

class PaymentMethodFilterStrip extends StatelessWidget {
  const PaymentMethodFilterStrip({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  final String selectedMethod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = paymentMethodFilterValues();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            _PaymentMethodFilterButton(
              label: paymentMethodLabel(options[i]),
              selected: options[i] == selectedMethod,
              onPressed: () => onChanged(options[i]),
            ),
            if (i != options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodFilterButton extends StatelessWidget {
  const _PaymentMethodFilterButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.primary : Colors.white;
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    return SizedBox(
      height: 30,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: AppColors.textPrimary.withAlpha(80)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
