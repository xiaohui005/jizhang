import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import '../models/payment_method_item.dart';

class PaymentMethodCatalog {
  PaymentMethodCatalog._();

  static final PaymentMethodCatalog instance = PaymentMethodCatalog._();

  List<PaymentMethodItem> _items = const [];
  Map<String, PaymentMethodItem> _byId = const {};

  void update(Iterable<PaymentMethodItem> items) {
    final list = [...items]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _items = List.unmodifiable(list);
    _byId = Map.unmodifiable({for (final item in list) item.id: item});
  }

  List<PaymentMethodItem> get items => _items;

  List<String> get filterValues => _items.isEmpty
      ? <String>['', ...PaymentMethod.values]
      : <String>['', ..._items.map((e) => e.id)];

  PaymentMethodItem? item(String id) => _byId[id];

  bool isDefaultId(String id) {
    final item = _byId[id];
    if (item != null) return item.isDefault;
    return PaymentMethod.isBuiltin(id);
  }

  String label(String id) {
    if (id.isEmpty) return '全部';
    final item = _byId[id];
    if (item != null) return item.name;
    switch (id) {
      case PaymentMethod.alipay:
        return '支付宝';
      case PaymentMethod.bank:
        return '银行卡';
      case PaymentMethod.wechat:
        return '微信';
      default:
        return id;
    }
  }

  IconData icon(String id) {
    switch (id) {
      case PaymentMethod.alipay:
        return Icons.payments_outlined;
      case PaymentMethod.bank:
        return Icons.credit_card_outlined;
      case PaymentMethod.wechat:
        return Icons.chat_bubble_outline;
      default:
        return Icons.payments_outlined;
    }
  }

  Color color(String id) {
    switch (id) {
      case PaymentMethod.alipay:
        return const Color(0xFF1677FF);
      case PaymentMethod.bank:
        return const Color(0xFF596277);
      case PaymentMethod.wechat:
        return const Color(0xFF07C160);
      default:
        return const Color(0xFF636E7F);
    }
  }

  String normalize(String? value) => PaymentMethod.normalize(value);
}
