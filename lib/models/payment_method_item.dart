import 'payment_method.dart';

class PaymentMethodItem {
  final String id;
  final String name;
  final int sortOrder;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  const PaymentMethodItem({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sort_order': sortOrder,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PaymentMethodItem.fromMap(Map<String, dynamic> map) {
    return PaymentMethodItem(
      id: map['id'] as String,
      name: map['name'] as String,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isDefault: (map['is_default'] as int?) == 1 || PaymentMethod.isBuiltin(map['id'] as String),
      createdAt: (map['created_at'] as String?) ?? '',
      updatedAt: (map['updated_at'] as String?) ?? '',
    );
  }

  PaymentMethodItem copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isDefault,
    String? createdAt,
    String? updatedAt,
  }) {
    return PaymentMethodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
