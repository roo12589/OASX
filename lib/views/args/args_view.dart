library args;

// import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:get/get.dart';
import 'dart:async';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/args/args_controller.dart';
import 'package:oasx/views/common/app_widgets.dart';

part './group_view.dart';
part './date_time_picker.dart';

/// 行内控件统一宽度
const double _argControlWidth = 200;

/// 参数配置页：暗色玻璃面板风格
class Args extends StatelessWidget {
  const Args({Key? key}) : super(key: key);

  /// 页面内容最大宽度，超出后居中留白
  static const double _maxContentWidth = 760;

  @override
  Widget build(BuildContext context) {
    return GetX<ArgsController>(builder: (controller) {
      final names = controller.groupsName.value;
      final total = names.fold<int>(
        0,
        (sum, name) =>
            sum + (controller.groupsData.value[name]?.members.length ?? 0),
      );
      return ColoredBox(
        color: AppColors.bg,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const hPad = AppMetrics.pagePadding;
            const vPad = AppMetrics.pagePadding;
            final available = constraints.maxWidth - hPad * 2;
            final width =
                available.clamp(0.0, _maxContentWidth).toDouble();
            final minHeight = constraints.maxHeight.isFinite
                ? (constraints.maxHeight - vPad * 3).clamp(0.0, double.infinity)
                : 0.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad * 2),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: names.isEmpty
                        ? const _ArgsEmptyView()
                        : _content(controller, names, total),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _content(
      ArgsController controller, List<String> names, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(total),
        for (final name in names)
          ArgsGroupPanel(
            key: ValueKey<String>('args-group-$name'),
            groupName: name,
          ),
      ],
    );
  }

  Widget _header(int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 极窄窗口下隐藏数量 chip，并给标题留出可压缩的宽度，避免 RenderFlex 溢出
        final showChip = constraints.maxWidth >= 200;
        final titleMaxWidth = (constraints.maxWidth - (showChip ? 150 : 40))
            .clamp(0.0, double.infinity);
        return AppPanel(
          margin: const EdgeInsets.only(bottom: AppMetrics.gap),
          padding: const EdgeInsets.symmetric(
            horizontal: AppMetrics.panelPadding,
            vertical: 11,
          ),
          child: AppSectionHeader(
            title: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: titleMaxWidth),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3,
                    height: 15,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      I18n.task_setting.tr,
                      style: AppText.pageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            subtitle: showChip
                ? AppChip(
                    label: '$total',
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    background: AppColors.panelHi,
                    textStyle: AppText.caption,
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// 空状态（未加载 / 无分组）
class _ArgsEmptyView extends StatelessWidget {
  const _ArgsEmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: AppRadius.cardR,
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppMetrics.gap),
          Text(I18n.no_data.tr, style: AppText.label),
        ],
      ),
    );
  }
}

class ArgumentView extends StatefulWidget {
  final void Function(String? config, String? task, String? group,
      String argument, String type, dynamic value) setArgument;
  final String Function() getGroupName;
  final int index;

  const ArgumentView(
      {required this.setArgument,
      required this.getGroupName,
      required this.index,
      Key? key})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ArgumentViewState createState() => _ArgumentViewState();
}

class _ArgumentViewState extends State<ArgumentView> {
  Timer? timer;

  ArgumentModel get model {
    ArgsController controller = Get.find();
    GroupsModel? groupsModel =
        controller.groupsData.value[widget.getGroupName()];
    return groupsModel!.members[widget.index];
  }

