import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 中间日志面板：Tab（日志 / 运行日志 / 错误日志 / 任务统计）
class OverviewLogPanel extends StatefulWidget {
  const OverviewLogPanel({
    super.key,
    required this.controller,
    required this.errorCount,
  });

  final LogMixin controller;
  final int errorCount;

  @override
  State<OverviewLogPanel> createState() => _OverviewLogPanelState();
}

class _OverviewLogPanelState extends State<OverviewLogPanel> {
  int _tabIndex = 0;

  /// 折叠状态：只显示 Tab 栏，隐藏日志内容
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        mainAxisSize: _collapsed ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
            child: Row(
              children: [
                // 标签区可横向滚动，避免窄面板下溢出
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TabButton(
                          label: I18n.log.tr,
                          selected: _tabIndex == 0,
                          onTap: () => setState(() => _tabIndex = 0),
                        ),
                        _TabButton(
                          label: I18n.runtime_log.tr,
                          selected: _tabIndex == 1,
                          onTap: () => setState(() => _tabIndex = 1),
                        ),
                        _TabButton(
                          label: I18n.error_log.tr,
                          selected: _tabIndex == 2,
                          badge: widget.errorCount,
                          onTap: () => setState(() => _tabIndex = 2),
                        ),
                        _TabButton(
                          label: I18n.task_stats.tr,
                          selected: _tabIndex == 3,
                          onTap: () => setState(() => _tabIndex = 3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _logActions(),
                // 「展开」：折叠日志内容，只保留 Tab 栏（对应设计稿右上角 展开/收起）
                _collapseButton(),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const AppDivider(),
          if (!_collapsed)
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _LogList(controller: widget.controller),
                  _LogList(controller: widget.controller, keyword: 'INFO'),
                  _LogList(controller: widget.controller, keyword: 'ERROR'),
                  _TaskStats(controller: widget.controller),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _collapseButton() {
    return AppIconButton(
      icon: Icon(
        _collapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
        size: 14,
      ),
      size: 24,
      tooltip: _collapsed ? I18n.expand.tr : I18n.collapse.tr,
      onPressed: () => setState(() => _collapsed = !_collapsed),
    );
  }

  Widget _logActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => AppIconButton(
            icon: Icon(
              widget.controller.autoScroll.value
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              size: 14,
            ),
            size: 24,
            tooltip: 'Auto scroll',
            selected: widget.controller.autoScroll.value,
            onPressed: widget.controller.toggleAutoScroll,
          ),
        ),
        AppIconButton(
          icon: const Icon(Icons.content_copy_rounded, size: 13),
          size: 24,
          tooltip: 'Copy log',
          onPressed: widget.controller.copyLogs,
        ),
        AppIconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          size: 24,
          tooltip: I18n.clear_log.tr,
          onPressed: widget.controller.clearLog,
        ),
      ],
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
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
        child: Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.panelHi : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.borderStrong : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.textPrimary
                      : (_hover ? AppColors.textSecondary : AppColors.textMuted),
                ),
              ),
              if (widget.badge > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${widget.badge}',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 日志滚动列表
class _LogList extends StatefulWidget {
  const _LogList({required this.controller, this.keyword});

  final LogMixin controller;
  final String? keyword;

  @override
  State<_LogList> createState() => _LogListState();
}

class _LogListState extends State<_LogList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToBottom());
    widget.controller.scrollLogs = ({
      bool isJump = false,
      bool force = false,
      int scrollOffset = -1,
    }) {
      if (!mounted) return;
      if (!force && !widget.controller.autoScroll.value) return;
      _jumpToBottom();
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final all = widget.controller.logs;
      final logs = widget.keyword == null
          ? List<String>.from(all)
          : all.where((e) => e.contains(widget.keyword!)).toList();
      if (logs.isEmpty) {
        return Center(
          child: Text(I18n.no_data.tr, style: AppText.caption),
        );
      }
      return NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (!_scrollController.hasClients) return false;
          final max = _scrollController.position.maxScrollExtent;
          final current = _scrollController.offset;
          final atBottom = current >= (max - 60);
          if (atBottom != widget.controller.autoScroll.value) {
            widget.controller.autoScroll.value = atBottom;
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
          itemCount: logs.length,
          itemBuilder: (context, index) => _LogLine(text: logs[index]),
        ),
      );
    });
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: _buildRich(text),
    );
  }

  Widget _buildRich(String raw) {
    final timeMatch =
        RegExp(r'^(\d{2}:\d{2}:\d{2})(\.\d{3})?').firstMatch(raw);
    if (timeMatch == null) {
      return SelectableText(
        raw,
        maxLines: 1,
        style: AppText.mono.copyWith(color: AppColors.textSecondary),
      );
    }
    final time = timeMatch.group(0)!;
    final rest = raw.substring(time.length);
    final levelMatch =
        RegExp(r'^\s*(INFO|WARNING|ERROR|CRITICAL)').firstMatch(rest);

    String level = '';
    var body = rest;
    var levelColor = AppColors.textSecondary;
    if (levelMatch != null) {
      level = levelMatch.group(1)!;
      body = rest.substring(levelMatch.end);
      levelColor = switch (level) {
        'INFO' => const Color(0xFF5E93B8),
        'WARNING' => AppColors.warning,
        'ERROR' || 'CRITICAL' => AppColors.danger,
        _ => AppColors.textSecondary,
      };
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: AppText.mono,
        children: [
          TextSpan(
            text: time,
            style: AppText.mono.copyWith(color: AppColors.cyan),
          ),
          if (level.isNotEmpty)
            TextSpan(
              text: ' $level',
              style: AppText.mono.copyWith(
                color: levelColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          TextSpan(
            text: body,
            style: AppText.mono.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TaskStats extends StatelessWidget {
  const _TaskStats({required this.controller});

  final LogMixin controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logs = controller.logs;
      final total = logs.length;
      final errors = logs.where((e) => e.contains('ERROR')).length;
      final warnings = logs.where((e) => e.contains('WARNING')).length;
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatTile(label: 'Lines', value: '$total', color: AppColors.info),
            _StatTile(
                label: 'Errors', value: '$errors', color: AppColors.danger),
            _StatTile(
                label: 'Warnings', value: '$warnings', color: AppColors.warning),
          ],
        ),
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppText.caption),
          const SizedBox(height: 4),
          Text(value, style: AppText.number.copyWith(color: color)),
        ],
      ),
    );
  }
}
