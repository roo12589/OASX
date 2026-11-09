import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/args/args_view.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/home/home_view.dart';
import 'package:oasx/views/home/tool_view.dart';
import 'package:oasx/views/home/updater_view.dart';
import 'package:oasx/views/overview/overview_view.dart';

/// 内容区分发：总览 / 首页子页 / 参数配置
Widget content() {
  return GetX<NavCtrl>(builder: (controller) {
    final script = controller.selectedScript.value;
    final menu = controller.selectedMenu.value;

    if (script == 'Home') {
      return switch (menu) {
        'Updater' => const _PageFrame(
            titleKey: I18n.updater, child: UpdaterView()),
        'Tool' => const _PageFrame(titleKey: I18n.tool, child: ToolView()),
        _ => const HomeView(),
      };
    }
    if (menu == 'Overview') {
      return const Overview();
    }
    return _TaskArgsPage(script: script, task: menu);
  });
}

/// 参数配置页外框：面包屑 + 返回总览
class _TaskArgsPage extends StatelessWidget {
  const _TaskArgsPage({required this.script, required this.task});

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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppColors.textMuted),
                ),
                Text(task.tr, style: AppText.sectionTitle),
              ],
            ),
          ),
          Expanded(
            child: AppPanel(
              padding: EdgeInsets.zero,
              clip: true,
              child: const Args(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 简单的带标题页框
class _PageFrame extends StatelessWidget {
  const _PageFrame({required this.titleKey, required this.child});

  final String titleKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppMetrics.pagePadding,
          0,
          AppMetrics.pagePadding,
          AppMetrics.pagePadding),
      child: AppPanel(
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: Text(titleKey.tr),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            ),
            const AppDivider(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
