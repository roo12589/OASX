import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/layout/script_tab_bar.dart';
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
                  const Expanded(child: ScriptTabBar()),
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

/// 右侧窗口操作按钮
class _CaptionActions extends StatelessWidget {
  const _CaptionActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 「更多」：收纳添加配置 / 排序 / 隐藏任务
        if (Get.currentRoute == '/main' && Get.isRegistered<NavCtrl>()) ...[
          const ScriptToolsButton(),
          const SizedBox(width: 2),
        ],
        AppIconButton(
          icon: const Icon(Icons.palette_outlined),
          size: 28,
          tooltip: I18n.change_theme.tr,
          onPressed: () {
            final theme = Get.find<ThemeService>();
            theme.toggle();
          },
        ),
        const SizedBox(width: 2),
        AppIconButton(
          icon: const Icon(Icons.settings_outlined),
          size: 28,
          tooltip: I18n.setting.tr,
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
          const ScriptTabBar(),
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
    actions: const [ScriptTabBar(), SizedBox(width: 8)],
  );
}
