import 'package:flutter/material.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/views/layout/appbar.dart';
import 'package:oasx/views/layout/content.dart';
import 'package:oasx/views/nav/tree_menu_view.dart';
import 'package:oasx/views/nav/view_nav.dart';

/// 移动端布局：标题栏（含抽屉按钮）+ 单页内容 + 抽屉导航
class MobileLayoutView extends StatelessWidget {
  const MobileLayoutView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: buildPlatformAppBar(context, isCollapsed: true),
      drawer: drawer(context),
      body: content(),
    );
  }

  Widget drawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Nav(),
          Expanded(child: TreeMenuView()),
        ],
      ),
    );
  }
}
