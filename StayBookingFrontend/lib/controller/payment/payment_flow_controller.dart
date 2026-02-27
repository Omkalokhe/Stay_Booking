import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/auth_controller.dart';
import 'package:stay_booking_frontend/model/payment_models.dart';
import 'package:stay_booking_frontend/service/payment/payment_api_client.dart';
import 'package:stay_booking_frontend/service/payment/razorpay_payment_service.dart';

enum PaymentUiState { idle, loading, success, failure, pending, cancelled }

class PaymentFlowController extends GetxController {
  PaymentFlowController({
    PaymentApiClient? apiClient,
    RazorpayPaymentService? paymentService,
    AuthController? authController,
  }) : _authController = authController ?? Get.find<AuthController>(),
       _paymentService =
           paymentService ??
           RazorpayPaymentService(
             apiClient: apiClient ??
                 PaymentApiClient(
                   baseUrl: const String.fromEnvironment(
                     'API_BASE_URL',
                     defaultValue: 'http://192.168.1.7:8080',
                   ),
                   accessTokenProvider: () async =>
                       Get.find<AuthController>().session.value?.accessToken,
                 ),
           );

  final AuthController _authController;
  final RazorpayPaymentService _paymentService;

  final uiState = PaymentUiState.idle.obs;
  final isLoading = false.obs;
  final message = ''.obs;

  Future<void> startPayment({required int bookingId}) async {
    if (isLoading.value) return;

    uiState.value = PaymentUiState.loading;
    isLoading.value = true;
    message.value = '';

    try {
      final email = (_authController.session.value?.user['email'] as String?)
              ?.trim() ??
          '';
      final phone = (_authController.session.value?.user['mobileno'] as String?)
              ?.trim() ??
          (_authController.session.value?.user['mobileNo'] as String?)?.trim() ??
          (_authController.session.value?.user['phone'] as String?)?.trim() ??
          '';

      final result = await _paymentService.startPaymentFlow(
        bookingId: bookingId,
        userEmail: email,
        userContact: phone,
      );

      switch (result.type) {
        case PaymentFlowType.success:
          uiState.value = PaymentUiState.success;
          break;
        case PaymentFlowType.failed:
          uiState.value = PaymentUiState.failure;
          break;
        case PaymentFlowType.pending:
          uiState.value = PaymentUiState.pending;
          break;
        case PaymentFlowType.cancelled:
          uiState.value = PaymentUiState.cancelled;
          break;
      }
      message.value = result.message;
    } catch (e) {
      uiState.value = PaymentUiState.failure;
      message.value =
          'Unable to process payment right now. Please try again. ($e)';
    } finally {
      // Loader safety: always reset loading regardless of success/failure/timeout.
      isLoading.value = false;
      if (uiState.value == PaymentUiState.loading) {
        uiState.value = PaymentUiState.idle;
      }
    }
  }

  void resetState() {
    uiState.value = PaymentUiState.idle;
    isLoading.value = false;
    message.value = '';
  }

  @override
  void onClose() {
    _paymentService.dispose();
    super.onClose();
  }
}
