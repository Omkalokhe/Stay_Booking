import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:stay_booking_frontend/model/payment_models.dart';
import 'package:stay_booking_frontend/service/payment/payment_api_client.dart';

class RazorpayPaymentService {
  RazorpayPaymentService({
    required PaymentApiClient apiClient,
    Razorpay? razorpay,
    Duration pollingInterval = const Duration(seconds: 2),
    Duration pollingTimeout = const Duration(seconds: 90),
  }) : _apiClient = apiClient,
       _razorpay = razorpay ?? Razorpay(),
       _pollingInterval = pollingInterval,
       _pollingTimeout = pollingTimeout {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  final PaymentApiClient _apiClient;
  final Razorpay _razorpay;
  final Duration _pollingInterval;
  final Duration _pollingTimeout;
  static const String _fallbackRazorpayKeyId = 'rzp_test_SIlc3ejkMvjn2O';

  Completer<PaymentFlowResult>? _flowCompleter;
  int? _activeBookingId;
  String _activeOrderId = '';
  bool _verifyTriggered = false;
  bool _disposed = false;

  bool get isProcessing =>
      _flowCompleter != null && !(_flowCompleter?.isCompleted ?? true);

  Future<PaymentFlowResult> startPaymentFlow({
    required int bookingId,
    required String userEmail,
    String userContact = '',
    String displayName = 'Stay Booking',
    String description = 'Room booking payment',
  }) async {
    if (_disposed) {
      return PaymentFlowResult.failed(
        'Payment service is disposed. Please reopen the screen and try again.',
      );
    }
    if (isProcessing) {
      return PaymentFlowResult.failed(
        'A payment is already in progress. Please wait.',
      );
    }

    _log('start_payment', {'bookingId': bookingId});
    _flowCompleter = Completer<PaymentFlowResult>();
    _activeBookingId = bookingId;
    _activeOrderId = '';
    _verifyTriggered = false;

    try {
      final order = await _apiClient.createOrder(
        request: CreateRazorpayOrderRequest(bookingId: bookingId),
      );
      _activeOrderId = order.orderId;
      _openCheckout(
        order: order,
        userEmail: userEmail,
        userContact: userContact,
        displayName: displayName,
        description: description,
      );

      return await _flowCompleter!.future.timeout(
        _pollingTimeout + const Duration(seconds: 20),
        onTimeout: () => PaymentFlowResult.pending(
          message:
              'Bank confirmation is taking longer than expected. We will keep checking in background.',
        ),
      );
    } on PaymentApiException catch (e) {
      return PaymentFlowResult.failed(e.message);
    } catch (e) {
      return PaymentFlowResult.failed(
        'Unable to start payment flow right now. Please try again. ($e)',
      );
    } finally {
      _flowCompleter = null;
      _activeBookingId = null;
      _activeOrderId = '';
      _verifyTriggered = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _razorpay.clear();
  }

  void _openCheckout({
    required RazorpayOrderResponse order,
    required String userEmail,
    required String userContact,
    required String displayName,
    required String description,
  }) {
    final options = <String, dynamic>{
      'key': order.keyId.trim().isEmpty
          ? _fallbackRazorpayKeyId
          : order.keyId.trim(),
      'order_id': order.orderId,
      'amount': order.amountInPaise,
      'currency': order.currency,
      'name': displayName,
      'description': description,
      'retry': <String, dynamic>{'enabled': true, 'max_count': 1},
      'prefill': <String, dynamic>{
        'email': userEmail.trim(),
        if (userContact.trim().isNotEmpty) 'contact': userContact.trim(),
      },
      'notes': <String, dynamic>{'bookingId': '${order.bookingId}'},
    };
    _log('open_checkout', {
      'bookingId': order.bookingId,
      'orderId': order.orderId,
      'amountInPaise': order.amountInPaise,
    });
    _razorpay.open(options);
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    if (_verifyTriggered) return;
    _verifyTriggered = true;

    final bookingId = _activeBookingId;
    if (bookingId == null) {
      _complete(PaymentFlowResult.failed('Payment context is missing.'));
      return;
    }

    _log('gateway_success', {'bookingId': bookingId});

    var continuePolling = true;
    try {
      await _apiClient.verifyPayment(
        request: VerifyRazorpayPaymentRequest(
          bookingId: bookingId,
          razorpayOrderId: (response.orderId ?? '').trim().isEmpty
              ? _activeOrderId
              : response.orderId!.trim(),
          razorpayPaymentId: (response.paymentId ?? '').trim(),
          razorpaySignature: (response.signature ?? '').trim(),
        ),
      );
    } on PaymentApiException catch (e) {
      _log('verify_error', {
        'bookingId': bookingId,
        'transient': e.isTransient,
        'statusCode': e.statusCode,
        'message': e.message,
      });
      if (!e.isTransient) {
        continuePolling = false;
        _complete(PaymentFlowResult.failed(e.message));
      }
    } catch (e) {
      _log('verify_exception', {'bookingId': bookingId, 'message': '$e'});
      // Treat unknown verify failures as transient and continue polling.
    }

    if (!continuePolling) return;

    final pollResult = await _pollUntilFinal(bookingId);
    _complete(pollResult);
  }

  void _onPaymentError(PaymentFailureResponse response) {
    final code = response.code;
    final message = (response.message ?? 'Payment failed.').trim();
    _log('gateway_error', {'code': code, 'message': message});

    final lowered = message.toLowerCase();
    final cancelled =
        code == 2 || lowered.contains('cancel') || lowered.contains('dismiss');
    if (cancelled) {
      _complete(PaymentFlowResult.cancelled());
      return;
    }
    _complete(PaymentFlowResult.failed(message));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    final wallet = (response.walletName ?? '').trim();
    _log('external_wallet', {'wallet': wallet});
    _complete(
      PaymentFlowResult.pending(
        message: wallet.isEmpty
            ? 'External wallet selected. Please confirm payment status shortly.'
            : 'External wallet selected: $wallet. Please confirm payment status shortly.',
      ),
    );
  }

  Future<PaymentFlowResult> _pollUntilFinal(int bookingId) async {
    final deadline = DateTime.now().add(_pollingTimeout);
    PaymentApiException? lastTransientError;

    while (DateTime.now().isBefore(deadline)) {
      try {
        final status = await _apiClient.getPaymentStatus(bookingId: bookingId);
        _log('poll_tick', {
          'bookingId': bookingId,
          'isFinal': status.isFinal,
          'paymentStatus': paymentStatusToApiValue(status.paymentStatus),
        });

        if (status.isFinal) {
          if (status.paymentStatus == PaymentStatus.success) {
            final message = status.frontendMessage.trim().isEmpty
                ? 'Payment successful. Booking confirmed.'
                : status.frontendMessage;
            return PaymentFlowResult.success(message: message, status: status);
          }
          if (status.paymentStatus == PaymentStatus.failed ||
              status.paymentStatus == PaymentStatus.refunded) {
            final message = status.frontendMessage.trim().isEmpty
                ? (status.lastErrorDescription?.trim().isNotEmpty == true
                      ? status.lastErrorDescription!.trim()
                      : 'Payment failed. Please retry.')
                : status.frontendMessage;
            return PaymentFlowResult.failed(message);
          }
          return PaymentFlowResult.failed(
            'Payment reached final state but could not be resolved.',
          );
        }
      } on PaymentApiException catch (e) {
        if (!e.isTransient) return PaymentFlowResult.failed(e.message);
        lastTransientError = e;
        _log('poll_transient_error', {'bookingId': bookingId, 'message': e.message});
      } catch (e) {
        _log('poll_exception', {'bookingId': bookingId, 'message': '$e'});
      }

      await Future<void>.delayed(_pollingInterval);
    }

    final message = lastTransientError?.message.trim().isNotEmpty == true
        ? 'Bank confirmation is taking longer than expected. ${lastTransientError!.message}'
        : 'Bank confirmation is taking longer than expected. We will keep checking in background.';
    return PaymentFlowResult.pending(message: message);
  }

  void _complete(PaymentFlowResult result) {
    final completer = _flowCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(result);
  }

  void _log(String event, Map<String, Object?> data) {
    if (!kDebugMode) return;
    final details = data.entries
        .map((e) => '${e.key}=${e.value ?? 'null'}')
        .join(', ');
    debugPrint('[RazorpayService] $event${details.isEmpty ? '' : ' | $details'}');
  }
}
