import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/theme.dart';

/// 主题服务。
///
/// 当前这套 UI 的目标设计（见 assets/design/ui_target.jpg）是一套暗色玻璃风格，
/// 所有组件令牌（lib/config/design/app_theme.dart）都是按暗色调校的，
/// 因此这里固定使用暗色，避免出现「暗色面板 + 亮色输入框」的混搭。
///
/// 以后要支持亮色主题时，应把 AppColors 改成随主题切换的调色板，
/// 而不是只切 ThemeData。
class ThemeService extends GetxService {
  final _dark = true.obs;
  final _color = ColorSeed.baseColor.color.obs;

  bool get isDarkMode => _dark.value;
  Color get color => _color.value;

  ThemeMode get themeMode => ThemeMode.dark;

  @override
  void onInit() {
    _dark.value = true;
    super.onInit();
  }
}
