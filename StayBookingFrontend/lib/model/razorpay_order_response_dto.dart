class RazorpayOrderResponseDto {
  const RazorpayOrderResponseDto({
    required this.orderId,
    required this.keyId,
    required this.amountInPaise,
    required this.currency,
    required this.frontendMessage,
  });

  final String orderId;
  final String keyId;
  final int amountInPaise;
  final String currency;
  final String frontendMessage;

  factory RazorpayOrderResponseDto.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponseDto(
      orderId: (json['orderId'] as String?)?.trim() ?? '',
      keyId: (json['keyId'] as String?)?.trim() ?? '',
      amountInPaise: _toInt(json['amountInPaise']),
      currency: (json['currency'] as String?)?.trim().toUpperCase() ?? 'INR',
      frontendMessage: (json['frontendMessage'] as String?)?.trim() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
