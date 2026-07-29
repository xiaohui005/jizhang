import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset_item.dart';
import '../providers/asset_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/asset_edit_sheet.dart';
import '../widgets/wallet_switcher_sheet.dart';

class AssetManagerPage extends ConsumerWidget {
  const AssetManagerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(assetProvider);
    final walletAsync = ref.watch(currentWalletProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: const Text('资产管家'),
        actions: [
          IconButton(
            onPressed: () => showWalletSwitcherSheet(context, ref),
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: '切换钱包',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final walletId = await ref.read(currentWalletIdProvider.future);
          final asset = await showAssetEditSheet(context, walletId: walletId);
          if (asset != null) {
            await ref.read(assetProvider.notifier).addAsset(asset);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('添加资产'),
      ),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (summary) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SummaryCard(
                walletName: walletAsync.value?.name ?? '钱包1',
                creditTotal: summary.creditTotal,
                debtTotal: summary.debtTotal,
                netAssets: summary.netAssets,
              ),
              const SizedBox(height: 12),
              _AssetSection(
                title: '负债',
                total: summary.debtTotal,
                items: summary.debts,
                emptyText: '还没有负债记录',
                color: Colors.redAccent,
                onDelete: (id) => ref.read(assetProvider.notifier).deleteAsset(id),
              ),
              const SizedBox(height: 12),
              _AssetSection(
                title: '债权',
                total: summary.creditTotal,
                items: summary.credits,
                emptyText: '还没有债权记录',
                color: Colors.blueAccent,
                onDelete: (id) => ref.read(assetProvider.notifier).deleteAsset(id),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.walletName,
    required this.creditTotal,
    required this.debtTotal,
    required this.netAssets,
  });

  final String walletName;
  final double creditTotal;
  final double debtTotal;
  final double netAssets;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(walletName, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              formatAmount(netAssets),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('资产 ${formatAmount(creditTotal)}'),
                Text('负债 ${formatAmount(debtTotal)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetSection extends StatelessWidget {
  const _AssetSection({
    required this.title,
    required this.total,
    required this.items,
    required this.emptyText,
    required this.color,
    required this.onDelete,
  });

  final String title;
  final double total;
  final List<AssetItem> items;
  final String emptyText;
  final Color color;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(formatAmount(total), style: TextStyle(color: color)),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(emptyText, style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: color.withAlpha(25),
                    child: Icon(
                      title == '负债' ? Icons.remove : Icons.add,
                      color: color,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(item.note),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(formatAmount(item.amount)),
                      IconButton(
                        onPressed: () => onDelete(item.id),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: '删除',
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
