import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_helper.dart';
import '../models/payment_method.dart';
import '../models/payment_method_item.dart';
import '../services/payment_method_catalog.dart';
import 'bill_provider.dart';

class LastPaymentMethodNotifier extends Notifier<String> {
  @override
  String build() => PaymentMethod.wechat;

  void set(String value) => state = PaymentMethod.normalize(value);
}

class PaymentMethodListNotifier extends AsyncNotifier<List<PaymentMethodItem>> {
  final _db = DatabaseHelper.instance;

  @override
  Future<List<PaymentMethodItem>> build() async {
    final items = await _db.getPaymentMethods();
    PaymentMethodCatalog.instance.update(items);
    return items;
  }

  Future<void> rename({required PaymentMethodItem item, required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const EmptyPaymentMethodNameError();
    }
    final duplicate = await _db.hasPaymentMethodName(trimmed, excludeId: item.id);
    if (duplicate) {
      throw const DuplicatePaymentMethodNameError();
    }
    await _db.updatePaymentMethodName(id: item.id, name: trimmed);
    ref.invalidateSelf();
    await future;
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const EmptyPaymentMethodNameError();
    }
    final duplicate = await _db.hasPaymentMethodName(trimmed);
    if (duplicate) {
      throw const DuplicatePaymentMethodNameError();
    }
    await _db.insertPaymentMethod(trimmed);
    ref.invalidateSelf();
    await future;
  }

  Future<void> reorder(List<String> orderedIds) async {
    await _db.reorderPaymentMethods(orderedIds);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(PaymentMethodItem item) async {
    if (item.isDefault) return;
    await _db.replacePaymentMethodOnBills(fromId: item.id, toId: PaymentMethod.wechat);
    await _db.deletePaymentMethod(item.id);
    ref.invalidateSelf();
    ref.invalidate(billListProvider);
    await future;
  }
}

final lastPaymentMethodProvider =
    NotifierProvider<LastPaymentMethodNotifier, String>(
      LastPaymentMethodNotifier.new,
    );

final paymentMethodsProvider =
    AsyncNotifierProvider<PaymentMethodListNotifier, List<PaymentMethodItem>>(
      PaymentMethodListNotifier.new,
    );

class EmptyPaymentMethodNameError implements Exception {
  const EmptyPaymentMethodNameError();

  @override
  String toString() => '支付方式名称不能为空';
}

class DuplicatePaymentMethodNameError implements Exception {
  const DuplicatePaymentMethodNameError();

  @override
  String toString() => '该支付方式名称已存在';
}
