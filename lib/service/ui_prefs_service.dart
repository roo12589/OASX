import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:oasx/config/defaults.dart';
import 'package:oasx/model/const/storage_key.dart';

/// 界面功能开关（与资源检测相关）。
///
/// 需求：支持隐藏资源检测相关内容并调整界面，**默认隐藏**。
/// 资源检测本身尚未实现，这里只控制占位资产面板是否显示。
class UiPrefsService extends GetxService {
  final _storage = GetStorage();

  /// 是否显示资产（资源检测）面板
  final showAssetsPanel = kDefaultShowAssetsPanel.obs;

  @override
  void onInit() {
    showAssetsPanel.value = _storage.read<bool>(
          StorageKey.showAssetsPanel.name,
        ) ??
        kDefaultShowAssetsPanel;
    super.onInit();
  }

  void setShowAssetsPanel(bool value) {
    showAssetsPanel.value = value;
    _storage.write(StorageKey.showAssetsPanel.name, value);
  }

  void toggleAssetsPanel() => setShowAssetsPanel(!showAssetsPanel.value);
}
