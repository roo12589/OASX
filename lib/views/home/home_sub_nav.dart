import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/controller/home_menu.dart';

/// 首页子页切换条：主页 / 更新器 / 工具。
///
/// 重做 UI 时首页只剩 README 渲染，更新器与工具页变成「有页面没入口」。
/// 桌面端没有左侧二级菜单，移动端抽屉里也不方便常驻发现，
/// 所以在内容区顶部固定放一条子页切换，保证入口一眼可见。
class HomeSubNav extends StatelessWidget {
  const HomeSubNav({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<NavCtrl>(builder: (controller) {
      final current = controller.selectedMenu.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppMetrics.gap),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              for (final menu in kHomeMenuOrder) ...[
                _HomeSubNavItem(
                  icon: _iconOf(menu),
                  label: _labelOf(menu),
                  selected: current == menu,
                  onTap: () => controller.switchContent(menu),
                ),
                const SizedBox(width: 2),
              ],
              const Spacer(),
            ],
          ),
        ),
      );
    });
  }

  static IconData _iconOf(String menu) => switch (menu) {
        'Updater' => Icons.system_update_alt_rounded,
        'Tool' => Icons.handyman_outlined,
        _ => Icons.home_rounded,
      };

  static String _labelOf(String menu) => switch (menu) {
        'Updater' => I18n.updater.tr,
        'Tool' => I18n.tool.tr,
        _ => I18n.home.tr,
      };
}

class _HomeSubNavItem extends StatefulWidget {
  const _HomeSubNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_HomeSubNavItem> createState() => _HomeSubNavItemState();
}

class _HomeSubNavItemState extends State<_HomeSubNavItem> {
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
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.accentDark.withValues(alpha: 0.6)
                : (_hover ? AppColors.panelSoft : Colors.transparent),
            borderRadius: BorderRadius.circular(AppRadius.chip - 3),
            border: widget.selected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.28))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
