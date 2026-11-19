import 'package:flutter/material.dart';

import 'package:oasx/config/design/app_theme.dart';

/// 统一的面板容器（圆角、细描边、暗色底）
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppMetrics.panelPadding),
    this.margin = EdgeInsets.zero,
    this.radius = AppRadius.panel,
    this.color,
    this.borderColor,
    this.shadow = true,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool shadow;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: AppDecorations.panel(
        color: color,
        borderColor: borderColor,
        radius: radius,
        shadow: shadow,
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: content,
    );
  }
}

/// 细分割线
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.color, this.height = 1, this.indent = 0});
  final Color? color;
  final double height;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: EdgeInsets.only(left: indent, right: indent),
      color: color ?? AppColors.borderSoft,
    );
  }
}

/// 圆形图标按钮，带 hover 与选中态
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 28,
    this.iconSize = 15,
    this.tooltip,
    this.selected = false,
    this.color,
    this.selectedColor,
    this.backgroundColor,
    this.border = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool selected;
  final Color? color;
  final Color? selectedColor;
  final Color? backgroundColor;
  final bool border;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final tint = widget.selected
        ? (widget.selectedColor ?? AppColors.textPrimary)
        : (widget.color ?? AppColors.textSecondary);
    final bg = widget.selected
        ? AppColors.panelHi
        : (_hover && enabled ? AppColors.panelHover : widget.backgroundColor);

    final button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bg ?? Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: widget.border
                ? Border.all(color: AppColors.border, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(size: widget.iconSize, color: tint),
            child: widget.icon,
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}

/// 章节标题行：标题 + 右侧操作区
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.titleStyle,
    this.padding = EdgeInsets.zero,
  });

  final Widget title;
  final Widget? subtitle;
  final List<Widget> actions;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          DefaultTextStyle(
            style: titleStyle ?? AppText.sectionTitle,
            child: title,
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            DefaultTextStyle(style: AppText.caption, child: subtitle!),
          ],
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

/// 小标签（时间、日期、状态）
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.background,
    this.borderColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.radius = AppRadius.chip,
    this.textStyle,
  });

  final String label;
  final Color? background;
  final Color? borderColor;
  final Color? textColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.panelSoft,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.borderSoft),
      ),
      child: Text(
        label,
        style: (textStyle ?? AppText.label).copyWith(
          color: textColor ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// 面板内的行 hover 高亮容器
class AppHoverRow extends StatefulWidget {
  const AppHoverRow({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.radius = 9,
    this.hoverColor,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? hoverColor;
  final EdgeInsetsGeometry margin;

  @override
  State<AppHoverRow> createState() => _AppHoverRowState();
}

class _AppHoverRowState extends State<AppHoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hover
                ? (widget.hoverColor ?? AppColors.panelSoft)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
