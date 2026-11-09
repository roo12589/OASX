import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/layout/title.dart';

/// 顶部窗口标题栏（Windows 自绘，可拖动）
PreferredSizeWidget buildPlatformAppBar(
  BuildContext context, {
  bool isCollapsed = false,
}) {
  final platform = PlatformUtils.platfrom();
  return switch (platform) {
    PlatformType.windows => _windowAppbar(context, isCollapsed: isCollapsed),
    PlatformType.linux => _desktopAppbar(context, isCollapsed: isCollapsed),
    PlatformType.macOS => _desktopAppbar(context, isCollapsed: isCollapsed),
    PlatformType.android => _mobileTabletAppbar(context, isCollapsed: isCollapsed),
    PlatformType.iOS => _mobileTabletAppbar(context, isCollapsed: isCollapsed),
    _ => _desktopAppbar(context, isCollapsed: isCollapsed),
  };
}

PreferredSizeWidget _windowAppbar(BuildContext context, {bool? isCollapsed}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(AppMetrics.titleBarHeight),
    child: Container(
      height: AppMetrics.titleBarHeight,
      color: AppColors.bg,
      child: Row(
        children: [
          if (isCollapsed == true)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AppIconButton(
                icon: const Icon(Icons.menu_rounded),
                size: 30,
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  // 左侧固定宽度标题区，避免被标签挤走
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: getTitle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 标签区自适应剩余空间，可横向滚动
                  const Expanded(child: _ScriptTabStrip()),
                  const SizedBox(width: 6),
                  const _CaptionActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 标题内容区：Logo + "OASX" + 分隔 + 脚本标签
/// 脚本标签条（Home / oas1 / oas2 ...），横向可滚动。
///
/// 仅在主页面且 NavCtrl 已注册时渲染；登录页/设置页没有 NavCtrl。
class _ScriptTabStrip extends StatelessWidget {
  const _ScriptTabStrip();

  @override
  Widget build(BuildContext context) {
    if (Get.currentRoute != '/main' || !Get.isRegistered<NavCtrl>()) {
      return const SizedBox.shrink();
    }
    return GetX<NavCtrl>(builder: (controller) {
      final names = controller.navNameList
          .where((e) => e != 'Home')
          .toList(growable: false);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: names.length,
              separatorBuilder: (_, __) => const SizedBox(width: 5),
              itemBuilder: (context, i) => Center(
                child: _ScriptTabChip(
                  name: names[i],
                  selected: controller.selectedIndex.value == i + 1,
                  onTap: () => controller.switchScript(i + 1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          AppIconButton(
            icon: const Icon(Icons.add_rounded),
            size: 28,
            tooltip: 'Add config',
            border: true,
            onPressed: () => _showAddConfigDialog(context),
          ),
        ],
      );
    });
  }

  Future<void> _showAddConfigDialog(BuildContext context) async {
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
}

class _ScriptTabChip extends StatefulWidget {
  const _ScriptTabChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ScriptTabChip> createState() => _ScriptTabChipState();
}

class _ScriptTabChipState extends State<_ScriptTabChip> {
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
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 30,
          padding: const EdgeInsets.only(left: 12, right: 6),
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
                widget.name,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 7),
              _PowerDot(active: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _PowerDot extends StatelessWidget {
  const _PowerDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.accent : AppColors.panelSoft,
        border: Border.all(
          color: active ? AppColors.accent : AppColors.borderStrong,
        ),
      ),
      child: Icon(
        Icons.power_settings_new_rounded,
        size: 9,
        color: active ? const Color(0xFF06231A) : AppColors.textMuted,
      ),
    );
  }
}

/// 右侧窗口操作按钮
class _CaptionActions extends StatelessWidget {
  const _CaptionActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          icon: const Icon(Icons.palette_outlined),
          size: 28,
          tooltip: 'Theme',
          onPressed: () => Get.toNamed('/settings'),
        ),
        const SizedBox(width: 2),
        AppIconButton(
          icon: const Icon(Icons.settings_outlined),
          size: 28,
          tooltip: 'Settings',
          onPressed: () => Get.toNamed('/settings'),
        ),
        const SizedBox(width: 8),
        _CaptionIcon(
          icon: Icons.remove_rounded,
          onTap: () async {
            final isMinimized = await windowManager.isMinimized();
            if (isMinimized) {
              windowManager.restore();
            } else {
              windowManager.minimize();
            }
          },
        ),
        FutureBuilder<bool>(
          future: windowManager.isMaximized(),
          builder: (context, snapshot) {
            final maximized = snapshot.data ?? false;
            return _CaptionIcon(
              icon: maximized
                  ? Icons.filter_none_rounded
                  : Icons.crop_square_rounded,
              onTap: () => maximized
                  ? windowManager.unmaximize()
                  : windowManager.maximize(),
            );
          },
        ),
        _CaptionIcon(
          icon: Icons.close_rounded,
          hoverColor: const Color(0xFFC42B1C),
          onTap: () => windowManager.close(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _CaptionIcon extends StatefulWidget {
  const _CaptionIcon({
    required this.icon,
    required this.onTap,
    this.hoverColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;

  @override
  State<_CaptionIcon> createState() => _CaptionIconState();
}

class _CaptionIconState extends State<_CaptionIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _hover
                ? (widget.hoverColor ?? AppColors.panelHover)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: _hover && widget.hoverColor != null
                ? Colors.white
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget _desktopAppbar(BuildContext context,
    {bool? isCollapsed}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(AppMetrics.titleBarHeight),
    child: Container(
      height: AppMetrics.titleBarHeight,
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          if (isCollapsed == true)
            AppIconButton(
              icon: const Icon(Icons.menu_rounded),
              size: 30,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: getTitle())),
          const _ScriptTabStrip(),
        ],
      ),
    ),
  );
}

PreferredSizeWidget _mobileTabletAppbar(BuildContext context,
    {bool? isCollapsed}) {
  return AppBar(
    backgroundColor: AppColors.bg,
    elevation: 0,
    title: getTitle(),
    actions: const [_ScriptTabStrip(), SizedBox(width: 8)],
  );
}
