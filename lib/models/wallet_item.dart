class WalletItem {
  final String id;
  final String name;
  final String createdAt;
  final String updatedAt;

  const WalletItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory WalletItem.fromMap(Map<String, dynamic> map) {
    return WalletItem(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  WalletItem copyWith({String? id, String? name, String? createdAt, String? updatedAt}) {
    return WalletItem(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
