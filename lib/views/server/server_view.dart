library server;

import 'dart:io';

import 'package:code_editor/code_editor.dart';
import 'package:expansion_tile_group/expansion_tile_group.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:process_run/shell.dart';

import 'package:oasx/component/log/log_mixin.dart';
import 'package:oasx/component/log/log_widget.dart';
import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/settings.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/layout/appbar.dart';

part './deploy_view.dart';
part '../../controller/server/server_controller.dart';

class ServerView extends StatelessWidget {
  const ServerView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: buildPlatformAppBar(context, isCollapsed: false),
      floatingActionButton: startServerButton(),
      body: _body(),
    );
  }

  Widget _body() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        ServerController serverController = Get.find<ServerController>();
        // 面板内代码编辑器与日志区高度：随窗口高度自适应，保证 1200x800 不溢出。
        // CodeEditor 自身高度 = 导航栏(60) + heightOfContainer，因此这里减去 60。
        final double codeHeight =
            (constraints.maxHeight - 150).clamp(240.0, 440.0);
        final double logHeight =
            (constraints.maxHeight - 430).clamp(200.0, 460.0);
        return SingleChildScrollView(
          // 底部留白，避免右下角的启动 FAB 遮挡日志区域
          padding: const EdgeInsets.fromLTRB(
            AppMetrics.pagePadding,
            AppMetrics.pagePadding,
            AppMetrics.pagePadding,
            76,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPanel(
                child: ExpansionTileGroup(
                  toggleType: ToggleType.expandOnlyCurrent,
                  spaceBetweenItem: 8,
                  children: [
                    path(context),
                    deploy(codeHeight),
                  ],
                ),
              ),
              const SizedBox(height: AppMetrics.gap),
              // LogWidget 自带 AppPanel 容器，这里只约束高度，避免双层面板。
              SizedBox(
                height: logHeight,
                child: LogWidget(
                  key: ValueKey(serverController.hashCode),
                  controller: serverController,
                  title: I18n.setup_log.tr,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ExpansionTileItem path(BuildContext context) {
    Widget path = GetX<ServerController>(builder: (controller) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.rootPathServer.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: OutlinedButton.icon(
                style: _outlinedStyle(),
                onPressed: () async {
                  String? selectedDirectory =
                      await FilePicker.platform.getDirectoryPath();
                  if (selectedDirectory == null) {
                    // User canceled the picker
                    return;
                  }
                  controller.updateRootPathServer(selectedDirectory);
                },
                icon: const Icon(Icons.folder_open_rounded, size: 15),
                label: Text(I18n.select_root_path_server.tr),
              ),
            ),
          ],
        ),
      );
    });
    Widget pass = GetX<ServerController>(builder: (controller) {
      final bool ok = controller.rootPathAuthenticated.value;
      // 作为 AppSectionHeader.subtitle 使用：外层 Row 给的是无界宽度，
      // 因此这里必须先由 ConstrainedBox 提供有界宽度，Flexible 才能安全使用。
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              size: 14,
              color: ok ? AppColors.accent : AppColors.danger,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                ok ? I18n.root_path_correct.tr : I18n.root_path_incorrect.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: ok ? AppColors.accent : AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      );
    });

    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      backgroundColor: AppColors.panelSoft,
      collapsedBackgroundColor: AppColors.panelSoft,
      textColor: AppColors.textPrimary,
      collapsedTextColor: AppColors.textPrimary,
      iconColor: AppColors.textSecondary,
      collapsedIconColor: AppColors.textSecondary,
      border: Border.all(color: AppColors.borderSoft),
      collapsedBorderColor: AppColors.borderSoft,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
      trailingIcon: const Icon(Icons.expand_more_rounded, size: 18),
      title: AppSectionHeader(
        title: Text(I18n.root_path_server.tr),
        subtitle: pass,
      ),
      children: [
        path,
        Text(
          I18n.root_path_server_help.tr,
          style: AppText.caption,
        ),
      ],
    );
  }

  ExpansionTileItem deploy(double codeHeight) {
    return ExpansionTileItem(
      initiallyExpanded: false,
      isHasTopBorder: false,
      isHasBottomBorder: false,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      backgroundColor: AppColors.panelSoft,
      collapsedBackgroundColor: AppColors.panelSoft,
      textColor: AppColors.textPrimary,
      collapsedTextColor: AppColors.textPrimary,
      iconColor: AppColors.textSecondary,
      collapsedIconColor: AppColors.textSecondary,
      border: Border.all(color: AppColors.borderSoft),
      collapsedBorderColor: AppColors.borderSoft,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.card)),
      trailingIcon: const Icon(Icons.expand_more_rounded, size: 18),
      title: AppSectionHeader(
        title: Text(I18n.setup_deploy.tr),
        actions: [
          Icon(
            Icons.code_rounded,
            size: 15,
            color: AppColors.textMuted,
          ),
        ],
      ),
      children: [
        // 编辑器在“编辑态”会额外出现工具栏，用滚动兜底避免溢出。
        SizedBox(
          height: codeHeight,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: SingleChildScrollView(
              child: code(codeHeight - 60),
            ),
          ),
        ),
      ],
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      backgroundColor: AppColors.panelHi,
      side: BorderSide(color: AppColors.border),
      textStyle: const TextStyle(fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
    );
  }

  Widget startServerButton() {
    return GetX<ServerController>(builder: (controller) {
      if (controller.rootPathAuthenticated.value) {
        return FloatingActionButton(
          heroTag: 'START_SERVER',
          elevation: 0,
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF06231A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          onPressed: () {
            controller.run();
          },
          child: const Icon(Icons.auto_mode_rounded),
        );
      } else {
        return const SizedBox.shrink();
      }
    });
  }

  Widget code(double maxHeight) {
    return GetX<ServerController>(builder: (controller) {
      FileEditor file = FileEditor(
        name: "deploy.yaml",
        language: "yaml",
        code: controller.deployContent.value, // [code] needs a string
      );
      EditorModel model = EditorModel(
        files: [file], // the files created above
        styleOptions: EditorModelStyleOptions(
          heightOfContainer: maxHeight < 120 ? 120 : maxHeight,
          fontSize: 12,
          padding: const EdgeInsets.all(12),
          editorColor: AppColors.panelSoft,
          editorBorderColor: AppColors.borderSoft,
          editorFilenameColor: AppColors.accent,
          editorToolButtonColor: AppColors.accentDark,
          editorToolButtonTextColor: AppColors.accent,
          editButtonBackgroundColor: AppColors.panelHi,
          editButtonTextColor: AppColors.textPrimary,
          textStyleOfTextField: AppText.mono.copyWith(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
      );
      return CodeEditor(
        model: model,
        formatters: const ["yaml"],
        onSubmit: (String language, String value) {
          controller.writeDeploy(value);
        },
      );
    });
  }
}
