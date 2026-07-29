import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/asset_item.dart';
import 'wallet_provider.dart';

class AssetSummary {
  final List<AssetItem> debts;
  final List<AssetItem> credits;

  const AssetSummary({required this.debts, required this.credits});

  double get debtTotal => debts.fold<double>(0, (sum, item) => sum + item.amount);
  double get creditTotal =>
      credits.fold<double>(0, (sum, item) => sum + item.amount);
  double get netAssets => creditTotal - debtTotal;
}

class AssetNotifier extends AsyncNotifier<AssetSummary> {
  final _db = DatabaseHelper.instance;

  @override
  Future<AssetSummary> build() async {
    final walletId = await ref.watch(currentWalletIdProvider.future);
    final assets = await _db.getAssets(walletId: walletId);
    final debts = <AssetItem>[];
    final credits = <AssetItem>[];
    for (final item in assets) {
      if (item.type == AssetItem.debt) {
        debts.add(item);
      } else {
        credits.add(item);
      }
    }
    return AssetSummary(debts: debts, credits: credits);
  }

  Future<void> addAsset(AssetItem asset) async {
    await _db.insertAsset(asset);
    ref.invalidateSelf();
  }

  Future<void> deleteAsset(String id) async {
    await _db.deleteAsset(id);
    ref.invalidateSelf();
  }
}

final assetProvider =
    AsyncNotifierProvider<AssetNotifier, AssetSummary>(AssetNotifier.new);
