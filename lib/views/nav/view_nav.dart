import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 移动端抽屉导航：脚本列表 + 二级菜单（由 TreeMenuView 渲染）
class Nav extends StatelessWidget {
  const Nav({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: _navigationRail(context)),
          ),
        );
      },
    );
  }

  Widget _navigationRail(BuildContext context) {
    return GetX<NavCtrl>(builder: (controller) {
      return Container(
        width: 64,
        color: AppColors.bgDeep,
        child: Column(
          children: [
            const SizedBox(height: 10),
            for (int i = 0; i < controller.navNameList.length; i++) ...[
              _NavIcon(
                icon: i == 0
                    ? Icons.home_rounded
                    : Icons.play_circle_outline_rounded,
                selected: controller.selectedIndex.value == i,
                tooltip: controller.navNameList[i],
                onTap: () => controller.switchScript(i),
              ),
              const SizedBox(height: 4),
            ],
            const Spacer(),
            AppIconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => addButton(context),
              tooltip: 'Add config',
            ),
            const SizedBox(height: 6),
            AppIconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Get.toNamed('/settings'),
              tooltip: 'Settings',
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    });
  }

  Future<void> addButton(BuildContext context) async {
    String newName = await ApiClient().getNewConfigName();
    final template = 'template'.obs;
    List<String> configAll = await ApiClient().getConfigAll();
    NavCtrl controllerNav = Get.find<NavCtrl>();
    Get.defaultDialog(
      title: I18n.config_add.tr,
      middleText: '',
      onConfirm: () async {
        await controllerNav.addConfig(newName, template.value);
        Get.back();
      },
      content: <Widget>[
        Text(I18n.new_name.tr),
        TextFormField(
          initialValue: newName,
          onChanged: (value) => newName = value,
        ).constrained(width: 200),
        Text(I18n.config_copy_from_exist.tr),
        Obx(() {
          return DropdownButton<String>(
            value: template.value,
            menuMaxHeight: 300,
            items: configAll
                .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                    value: e.toString(),
                    child: Text(
                      e.toString(),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ).constrained(width: 177)))
                .toList(),
            onChanged: (value) => template.value = value.toString(),
          );
        }),
      ].toColumn(crossAxisAlignment: CrossAxisAlignment.start),
    );
  }
}

class _NavIcon extends StatefulWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final content = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.accentDark
                : (_hover ? AppColors.panelSoft : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: widget.selected
                ? Border.all(color: AppColors.accent.withValues(alpha: 0.35))
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.selected
                ? AppColors.accent
                : (_hover ? AppColors.textPrimary : AppColors.textMuted),
          ),
        ),
      ),
    );
    if (widget.tooltip == null) return content;
    return Tooltip(message: widget.tooltip!, child: content);
  }
}
