import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_method_item.dart';
import '../providers/payment_method_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/payment_method_edit_sheet.dart';
import '../widgets/payment_method_reorder_tile.dart';

class PaymentMethodManagerPage extends ConsumerWidget {
  const PaymentMethodManagerPage({super.key});

  Future<void> _showMessage(BuildContext context, String message) async {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addMethod(BuildContext context, WidgetRef ref) async {
    final name = await showPaymentMethodEditSheet(
      context,
      title: '新增支付方式',
      confirmText: '新增',
    );
    if (name == null || !context.mounted) return;
    try {
      await ref.read(paymentMethodsProvider.notifier).add(name);
      if (!context.mounted) return;
      await _showMessage(context, '已新增支付方式');
    } on EmptyPaymentMethodNameError catch (e) {
      if (!context.mounted) return;
      await _showMessage(context, e.toString());
    } on DuplicatePaymentMethodNameError catch (e) {
      if (!context.mounted) return;
      await _showMessage(context, e.toString());
    }
  }

  Future<void> _renameMethod(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodItem item,
  ) async {
    final name = await showPaymentMethodEditSheet(
      context,
      title: '编辑支付方式',
      initialName: item.name,
      confirmText: '保存',
    );
    if (name == null || !context.mounted) return;
    try {
      await ref.read(paymentMethodsProvider.notifier).rename(item: item, name: name);
      if (!context.mounted) return;
      await _showMessage(context, '已更新名称');
    } on EmptyPaymentMethodNameError catch (e) {
      if (!context.mounted) return;
      await _showMessage(context, e.toString());
    } on DuplicatePaymentMethodNameError catch (e) {
      if (!context.mounted) return;
      await _showMessage(context, e.toString());
    }
  }

  Future<void> _deleteMethod(
    BuildContext context,
    WidgetRef ref,
    PaymentMethodItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除支付方式'),
        content: Text('删除「${item.name}」后，相关账单会回退到微信。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(paymentMethodsProvider.notifier).delete(item);
    if (!context.mounted) return;
    await _showMessage(context, '已删除并回退账单');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text('支付方式管理'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMethod(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新增'),
      ),
      body: methodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败: $error')),
        data: (methods) => _PaymentMethodManagerBody(
          methods: methods,
          onReorder: (orderedIds) =>
              ref.read(paymentMethodsProvider.notifier).reorder(orderedIds),
          onRename: (item) => _renameMethod(context, ref, item),
          onDelete: (item) => _deleteMethod(context, ref, item),
        ),
      ),
    );
  }
}

class _PaymentMethodManagerBody extends StatelessWidget {
  const _PaymentMethodManagerBody({
    required this.methods,
    required this.onReorder,
    required this.onRename,
    required this.onDelete,
  });

  final List<PaymentMethodItem> methods;
  final Future<void> Function(List<String> orderedIds) onReorder;
  final void Function(PaymentMethodItem item) onRename;
  final void Function(PaymentMethodItem item) onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '拖动调整顺序，点击条目可重命名',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: methods.length,
              onReorder: (oldIndex, newIndex) {
                final next = [...methods];
                if (oldIndex < newIndex) newIndex -= 1;
                final moved = next.removeAt(oldIndex);
                next.insert(newIndex, moved);
                unawaited(onReorder([for (final item in next) item.id]));
              },
              itemBuilder: (context, index) {
                final item = methods[index];
                return Padding(
                  key: ValueKey(item.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PaymentMethodReorderTile(
                    index: index,
                    item: item,
                    onTap: () => onRename(item),
                    onDelete: item.isDefault ? null : () => onDelete(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
