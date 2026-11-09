import 'package:get/get.dart';

import 'package:oasx/controller/args/args_controller.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/service/script_service.dart';

class LayoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<NavCtrl>(NavCtrl(), permanent: true);
    Get.lazyPut<ArgsController>(() => ArgsController(), fenix: true);
    Get.putAsync(() async => ScriptService(), permanent: true);
  }
}
