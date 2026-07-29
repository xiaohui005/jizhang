class AssetItem {
  static const debt = 'debt';
  static const credit = 'credit';

  final String id;
  final String walletId;
  final String type;
  final String name;
  final String note;
  final double amount;
  final String createdAt;
  final String updatedAt;

  const AssetItem({
    required this.id,
    this.walletId = 'wallet_default',
    required this.type,
    required this.name,
    required this.note,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'type': type,
      'name': name,
      'note': note,
      'amount': amount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AssetItem.fromMap(Map<String, dynamic> map) {
    return AssetItem(
      id: map['id'] as String,
      walletId: (map['wallet_id'] as String?) ?? 'wallet_default',
      type: map['type'] as String,
      name: map['name'] as String,
      note: (map['note'] as String?) ?? '',
      amount: (map['amount'] as num).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
