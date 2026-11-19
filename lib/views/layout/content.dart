import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/views/args/args_view.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/home/home_sub_nav.dart';
import 'package:oasx/views/home/home_view.dart';
import 'package:oasx/views/home/tool_view.dart';
import 'package:oasx/views/home/updater_view.dart';
import 'package:oasx/views/overview/overview_view.dart';

/// 内容区分发：总览 / 首页子页 / 参数配置
Widget content() {
  return GetX<NavCtrl>(builder: (controller) {
    final script = controller.selectedScript.value;
    final menu = controller.selectedMenu.value;

    // 首页：固定子页（主页 / 更新器 / 工具）切换条 + 对应页面。
    // 子页切换条放这里而不是只放抽屉里，是为了保证首页的三个入口
    // 在桌面端和移动端都能一眼看到。
    if (script == 'Home') {
      return _HomePageFrame(menu: menu, child: _homeChild(menu));
    }
    if (menu == 'Overview') {
      // 注意：不要写成 `const Overview()`。
      // 切换脚本时本 builder 会重建，但若返回同一个 const 实例，
      // Flutter 的 updateChild 会因 widget 完全相同而跳过子树重建，
      // 导致总览页一直停留在旧脚本的数据上。
      return Overview(key: ValueKey<String>('overview-$script'));
    }
    return _TaskArgsPage(
      key: ValueKey<String>('args-$script-$menu'),
      script: script,
      task: menu,
    );
  });
}

Widget _homeChild(String menu) {
  return switch (menu) {
    'Updater' => const UpdaterView(),
    'Tool' => const ToolView(),
    _ => const HomeView(),
  };
}

/// 首页外框：子页切换条 + 带标题的内容面板
class _HomePageFrame extends StatelessWidget {
  const _HomePageFrame({required this.menu, required this.child});

  final String menu;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppMetrics.pagePadding,
          0,
          AppMetrics.pagePadding,
          AppMetrics.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeSubNav(),
          Expanded(
            child: AppPanel(
              padding: EdgeInsets.zero,
              clip: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSectionHeader(
                    title: Text(_title(menu).tr),
                    actions: [
                      Icon(_icon(menu),
                          size: 15, color: AppColors.textMuted),
                    ],
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  ),
                  const AppDivider(),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _title(String menu) => switch (menu) {
        'Updater' => I18n.updater,
        'Tool' => I18n.tool,
        _ => I18n.home,
      };

  static IconData _icon(String menu) => switch (menu) {
        'Updater' => Icons.system_update_alt_rounded,
        'Tool' => Icons.handyman_outlined,
        _ => Icons.home_rounded,
      };
}

/// 参数配置页外框：面包屑 + 返回总览
class _TaskArgsPage extends StatelessWidget {
  const _TaskArgsPage({
    super.key,
    required this.script,
    required this.task,
  });

  final String script;
  final String task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppMetrics.pagePadding,
          0,
          AppMetrics.pagePadding,
          AppMetrics.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                AppIconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: I18n.back_to_overview.tr,
                  onPressed: () => Get.find<NavCtrl>().backToOverview(),
                ),
                const SizedBox(width: 10),
                Text(script,
                    style: AppText.label.copyWith(color: AppColors.textMuted)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppColors.textMuted),
                ),
                Text(task.tr, style: AppText.sectionTitle),
              ],
            ),
          ),
          const Expanded(
            child: AppPanel(
              padding: EdgeInsets.zero,
              clip: true,
              child: Args(),
            ),
          ),
        ],
      ),
    );
  }
}
