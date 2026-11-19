import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/component/log/log_store.dart';
import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 中间日志面板。
///
/// Tab：日志 / 运行日志 / 错误日志 / 任务统计 / 历史
/// - 自动滚动：由 LogMixin 的滚动回调注册表驱动，多个 Tab 互不干扰
/// - 折叠：折叠时面板高度收缩为标题栏（不再占满）
/// - 历史：按日期读取落盘的日志，可筛选级别与关键字
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

  @override
  Widget build(BuildContext context) {
    // 折叠状态放在 controller 里，父级布局才知道要不要收缩高度
    return Obx(() {
      final collapsed = widget.controller.collapseLog.value;
      return AppPanel(
        padding: EdgeInsets.zero,
        clip: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(collapsed),
            const SizedBox(height: 6),
            const AppDivider(),
            if (!collapsed)
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    _LogList(controller: widget.controller),
                    _LogList(
                        controller: widget.controller, levelFilter: 'INFO'),
                    _LogList(
                        controller: widget.controller, levelFilter: 'ERROR'),
                    _TaskStats(controller: widget.controller),
                    _HistoryPane(controller: widget.controller),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _header(bool collapsed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 0),
      child: Row(
        children: [
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
                  _TabButton(
                    label: I18n.history_log.tr,
                    selected: _tabIndex == 4,
                    onTap: () => setState(() => _tabIndex = 4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          _logActions(),
          AppIconButton(
            icon: Icon(
              collapsed
                  ? Icons.unfold_more_rounded
                  : Icons.unfold_less_rounded,
              size: 14,
            ),
            size: 24,
            tooltip: collapsed ? I18n.expand.tr : I18n.collapse.tr,
            onPressed: widget.controller.toggleCollapse,
          ),
        ],
      ),
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
            tooltip: I18n.auto_scroll.tr,
            selected: widget.controller.autoScroll.value,
            onPressed: widget.controller.toggleAutoScroll,
          ),
        ),
        AppIconButton(
          icon: const Icon(Icons.content_copy_rounded, size: 13),
          size: 24,
          tooltip: I18n.copy_log.tr,
          onPressed: widget.controller.copyLogs,
        ),
        AppIconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 14),
          size: 24,
          tooltip: I18n.clear_log.tr,
          onPressed: widget.controller.clearLogAndStore,
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
                      : (_hover
                          ? AppColors.textSecondary
                          : AppColors.textMuted),
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

/// 实时日志滚动列表
class _LogList extends StatefulWidget {
  const _LogList({required this.controller, this.levelFilter});

  final LogMixin controller;

  /// 为空表示不过滤；否则按级别过滤（INFO / ERROR / ...）
  final String? levelFilter;

  @override
  State<_LogList> createState() => _LogListState();
}

class _LogListState extends State<_LogList> {
  final _scrollController = ScrollController();

  late final LogScrollCallback _onScrollRequest;

  @override
  void initState() {
    super.initState();
    _onScrollRequest = ({
      bool isJump = false,
      bool force = false,
      int scrollOffset = -1,
    }) {
      if (!mounted) return;
      if (!force && !widget.controller.autoScroll.value) return;
      // IndexedStack 里未显示的列表也有 clients，这里只滚当前可见的那个，
      // 否则会把隐藏 Tab 也滚到底（无害但浪费）。
      if (!_scrollController.hasClients) return;
      _scheduleToBottom();
    };
    widget.controller.registerScrollCallback(_onScrollRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleToBottom());
  }

  @override
  void dispose() {
    widget.controller.unregisterScrollCallback(_onScrollRequest);
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  List<String> _filter(List<String> all) {
    final level = widget.levelFilter;
    if (level == null || level.isEmpty) return all;
    return all
        .where((e) => RegExp('\\b$level\\b', caseSensitive: false).hasMatch(e))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logs = _filter(List<String>.from(widget.controller.logs));
      if (logs.isEmpty) {
        return Center(child: Text(I18n.no_data.tr, style: AppText.caption));
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
        'INFO' => AppColors.info,
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
      final rate = total == 0 ? 0 : (errors / total * 100);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatTile(
                label: I18n.log_lines.tr,
                value: '$total',
                color: AppColors.info),
            _StatTile(
                label: I18n.log_errors.tr,
                value: '$errors',
                color: AppColors.danger),
            _StatTile(
                label: I18n.log_warnings.tr,
                value: '$warnings',
                color: AppColors.warning),
            _StatTile(
                label: I18n.log_error_rate.tr,
                value: '${rate.toStringAsFixed(1)}%',
                color: rate > 10 ? AppColors.danger : AppColors.accent),
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

/// 历史日志：按日期查看已落盘的日志
class _HistoryPane extends StatefulWidget {
  const _HistoryPane({required this.controller});

  final LogMixin controller;

  @override
  State<_HistoryPane> createState() => _HistoryPaneState();
}

class _HistoryPaneState extends State<_HistoryPane> {
  List<DateTime> _dates = const [];
  DateTime? _selectedDate;
  List<PersistedLog> _entries = const [];
  String _level = '';
  final _keywordController = TextEditingController();
  bool _loading = false;
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadDates() async {
    setState(() => _loading = true);
    final dates = await widget.controller.logStore.availableDates();
    if (!mounted) return;
    setState(() {
      _dates = dates;
      _selectedDate = dates.isNotEmpty ? dates.first : null;
      _loading = false;
      _inited = true;
    });
    if (_selectedDate != null) await _loadEntries();
  }

  Future<void> _loadEntries() async {
    final day = _selectedDate;
    if (day == null) return;
    setState(() => _loading = true);
    final entries = await widget.controller.logStore.readDay(
      day,
      level: _level.isEmpty ? null : _level,
      keyword: _keywordController.text,
    );
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String _dateLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (!_inited) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      );
    }
    if (_dates.isEmpty) {
      return Center(child: Text(I18n.no_history.tr, style: AppText.caption));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filterBar(),
        const AppDivider(),
        Expanded(
          child: _loading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                )
              : (_entries.isEmpty
                  ? Center(
                      child:
                          Text(I18n.no_data.tr, style: AppText.caption))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final e = _entries[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: SelectableText(
                            e.text,
                            maxLines: 1,
                            style: AppText.mono.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    )),
        ),
      ],
    );
  }

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 6),
      child: Row(
        children: [
          // 日期下拉
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.panelSoft,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DateTime>(
                value: _selectedDate,
                isDense: true,
                dropdownColor: AppColors.panelHi,
                style: AppText.body,
                icon: Icon(Icons.expand_more_rounded,
                    size: 14, color: AppColors.textMuted),
                items: _dates
                    .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text(_dateLabel(d), style: AppText.body),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedDate = v);
                  _loadEntries();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 级别筛选
          for (final level in const ['', 'INFO', 'WARNING', 'ERROR']) ...[
            _LevelChip(
              label: level.isEmpty ? I18n.log_all.tr : level,
              selected: _level == level,
              color: switch (level) {
                'INFO' => AppColors.info,
                'WARNING' => AppColors.warning,
                'ERROR' => AppColors.danger,
                _ => AppColors.textSecondary,
              },
              onTap: () {
                setState(() => _level = level);
                _loadEntries();
              },
            ),
            const SizedBox(width: 4),
          ],
          const Spacer(),
          // 关键字
          Container(
            width: 150,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.panelSoft,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _keywordController,
                    style: AppText.body,
                    cursorColor: AppColors.accent,
                    onSubmitted: (_) => _loadEntries(),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: I18n.log_search_hint.tr,
                      hintStyle: AppText.caption,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          AppIconButton(
            icon: const Icon(Icons.refresh_rounded, size: 14),
            size: 26,
            tooltip: I18n.log_reload.tr,
            onPressed: _loadDates,
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.panelHi : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? color : AppColors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: selected ? color : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
