import 'package:flutter/material.dart';

import '../models/payment_method_item.dart';
import '../theme/app_theme.dart';
import 'payment_method_widgets.dart';

class PaymentMethodReorderTile extends StatelessWidget {
  const PaymentMethodReorderTile({
    super.key,
    required this.index,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final PaymentMethodItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.drag_indicator, size: 20, color: AppColors.textSecondary),
                ),
              ),
              PaymentMethodBadge(method: item.id, compact: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.isDefault ? '默认支付方式' : '自定义支付方式',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (item.isDefault)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                )
              else ...[
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  tooltip: '删除',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
