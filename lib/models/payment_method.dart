class PaymentMethod {
  static const wechat = 'wechat';
  static const alipay = 'alipay';
  static const bank = 'bank';

  static const values = [wechat, alipay, bank];

  static String normalize(String? value) {
    final trimmed = value?.trim();
    return values.contains(trimmed) ? trimmed! : wechat;
  }
}
