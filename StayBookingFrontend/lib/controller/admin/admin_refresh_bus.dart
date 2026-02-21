import 'package:get/get.dart';

class AdminRefreshBus extends GetxService {
  final hotelsMutationVersion = 0.obs;

  void notifyHotelsChanged() {
    hotelsMutationVersion.value++;
  }
}
