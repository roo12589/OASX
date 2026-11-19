import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/model/script_model.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 顶部脚本标签栏。
///
/// 默认**不可拖拽排序**（避免误拖）。添加配置、排序 / 显隐统一收进
/// 主题按钮左侧的「更多」菜单（[ScriptToolsButton]），其中排序面板
/// 同时负责显隐与拖拽重排。
/// 标签本身仍支持右键菜单（打开 / 隐藏 / 左移 / 右移）。
class ScriptTabBar extends StatelessWidget {
  const ScriptTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<NavCtrl>(builder: (controller) {
      // 显式读一次两个 observable，确保 GetX 能追踪到依赖
      // （visibleConfigTabs 是合成 getter，GetX 不保证能追踪到内部读取）。
      final order = controller.tabOrder.toList();
      final hidden = controller.hiddenTabs.toSet();
      final visible = order.where((e) => !hidden.contains(e)).toList();
      if (visible.isEmpty) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(I18n.no_visible_tab.tr, style: AppText.caption),
        );
      }
      return Row(
        children: [
          // 固定的「首页」入口：放在标签列表左侧且不参与排序 / 显隐，
          // 避免所有配置标签把 Home 挤到视野外后回不了首页
          //（更新器 / 工具页都挂在首页下）。
          Obx(
            () => ScriptTabChip(
              name: 'Home',
              label: I18n.home.tr,
              showPower: false,
              selected: controller.selectedScript.value == 'Home',
              onTap: () => controller.selectScript('Home'),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: _tabs(controller, visible)),
        ],
      );
    });
  }

  Widget _tabs(NavCtrl controller, List<String> visible) {
    return ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 5),
        itemBuilder: (context, i) {
          final name = visible[i];
          return Center(
            // 每个标签自己订阅选中态：ListView 的 sliver 在父级重建时
            // 不保证重建全部子项，靠外层传值会出现「内容切了但高亮没变」。
            child: Obx(
              () => ScriptTabChip(
                name: name,
                selected: controller.selectedScript.value == name,
                onTap: () => controller.selectScript(name),
              ),
            ),
          );
        },
      );
  }
}

/// 主题按钮左侧的「更多」按钮：添加配置 / 排序（含显隐）/ 全部显示
class ScriptToolsButton extends StatelessWidget {
  const ScriptToolsButton({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return GetX<NavCtrl>(builder: (controller) {
      // 显式订阅 hiddenTabs：hasHiddenTabs 是合成 getter，
      // 不直接读 observable 时 GetX 会报 "improper use of a GetX"。
      final hiddenCount = controller.hiddenTabs.length;
      return PopupMenuButton<String>(
        tooltip: I18n.more_actions.tr,
        offset: const Offset(0, 34),
        color: AppColors.panelHi,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'add',
            height: 34,
            child: _menuRow(Icons.add_rounded, I18n.config_add.tr),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'order',
            height: 34,
            child: _menuRow(Icons.swap_vert_rounded, I18n.reorder_tabs.tr),
          ),
          PopupMenuItem<String>(
            value: 'show_all',
            enabled: hiddenCount > 0,
            height: 34,
            child: _menuRow(
              Icons.restore_rounded,
              hiddenCount > 0
                  ? '${I18n.show_all_tabs.tr} ($hiddenCount)'
                  : I18n.show_all_tabs.tr,
            ),
          ),
        ],
        onSelected: (value) => _onSelected(context, controller, value),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(Icons.more_horiz_rounded,
              size: 15, color: AppColors.textSecondary),
        ),
      );
    });
  }

  Future<void> _onSelected(
      BuildContext context, NavCtrl controller, String value) async {
    switch (value) {
      case 'add':
        await showAddConfigDialog(context);
      case 'order':
        await showTabOrderSheet(context, controller);
      case 'show_all':
        controller.showAllTabs();
    }
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: AppText.body),
      ],
    );
  }
}

