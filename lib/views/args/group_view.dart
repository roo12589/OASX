part of args;

/// 单个参数分组：暗色玻璃面板 + 可折叠标题行 + 参数行列表
class ArgsGroupPanel extends StatefulWidget {
  const ArgsGroupPanel({
    super.key,
    required this.groupName,
    this.initiallyExpanded = true,
  });

  final String groupName;
  final bool initiallyExpanded;

  @override
  State<ArgsGroupPanel> createState() => _ArgsGroupPanelState();
}

class _ArgsGroupPanelState extends State<ArgsGroupPanel> {
  late bool _expanded = widget.initiallyExpanded;
  bool _headerHover = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ArgsController>();
    final groupsModel = controller.groupsData.value[widget.groupName];
    final members = groupsModel?.members ?? const <dynamic>[];

    return AppPanel(
      margin: const EdgeInsets.only(bottom: AppMetrics.gap),
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(members.length),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? _body(controller, groupsModel, members)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }

  Widget _header(int count) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 极窄窗口下隐藏数量 chip，保证标题区永远不溢出
        final showCount = constraints.maxWidth >= 180;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _headerHover = true),
          onExit: (_) => setState(() => _headerHover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(
                horizontal: AppMetrics.panelPadding,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: _headerHover ? AppColors.panelHi : Colors.transparent,
                border: _expanded
                    ? const Border(
                        bottom:
                            BorderSide(color: AppColors.borderSoft, width: 1),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 3,
                    height: 13,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? AppColors.accent
                          : AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.groupName.tr,
                      style: AppText.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showCount) ...[
                    const SizedBox(width: 8),
                    AppChip(
                      label: '$count',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      background: AppColors.panelSoft,
                      borderColor: AppColors.borderSoft,
                      textStyle: AppText.caption,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(
    ArgsController controller,
    GroupsModel? groupsModel,
    List<dynamic> members,
  ) {
    if (groupsModel == null || members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppMetrics.panelPadding,
          vertical: 14,
        ),
        child: Text(I18n.no_data.tr, style: AppText.caption),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < members.length; i++) ...[
          if (i > 0) const AppDivider(indent: AppMetrics.panelPadding),
          ArgumentView(
            key: ValueKey<String>('${widget.groupName}-$i'),
            setArgument: controller.setArgument,
            getGroupName: groupsModel.getGroupName,
            index: i,
          ),
        ],
      ],
    );
  }
}
