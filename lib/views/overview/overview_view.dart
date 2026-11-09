import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/views/asset/asset_panel.dart';
import 'package:oasx/views/overview/date_distribution_panel.dart';
import 'package:oasx/views/overview/overview_banner.dart';
import 'package:oasx/views/overview/overview_log_panel.dart';
import 'package:oasx/views/overview/task_list_panel.dart';
import 'package:oasx/controller/overview/overview_controller.dart';

/// 总览页：三列布局
///   左：任务日期分布 + 任务列表
///   中：横幅 + 日志面板
///   右：资产面板
class Overview extends StatelessWidget {
  const Overview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.find<NavCtrl>();
    final controller = Get.put<OverviewController>(
      OverviewController(name: navCtrl.selectedScript.value),
      tag: navCtrl.selectedScript.value,
    );

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    if (isPortrait) return _PortraitOverview(controller: controller);
    return _DesktopOverview(controller: controller);
  }
}

class _DesktopOverview extends StatelessWidget {
  const _DesktopOverview({required this.controller});

  final OverviewController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final leftWidth = (total * 0.29).clamp(290.0, 400.0);
        final rightWidth = (total * 0.35).clamp(320.0, 520.0);
        final showRight = total >= 1120;
        final showLeft = total >= 780;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppMetrics.pagePadding,
            0,
            AppMetrics.pagePadding,
            AppMetrics.pagePadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showLeft) ...[
                SizedBox(
                  width: leftWidth,
                  child: _LeftColumn(controller: controller),
                ),
                const SizedBox(width: AppMetrics.gap),
              ],
              Expanded(child: _CenterColumn(controller: controller)),
              if (showRight) ...[
                const SizedBox(width: AppMetrics.gap),
                SizedBox(width: rightWidth, child: const AssetPanel()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PortraitOverview extends StatelessWidget {
  const _PortraitOverview({required this.controller});

  final OverviewController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppMetrics.pagePadding,
        0,
        AppMetrics.pagePadding,
        AppMetrics.pagePadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CenterColumn(controller: controller, fixedLogHeight: 420),
          const SizedBox(height: AppMetrics.gap),
          SizedBox(height: 300, child: const AssetPanel()),
          const SizedBox(height: AppMetrics.gap),
          SizedBox(height: 560, child: _LeftColumn(controller: controller)),
        ],
      ),
    );
  }
}

class _LeftColumn extends StatelessWidget {
  const _LeftColumn({required this.controller});

  final OverviewController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final buckets = controller.dateBuckets;
      final totalCount = buckets.fold<int>(0, (sum, e) => sum + e.count);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateDistributionPanel(
            buckets: buckets,
            totalCount: totalCount,
            farthestLabel: controller.farthestTaskLabel,
          ),
          const SizedBox(height: AppMetrics.gap),
          Expanded(
            child: TaskListPanel(
              rows: controller.buildRows(),
              showAll: controller.showAll.value,
              searching: controller.searching.value,
              onToggleAll: controller.toggleShowAll,
              onToggleSearch: controller.toggleSearch,
              onSearchChanged: controller.setSearchKeyword,
              onRunNow: controller.runNow,
              onPinTop: controller.pinTop,
              onPinBottom: controller.pinBottom,
              onOpenSetting: controller.openTaskSetting,
            ),
          ),
        ],
      );
    });
  }
}

class _CenterColumn extends StatelessWidget {
  const _CenterColumn({required this.controller, this.fixedLogHeight});

  final OverviewController controller;
  final double? fixedLogHeight;

  @override
  Widget build(BuildContext context) {
    final banner = Obx(() {
      final state = controller.scriptModel.state.value;
      return OverviewBanner(
        title: controller.displayTitle,
        state: switch (state) {
          ScriptState.running => BannerState.running,
          ScriptState.inactive => BannerState.inactive,
          ScriptState.warning => BannerState.warning,
          ScriptState.updating => BannerState.updating,
        },
        onToggleScript: controller.toggleScript,
        onRunOnce: controller.runNextTaskNow,
      );
    });

    final logPanel = Obx(
      () => OverviewLogPanel(
        controller: controller,
        errorCount: controller.errorCount,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        const SizedBox(height: AppMetrics.gap),
        if (fixedLogHeight != null)
          SizedBox(height: fixedLogHeight, child: logPanel)
        else
          Expanded(child: logPanel),
      ],
    );
  }
}