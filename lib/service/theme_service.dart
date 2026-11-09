import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:oasx/config/defaults.dart';
import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/model/const/storage_key.dart';

/// 主题服务。
///
/// 默认亮色（[kDefaultDarkMode] = false），用户可在设置页/标题栏切换，
/// 选择会持久化。切换时 [applyPalette] 更新全局调色板，
/// [AppColors] 的 getter 立即返回新颜色。
class ThemeService extends GetxService {
  final _storage = GetStorage();

  final _dark = kDefaultDarkMode.obs;

  /// 主题版本号：每次切换自增，作为重建整棵树的 key。
  /// 颜色是普通 getter，不会触发响应式刷新，必须让界面整体重建。
  final _revision = 0.obs;

  bool get isDarkMode => _dark.value;

  int get revision => _revision.value;

  ThemeMode get themeMode => _dark.value ? ThemeMode.dark : ThemeMode.light;

  /// 当前调色板（构建非 widget 场景的颜色时可用）
  AppPalette get palette => _dark.value ? AppPalette.dark : AppPalette.light;

  @override
  void onInit() {
    _dark.value =
        _storage.read<bool>(StorageKey.dark.name) ?? kDefaultDarkMode;
    applyPalette(dark: _dark.value);
    super.onInit();
  }

  void switchTheme([bool? dark]) {
    final next = dark ?? !_dark.value;
    if (next == _dark.value) return;
    _dark.value = next;
    _storage.write(StorageKey.dark.name, next);
    applyPalette(dark: next);
    // 自增版本号，GetMaterialApp 会用 key 重建整棵树
    _revision.value++;
    Get.changeThemeMode(themeMode);
    Get.forceAppUpdate();
  }

  void toggle() => switchTheme(!_dark.value);
}
