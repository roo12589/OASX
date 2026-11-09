import 'package:flutter/material.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/views/layout/content.dart';

/// 桌面布局：单行标题栏（Logo + 脚本标签 + 窗口按钮）+ 内容区
class DesktopLayoutView extends StatelessWidget {
  const DesktopLayoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: buildPlatformAppBar(context),
      body: content(),
    );
  }
}
