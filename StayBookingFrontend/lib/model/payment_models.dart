import 'dart:convert';

enum PaymentMethod { razorpay, unknown }

enum PaymentStatus { pending, success, failed, refunded, unknown }

enum BookingStatus { pending, confirmed, cancelled, completed, noShow, unknown }

enum PaymentFlowType { success, failed, pending, cancelled }

PaymentMethod parsePaymentMethod(dynamic raw) {
  final value = (raw?.toString() ?? '').trim().toUpperCase();
  if (value == 'RAZORPAY') return PaymentMethod.razorpay;
  return PaymentMethod.unknown;
}

PaymentStatus parsePaymentStatus(dynamic raw) {
  final value = (raw?.toString() ?? '').trim().toUpperCase();
  switch (value) {
    case 'PENDING':
      return PaymentStatus.pending;
    case 'SUCCESS':
      return PaymentStatus.success;
    case 'FAILED':
      return PaymentStatus.failed;
    case 'REFUNDED':
      return PaymentStatus.refunded;
    default:
      return PaymentStatus.unknown;
  }
}

BookingStatus parseBookingStatus(dynamic raw) {
  final value = (raw?.toString() ?? '').trim().toUpperCase();
  switch (value) {
    case 'PENDING':
      return BookingStatus.pending;
    case 'CONFIRMED':
      return BookingStatus.confirmed;
    case 'CANCELLED':
      return BookingStatus.cancelled;
    case 'COMPLETED':
      return BookingStatus.completed;
    case 'NO_SHOW':
      return BookingStatus.noShow;
    default:
      return BookingStatus.unknown;
  }
}

String paymentMethodToApiValue(PaymentMethod value) {
  switch (value) {
    case PaymentMethod.razorpay:
      return 'RAZORPAY';
    case PaymentMethod.unknown:
      return 'UNKNOWN';
  }
}

String paymentStatusToApiValue(PaymentStatus value) {
  switch (value) {
    case PaymentStatus.pending:
      return 'PENDING';
    case PaymentStatus.success:
      return 'SUCCESS';
    case PaymentStatus.failed:
      return 'FAILED';
    case PaymentStatus.refunded:
      return 'REFUNDED';
    case PaymentStatus.unknown:
      return 'UNKNOWN';
  }
}

String bookingStatusToApiValue(BookingStatus value) {
  switch (value) {
    case BookingStatus.pending:
      return 'PENDING';
    case BookingStatus.confirmed:
      return 'CONFIRMED';
    case BookingStatus.cancelled:
      return 'CANCELLED';
    case BookingStatus.completed:
      return 'COMPLETED';
    case BookingStatus.noShow:
      return 'NO_SHOW';
    case BookingStatus.unknown:
      return 'UNKNOWN';
  }
}

class CreateRazorpayOrderRequest {
  const CreateRazorpayOrderRequest({required this.bookingId});

  final int bookingId;

  Map<String, dynamic> toJson() => <String, dynamic>{'bookingId': bookingId};
}

class RazorpayOrderResponse {
  const RazorpayOrderResponse({
    required this.bookingId,
    required this.orderId,
    required this.keyId,
    required this.amountInPaise,
    required this.currency,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.frontendMessage,
  });

  final int bookingId;
  final String orderId;
  final String keyId;
  final int amountInPaise;
  final String currency;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final BookingStatus bookingStatus;
  final String frontendMessage;

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      bookingId: _asInt(json['bookingId']),
      orderId: _asString(json['orderId']),
      keyId: _asString(json['keyId']),
      amountInPaise: _asInt(json['amountInPaise']),
      currency: _asString(json['currency']).isEmpty
          ? 'INR'
          : _asString(json['currency']).toUpperCase(),
      paymentMethod: parsePaymentMethod(json['paymentMethod']),
      paymentStatus: parsePaymentStatus(json['paymentStatus']),
      bookingStatus: parseBookingStatus(json['bookingStatus']),
      frontendMessage: _asString(json['frontendMessage']),
    );
  }
}

class VerifyRazorpayPaymentRequest {
  const VerifyRazorpayPaymentRequest({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final int bookingId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'bookingId': bookingId,
    'razorpayOrderId': razorpayOrderId.trim(),
    'razorpayPaymentId': razorpayPaymentId.trim(),
    'razorpaySignature': razorpaySignature.trim(),
  };
}

class VerifyRazorpayPaymentResponse {
  const VerifyRazorpayPaymentResponse({
    required this.bookingId,
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.frontendMessage,
  });

  final int bookingId;
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final PaymentStatus paymentStatus;
  final BookingStatus bookingStatus;
  final String frontendMessage;

