import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:styled_widget/styled_widget.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 通用日志组件（设置页 / 服务端页 / 任意页面复用）
class LogWidget extends StatefulWidget {
  final LogMixin controller;
  final String title;
  final bool? enableCopy;
  final bool? enableAutoScroll;
  final bool? enableClear;
  final bool? enableCollapse;
  final Widget? topPanelBottomChild;

  const LogWidget({
    super.key,
    required this.controller,
    required this.title,
    this.enableCopy,
    this.enableAutoScroll,
    this.enableClear,
    this.enableCollapse,
    this.topPanelBottomChild,
  });

  @override
  State<StatefulWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController ??= ScrollController(
        initialScrollOffset: widget.controller.savedScrollOffsetVal);    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.autoScroll.value) {
        _scrollLogs(force: true, scrollOffset: -1);
      } else if (widget.controller.savedScrollOffsetVal > 0) {
        _scrollLogs(
            force: true,
            scrollOffset: widget.controller.savedScrollOffsetVal.toInt());
      }
    });
    widget.controller.scrollLogs = _scrollLogs;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopLogPanel(
          title: widget.title,
          controller: widget.controller,
          enableCopy: widget.enableCopy,
          enableAutoScroll: widget.enableAutoScroll,
          enableClear: widget.enableClear,
          enableCollapse: widget.enableCollapse,
          bottomChild: widget.topPanelBottomChild,
        ),
        Obx(() => widget.controller.collapseLog.value
            ? const SizedBox.shrink()
            : LogContent(
                controller: widget.controller,
                scrollController: _scrollController!,
                onUserScroll: _handleUserScroll,
              ).expanded()),
      ],
    );
  }

  @override
  void deactivate() {
    if (_scrollController != null && _scrollController!.hasClients) {
      widget.controller.saveScrollOffset(_scrollController!.offset);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (_scrollController != null && _scrollController!.hasClients) {
      widget.controller.saveScrollOffset(_scrollController!.offset);
    }
    _scrollController?.dispose();
    _scrollController = null;
    super.dispose();
  }

  void _scrollLogs({bool isJump = false, bool force = false, int scrollOffset = -1}) {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController == null || !_scrollController!.hasClients) return;
      if (!force && !widget.controller.autoScroll.value) return;
      final double targetPos = scrollOffset == -1
          ? _scrollController!.position.maxScrollExtent
          : scrollOffset.toDouble();
      final double currentPos = _scrollController!.offset;
      final double distance = (targetPos - currentPos).abs();
      int animateMs = (sqrt(distance) * 10).toInt().clamp(100, 1000);
      _scrollController!
          .animateTo(targetPos,
              duration: Duration(milliseconds: animateMs), curve: Curves.easeOut)
          .whenComplete(() {
        if (_scrollController == null || !_scrollController!.hasClients) return;
        final latestExtent = _scrollController!.position.maxScrollExtent;
        if ((scrollOffset == -1 || widget.controller.autoScroll.value) &&
            latestExtent > targetPos) {
          _scrollController!.jumpTo(latestExtent);
        }
      });
    });
  }

  void _handleUserScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    final maxExtent = _scrollController!.position.maxScrollExtent;
    final currentOffset = _scrollController!.offset;
    final isAtBottom = currentOffset >= (maxExtent - 80);
    if (isAtBottom && !widget.controller.autoScroll.value) {
      widget.controller.autoScroll.value = true;
    } else if (!isAtBottom && widget.controller.autoScroll.value) {
      widget.controller.autoScroll.value = false;
    }
  }
}

/// 日志顶部操作栏
class TopLogPanel extends StatelessWidget {
  final LogMixin controller;
  final String title;
  final bool? enableCopy;
  final bool? enableAutoScroll;
  final bool? enableClear;
  final bool? enableCollapse;
  final Widget? bottomChild;

  const TopLogPanel({
    super.key,
    required this.controller,
    required this.title,
    this.enableCopy,
    this.enableAutoScroll,
    this.enableClear,
    this.enableCollapse,
    this.bottomChild,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppMetrics.gapSmall),
      clip: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(title, style: AppText.sectionTitle),
                  const Spacer(),
                  if (enableAutoScroll ?? true) _autoScrollButton(),
                  if (enableCopy ?? true) _copyButton(),
                  if (enableClear ?? true) _deleteButton(),
                  if (enableCollapse ?? true) _collapseButton(),
                ],
              ),
            ),
          ),
          if (bottomChild != null) ...[
            const AppDivider(),
            bottomChild!,
          ],
        ],
      ),
    );
  }

  Widget _copyButton() {
    return AppIconButton(
      icon: const Icon(Icons.content_copy_rounded, size: 13),
      size: 24,
      tooltip: I18n.copy_success.tr,
      onPressed: controller.copyLogs,
    );
  }

  Widget _autoScrollButton() {
    return Obx(() => AppIconButton(
          icon: Icon(
            controller.autoScroll.value
                ? Icons.flash_on_rounded
                : Icons.flash_off_rounded,
            size: 14,
          ),
          size: 24,
          selected: controller.autoScroll.value,
          onPressed: controller.toggleAutoScroll,
        ));
  }

  Widget _deleteButton() {
    return AppIconButton(
      icon: const Icon(Icons.delete_outline_rounded, size: 14),
      size: 24,
      tooltip: I18n.clear_log.tr,
      onPressed: controller.clearLog,
    );
  }

  Widget _collapseButton() {
    return Obx(() => AppIconButton(
          icon: Icon(
            controller.collapseLog.value
                ? Icons.expand_more_rounded
                : Icons.expand_less_rounded,
            size: 16,
          ),
          size: 24,
          onPressed: controller.toggleCollapse,
        ));
  }
}

/// 日志内容区
class LogContent extends StatelessWidget {
  final LogMixin controller;
  final ScrollController scrollController;
  final Function() onUserScroll;

  const LogContent({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.onUserScroll,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppMetrics.gapSmall),
      clip: true,
      child: Container(
        constraints: const BoxConstraints.expand(),
        child: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            onUserScroll();
            return false;
          },
          child: Obx(() => ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(10),
                itemCount: controller.logs.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: SelectableText(
                    controller.logs[index],
                    maxLines: 1,
                    style: AppText.mono,
                  ),
                ),
              )),
        ),
      ),
    );
  }
}