  @override
  Widget build(BuildContext context) {
    return AppHoverRow(
      padding: const EdgeInsets.symmetric(
        horizontal: AppMetrics.panelPadding,
        vertical: 9,
      ),
      radius: 0,
      hoverColor: AppColors.panelHi,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 先算出本行可用的控件宽度，空间足够时固定 200
          final controlWidth = constraints.maxWidth < _argControlWidth
              ? constraints.maxWidth
              : _argControlWidth;
          // 窗口很窄时改为上下两段，避免固定宽度的控件把行挤爆
          if (constraints.maxWidth < _argControlWidth + 96) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(),
                const SizedBox(height: AppMetrics.gapSmall),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: controlWidth,
                    child: _form(),
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _title()),
              const SizedBox(width: 16),
              SizedBox(
                width: controlWidth,
                child: _form(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _title() {
    final description = model.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model.title.tr,
          style: AppText.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            description.tr,
            style: AppText.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _form() {
    return switch (model.type) {
      "boolean" => Align(
          alignment: Alignment.centerLeft,
          child: _checkbox(),
        ),
      "string" => _textField(onChanged: onStringChanged),
      "multi_line" => _textField(onChanged: onStringChanged, multiline: true),
      "number" => _textField(
          onChanged: onNumberChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[-0-9.]')),
          ],
        ),
      "integer" => _textField(
          onChanged: onIntegerChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[-0-9]')),
          ],
        ),
      "enum" => _enumDropdown(),
      "date_time" => DateTimePicker(
          value: model.value,
          onChange: onDateTimeChanged,
        ),
      "time_delta" => TimeDeltaPicker(
          value: ensureTimeDeltaString(model.value),
          onChange: onTimeDeltaChanged,
        ),
      "time" => TimePicker(
          value: model.value,
          onChange: onTimeChanged,
        ),
      _ => Text(
          '${model.value ?? ''}',
          style: AppText.mono.copyWith(color: AppColors.textPrimary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        )
    };
  }

  Widget _checkbox() {
    return Checkbox(
      value: model.value == true,
      onChanged: onCheckboxChanged,
      activeColor: AppColors.accent,
      checkColor: const Color(0xFF06231A),
      side: const BorderSide(color: AppColors.borderStrong, width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _textField({
    required void Function(String?) onChanged,
    bool multiline = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      initialValue: '${model.value ?? ''}',
      style: AppText.body,
      keyboardType: multiline ? TextInputType.multiline : keyboardType,
      textInputAction:
          multiline ? TextInputAction.newline : TextInputAction.done,
      maxLines: multiline ? null : 1,
      minLines: 1,
      inputFormatters: inputFormatters,
      onChanged: (value) {
        timer?.cancel();
        timer = Timer(
          const Duration(milliseconds: 1000),
          () => onChanged(value),
        );
      },
    );
  }

  Widget _enumDropdown() {
    final items = model.enumEnum ?? const <String>[];
    final current = model.value?.toString();
    final value = items.contains(current) ? current : null;
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 10, right: 6),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: AppRadius.chipR,
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(AppRadius.card),
          dropdownColor: AppColors.panelHi,
          menuMaxHeight: 320,
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
          style: AppText.body,
          items: items
              .map<DropdownMenuItem<String>>((e) => DropdownMenuItem(
                    value: e.toString(),
                    child: Text(
                      e.toString().tr,
                      style: AppText.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onEnumChanged,
        ),
      ),
    );
  }

  void onCheckboxChanged(bool? value) {
    setState(() {
      widget.setArgument(
          "", "", widget.getGroupName(), model.title, 'boolean', value);
      model.value = value;
    });
    showSnakbar(value);
  }

  void onStringChanged(String? value) {
    widget.setArgument(
        "", "", widget.getGroupName(), model.title, 'string', value);
    showSnakbar(value);
  }

  void onNumberChanged(String? value) {
    widget.setArgument(
        "", "", widget.getGroupName(), model.title, 'number', value);
    showSnakbar(value);
  }

  void onIntegerChanged(String? value) {
    widget.setArgument(
        "", "", widget.getGroupName(), model.title, 'integer', value);
    showSnakbar(value);
  }

  void onEnumChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(
          "", "", widget.getGroupName(), model.title, 'enum', value);
    });
    showSnakbar(value);
  }

  void onDateTimeChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(
          "", "", widget.getGroupName(), model.title, 'date_time', value);
    });
    showSnakbar(value);
  }

  void onTimeDeltaChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(
          "", "", widget.getGroupName(), model.title, 'time_delta', value);
    });
    showSnakbar(value);
  }

  void onTimeChanged(String? value) {
    setState(() {
      model.value = value;
      widget.setArgument(
          "", "", widget.getGroupName(), model.title, 'time', value);
    });
    showSnakbar(value);
  }

// -----------------------------------------------------------------------------
  void showSnakbar(dynamic value) {
    Get.snackbar(
      I18n.setting_saved.tr,
      "$value",
      duration: const Duration(seconds: 1),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(AppMetrics.gap),
      backgroundColor: AppColors.panelHi,
      colorText: AppColors.textPrimary,
      borderRadius: AppRadius.card,
      borderColor: AppColors.borderStrong,
      borderWidth: 1,
      boxShadows: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    );
  }
}
