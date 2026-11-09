import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:treemenu2/treemenu2.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 二级菜单（任务分类树），桌面端与移动端共用
class TreeMenuView extends StatelessWidget {
  const TreeMenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<NavCtrl>(builder: (controller) {
      return Container(
        width: 178,
        decoration: BoxDecoration(
          color: AppColors.bg,
          border: Border(
            right: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: controller.isHomeScript
            ? _homeMenu(controller)
            : _taskMenu(controller),
      );
    });
  }

  Widget _homeMenu(NavCtrl controller) {
    final items = controller.currentTaskMenus;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Obx(() => _MenuEntry(
              label: item.tr,
              selected: controller.selectedMenu.value == item,
              onTap: () => controller.switchContent(item),
            ));
      },
    );
  }

  Widget _taskMenu(NavCtrl controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() => _MenuEntry(
                label: 'Overview'.tr,
                selected: controller.selectedMenu.value == 'Overview',
                leading: Icons.dashboard_outlined,
                onTap: () => controller.switchContent('Overview'),
              )),
          const SizedBox(height: 6),
          const AppDivider(),
          const SizedBox(height: 6),
          TreeView(
            data: controller.scriptMenuJson,
            onTap: controller.switchContent,
          ),
        ],
      ),
    );
  }
}

class _MenuEntry extends StatefulWidget {
  const _MenuEntry({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leading;

  @override
  State<_MenuEntry> createState() => _MenuEntryState();
}

class _MenuEntryState extends State<_MenuEntry> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? AppColors.accent
        : (_hover ? AppColors.textPrimary : AppColors.textSecondary);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.accentDark.withValues(alpha: 0.6)
                : (_hover ? AppColors.panelSoft : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: widget.selected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.28))
                : null,
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                Icon(widget.leading, size: 15, color: color),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: color,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