  factory VerifyRazorpayPaymentResponse.fromJson(Map<String, dynamic> json) {
    return VerifyRazorpayPaymentResponse(
      bookingId: _asInt(json['bookingId']),
      razorpayOrderId: _asString(json['razorpayOrderId']),
      razorpayPaymentId: _asString(json['razorpayPaymentId']),
      paymentStatus: parsePaymentStatus(json['paymentStatus']),
      bookingStatus: parseBookingStatus(json['bookingStatus']),
      frontendMessage: _asString(json['frontendMessage']),
    );
  }
}

class RazorpayPaymentStatusResponse {
  const RazorpayPaymentStatusResponse({
    required this.bookingId,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.paymentReference,
    required this.isFinal,
    required this.providerOrderId,
    required this.providerPaymentId,
    required this.providerStatus,
    required this.lastErrorCode,
    required this.lastErrorDescription,
    required this.updatedAtRaw,
    required this.frontendMessage,
  });

  final int bookingId;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final BookingStatus bookingStatus;
  final String? paymentReference;
  final bool isFinal;
  final String? providerOrderId;
  final String? providerPaymentId;
  final PaymentStatus providerStatus;
  final String? lastErrorCode;
  final String? lastErrorDescription;
  final String updatedAtRaw;
  final String frontendMessage;

  DateTime? get updatedAt => DateTime.tryParse(updatedAtRaw);

  factory RazorpayPaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayPaymentStatusResponse(
      bookingId: _asInt(json['bookingId']),
      paymentMethod: parsePaymentMethod(json['paymentMethod']),
      paymentStatus: parsePaymentStatus(json['paymentStatus']),
      bookingStatus: parseBookingStatus(json['bookingStatus']),
      paymentReference: _asNullableString(json['paymentReference']),
      isFinal: _asBool(json['isFinal']),
      providerOrderId: _asNullableString(json['providerOrderId']),
      providerPaymentId: _asNullableString(json['providerPaymentId']),
      providerStatus: parsePaymentStatus(json['providerStatus']),
      lastErrorCode: _asNullableString(json['lastErrorCode']),
      lastErrorDescription: _asNullableString(json['lastErrorDescription']),
      updatedAtRaw: _asString(json['updatedAt']),
      frontendMessage: _asString(json['frontendMessage']),
    );
  }
}

class PaymentFlowResult {
  const PaymentFlowResult._({
    required this.type,
    required this.message,
    this.status,
  });

  final PaymentFlowType type;
  final String message;
  final RazorpayPaymentStatusResponse? status;

  bool get isSuccess => type == PaymentFlowType.success;

  factory PaymentFlowResult.success({
    required String message,
    RazorpayPaymentStatusResponse? status,
  }) {
    return PaymentFlowResult._(
      type: PaymentFlowType.success,
      message: message,
      status: status,
    );
  }

  factory PaymentFlowResult.failed(String message) {
    return PaymentFlowResult._(
      type: PaymentFlowType.failed,
      message: message.trim().isEmpty ? 'Payment failed.' : message,
    );
  }

  factory PaymentFlowResult.pending({
    required String message,
    RazorpayPaymentStatusResponse? status,
  }) {
    return PaymentFlowResult._(
      type: PaymentFlowType.pending,
      message: message,
      status: status,
    );
  }

  factory PaymentFlowResult.cancelled({
    String message = 'Payment was cancelled by user.',
  }) {
    return PaymentFlowResult._(
      type: PaymentFlowType.cancelled,
      message: message,
    );
  }
}

class PaymentApiException implements Exception {
  const PaymentApiException({
    required this.message,
    this.statusCode,
    this.isTransient = false,
  });

  final String message;
  final int? statusCode;
  final bool isTransient;

  @override
  String toString() =>
      'PaymentApiException(statusCode: $statusCode, transient: $isTransient, message: $message)';
}

String extractBackendMessage(dynamic payload, {String fallback = 'Request failed.'}) {
  if (payload == null) return fallback;

  if (payload is String) {
    final text = payload.trim();
    if (text.isEmpty) return fallback;
    try {
      final decoded = jsonDecode(text);
      return extractBackendMessage(decoded, fallback: text);
    } catch (_) {
      return text;
    }
  }

  if (payload is Map) {
    final map = Map<String, dynamic>.from(payload);
    final candidates = <dynamic>[
      map['frontendMessage'],
      map['message'],
      map['error'],
      map['detail'],
      map['description'],
      map['lastErrorDescription'],
    ];
    for (final c in candidates) {
      final text = _asString(c);
      if (text.isNotEmpty) return text;
    }
    final errors = map['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = extractBackendMessage(errors.first, fallback: '');
      if (first.isNotEmpty) return first;
    }
    if (errors is Map && errors.isNotEmpty) {
      final first = extractBackendMessage(errors.values.first, fallback: '');
      if (first.isNotEmpty) return first;
    }
    return fallback;
  }

  if (payload is List && payload.isNotEmpty) {
    return extractBackendMessage(payload.first, fallback: fallback);
  }
  return fallback;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) => (value?.toString() ?? '').trim();

String? _asNullableString(dynamic value) {
  final out = _asString(value);
  return out.isEmpty ? null : out;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  final text = (value?.toString() ?? '').trim().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return false;
}