/// 添加配置对话框
Future<void> showAddConfigDialog(BuildContext context) async {
  final navCtrl = Get.find<NavCtrl>();
  String newName = await ApiClient().getNewConfigName();
  final template = 'template'.obs;
  final configAll = await ApiClient().getConfigAll();
  Get.defaultDialog(
    title: I18n.config_add.tr,
    middleText: '',
    textConfirm: I18n.confirm.tr,
    textCancel: I18n.cancel.tr,
    onConfirm: () async {
      await navCtrl.addConfig(newName, template.value);
      Get.back();
    },
    content: SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(I18n.new_name.tr, style: AppText.label),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: newName,
            style: AppText.body,
            onChanged: (v) => newName = v,
          ),
          const SizedBox(height: 10),
          Text(I18n.config_copy_from_exist.tr, style: AppText.label),
          const SizedBox(height: 4),
          Obx(
            () => DropdownButton<String>(
              value: template.value,
              isExpanded: true,
              menuMaxHeight: 300,
              items: configAll
                  .map((e) => DropdownMenuItem(
                        value: e.toString(),
                        child: Text(e.toString(), style: AppText.body),
                      ))
                  .toList(),
              onChanged: (v) => template.value = v.toString(),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 排序 / 显隐面板：列出**全部**配置（含隐藏项，隐藏项置灰），
/// 支持整行拖拽排序，每行右侧一个显隐切换按钮。
Future<void> showTabOrderSheet(BuildContext context, NavCtrl controller) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black45,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(12),
      child: AppPanel(
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
              child: Row(
                children: [
                  Icon(Icons.swap_vert_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(I18n.reorder_tabs.tr, style: AppText.sectionTitle),
                  const Spacer(),
                  Obx(
                    () => controller.hasHiddenTabs
                        ? TextButton(
                            onPressed: controller.showAllTabs,
                            child: Text(I18n.show_all_tabs.tr),
                          )
                        : const SizedBox.shrink(),
                  ),
                  AppIconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    size: 26,
                    onPressed: () => Navigator.of(sheetContext).maybePop(),
                  ),
                ],
              ),
            ),
            const AppDivider(),
            Flexible(
              child: Obx(() {
                // 面板行索引必须与完整 tabOrder 一一对应，
                // 拖拽回调才能直接交给 reorderAllTabs。
                final all = controller.tabOrder.toList();
                if (all.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(I18n.no_data.tr, style: AppText.caption),
                    ),
                  );
                }
                return ReorderableListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  buildDefaultDragHandles: false,
                  itemCount: all.length,
                  onReorder: controller.reorderAllTabs,
                  proxyDecorator: (child, index, animation) => Material(
                    color: AppColors.panelHi,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(9),
                    child: child,
                  ),
                  itemBuilder: (context, i) {
                    final name = all[i];
                    final hidden = controller.hiddenTabs.contains(name);
                    return Opacity(
                      // 隐藏项置灰但仍留在列表里，方便拖拽排序与恢复
                      key: ValueKey<String>(name),
                      opacity: hidden ? 0.55 : 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // 拖拽区覆盖手柄 + 名称（整行可拖），
                                // 右侧显隐按钮留在监听器之外，避免点击被拖拽手势吃掉。
                                Expanded(
                                  child: ReorderableDragStartListener(
                                    index: i,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.drag_indicator_rounded,
                                            size: 16,
                                            color: hidden
                                                ? AppColors.textMuted
                                                : AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          SizedBox(
                                            width: 20,
                                            child: Text(
                                              '${i + 1}',
                                              style: AppText.caption.copyWith(
                                                color: hidden
                                                    ? AppColors.textMuted
                                                    : null,
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures()
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.body.copyWith(
                                                color: hidden
                                                    ? AppColors.textMuted
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                AppIconButton(
                                  icon: Icon(
                                    hidden
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 14,
                                  ),
                                  size: 26,
                                  tooltip: hidden
                                      ? I18n.hidden_tabs.tr
                                      : I18n.hide_tab.tr,
                                  onPressed: () => hidden
                                      ? controller.showTab(name)
                                      : controller.hideTab(name),
                                ),
                              ],
                            ),
                            // 行间细分割线（最后一行不加）
                            if (i < all.length - 1) const AppDivider(indent: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// 单个脚本标签：点击切换、右键菜单、电源开关
class ScriptTabChip extends StatefulWidget {
  const ScriptTabChip({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
    this.label,
    this.showPower = true,
  });

  final String name;

  /// 显示文案，默认与 [name] 相同（Home 用本地化文案）
  final String? label;
  final bool selected;
  final VoidCallback onTap;

  /// 是否显示电源开关（Home 不是脚本，没有启停语义）
  final bool showPower;

  @override
  State<ScriptTabChip> createState() => _ScriptTabChipState();
}

class _ScriptTabChipState extends State<ScriptTabChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTapDown: (details) =>
            _showContextMenu(context, details.globalPosition),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 30,
          padding: const EdgeInsets.only(left: 10, right: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.panelHi
                : (_hover ? AppColors.panelSoft : Colors.transparent),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label ?? widget.name,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              if (widget.showPower) ...[
                const SizedBox(width: 6),
                // 电源开关：点它只切换运行状态，不触发标签切换
                ScriptPowerButton(name: widget.name),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final nav = Get.find<NavCtrl>();
    final order = nav.visibleConfigTabs;
    final index = order.indexOf(widget.name);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 4,
        position.dy + 4,
      ),
      color: AppColors.panelHi,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.border),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'open',
          height: 34,
          child: _menuRow(Icons.tune_rounded, I18n.open_overview.tr),
        ),
        PopupMenuItem<String>(
          value: 'hide',
          height: 34,
          child: _menuRow(Icons.visibility_off_outlined, I18n.hide_tab.tr),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'left',
          enabled: index > 0,
          height: 34,
          child: _menuRow(Icons.arrow_back_rounded, I18n.move_left.tr),
        ),
        PopupMenuItem<String>(
          value: 'right',
          enabled: index >= 0 && index < order.length - 1,
          height: 34,
          child: _menuRow(Icons.arrow_forward_rounded, I18n.move_right.tr),
        ),
      ],
    ).then((value) {
      switch (value) {
        case 'open':
          nav.selectScript(widget.name);
        case 'hide':
          nav.hideTab(widget.name);
        case 'left':
          nav.moveTab(widget.name, -1);
        case 'right':
          nav.moveTab(widget.name, 1);
      }
    });
  }

  Widget _menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: AppText.body),
      ],
    );
  }
}

/// 电源开关：真实控制该脚本的启动/停止
class ScriptPowerButton extends StatelessWidget {
  const ScriptPowerButton({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scriptService = Get.find<ScriptService>();
    return Obx(() {
      final model = scriptService.findScriptModel(name);
      final state = model?.state.value ?? ScriptState.inactive;
      final running = state == ScriptState.running;
      final busy = state == ScriptState.updating;

      final Color bg;
      final Color fg;
      final Color borderColor;
      if (running) {
        bg = AppColors.accent;
        fg = AppColors.accentFg;
        borderColor = AppColors.accent;
      } else if (state == ScriptState.warning) {
        bg = AppColors.dangerSoft;
        fg = AppColors.warning;
        borderColor = AppColors.warning.withValues(alpha: 0.5);
      } else {
        bg = AppColors.panelSoft;
        fg = AppColors.textMuted;
        borderColor = AppColors.borderStrong;
      }

      return Tooltip(
        message: running ? I18n.stop_script.tr : I18n.start_script.tr,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: busy ? null : () => _toggle(scriptService),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                busy ? Icons.sync_rounded : Icons.power_settings_new_rounded,
                size: 10,
                color: fg,
              ),
            ),
          ),
        ),
      );
    });
  }

  Future<void> _toggle(ScriptService scriptService) async {
    final model = scriptService.findScriptModel(name);
    final running = model?.state.value == ScriptState.running;
    if (running) {
      await scriptService.stopScript(name);
      Get.snackbar(I18n.tip.tr, '${I18n.stopping.tr}: $name',
          duration: const Duration(seconds: 1));
    } else {
      await scriptService.startScript(name);
      Get.snackbar(I18n.tip.tr, '${I18n.starting.tr}: $name',
          duration: const Duration(seconds: 1));
    }
  }
}
