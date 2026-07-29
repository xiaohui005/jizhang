import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

Future<void> showWalletSwitcherSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Consumer(
          builder: (context, ref, _) {
            final walletsAsync = ref.watch(walletsProvider);
            final currentWalletAsync = ref.watch(currentWalletProvider);
            final currentWalletId = ref.watch(currentWalletIdProvider).value;

            return walletsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (wallets) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '钱包',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...wallets.map(
                      (wallet) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          wallet.id == currentWalletId
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: AppColors.primaryDark,
                        ),
                        title: Text(wallet.name),
                        subtitle: Text(wallet.id),
                        onTap: () async {
                          await ref
                              .read(currentWalletIdProvider.notifier)
                              .setWallet(wallet.id);
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final name = await _askWalletName(context);
                          if (name == null || name.trim().isEmpty) return;
                          await ref
                              .read(currentWalletIdProvider.notifier)
                              .createWallet(name.trim());
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('新建钱包'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (currentWalletAsync.value != null)
                      Text(
                        '当前：${currentWalletAsync.value!.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}

Future<String?> _askWalletName(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('新建钱包'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：钱包2'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('确定'),
          ),
        ],
      );
    },
  );
}
