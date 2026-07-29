import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/wallet_item.dart';

final walletsProvider = FutureProvider<List<WalletItem>>((ref) async {
  return DatabaseHelper.instance.getWallets();
});

class CurrentWalletNotifier extends AsyncNotifier<String> {
  final _db = DatabaseHelper.instance;

  @override
  Future<String> build() async {
    return _db.getCurrentWalletId();
  }

  Future<void> setWallet(String walletId) async {
    await _db.setCurrentWalletId(walletId);
    ref.invalidateSelf();
    ref.invalidate(walletsProvider);
  }

  Future<WalletItem> createWallet(String name) async {
    final wallet = await _db.createWallet(name);
    await _db.setCurrentWalletId(wallet.id);
    ref.invalidateSelf();
    ref.invalidate(walletsProvider);
    return wallet;
  }
}

final currentWalletIdProvider =
    AsyncNotifierProvider<CurrentWalletNotifier, String>(
      CurrentWalletNotifier.new,
    );

final currentWalletProvider = FutureProvider<WalletItem?>((ref) async {
  final walletId = await ref.watch(currentWalletIdProvider.future);
  final wallets = await DatabaseHelper.instance.getWallets();
  for (final wallet in wallets) {
    if (wallet.id == walletId) return wallet;
  }
  return null;
});
