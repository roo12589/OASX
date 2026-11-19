import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/controller/settings.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/ui_prefs_service.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/layout/appbar.dart';

/// 设置页：单列居中（最大宽 560），四个暗色玻璃分区：
/// 外观主题 / 语言 / OAS 服务 / 账号。
class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: buildPlatformAppBar(context),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double minHeight =
              constraints.maxHeight - 24 > 0 ? constraints.maxHeight - 24 : 0;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppMetrics.pagePadding,
              vertical: 12,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 560, minHeight: minHeight),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ThemeSection(),
                    SizedBox(height: AppMetrics.gap),
                    _LanguageSection(),
                    _AssetsSection(),
                    SizedBox(height: AppMetrics.gap),
                    _ServerSection(),
                    SizedBox(height: AppMetrics.gap),
                    _AccountSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 两段式分段控件（主题 / 语言共用）
class _Segmented extends StatelessWidget {
  const _Segmented({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.panelSoft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 分段控件中的一段
class _Segment extends StatelessWidget {
  const _Segment({
    required this.selected,
    required this.onTap,
    required this.label,
  });

  final bool selected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color tint = selected ? AppColors.accent : AppColors.textSecondary;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.panelHi : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip - 3),
            border: Border.all(
              color: selected ? AppColors.borderStrong : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: tint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 面板底部的整行操作按钮
class _PanelActionButton extends StatelessWidget {
  const _PanelActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foreground,
    this.background,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? foreground;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground ?? AppColors.textPrimary,
          backgroundColor: background ?? AppColors.panelSoft,
          side: BorderSide(color: borderColor ?? AppColors.border, width: 1),
          textStyle:
              const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// 分区外壳：统一的标题行 + 主体
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: Text(title),
            actions: actions,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection();

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    return Obx(() {
      final isDark = themeService.isDarkMode;
      return _Section(
        title: I18n.change_theme.tr,
        actions: [
          Icon(Icons.palette_outlined, size: 15, color: AppColors.textMuted),
        ],
        child: Align(
          alignment: Alignment.centerLeft,
          child: _Segmented(
            children: [
              _Segment(
                selected: !isDark,
                label: I18n.theme_light.tr,
                onTap: () => themeService.switchTheme(false),
              ),
              _Segment(
                selected: isDark,
                label: I18n.theme_dark.tr,
                onTap: () => themeService.switchTheme(true),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// 资源检测（资产面板）显隐 —— 默认隐藏
class _AssetsSection extends StatelessWidget {
  const _AssetsSection();

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<UiPrefsService>();
    return Obx(
      () => _Section(
        title: I18n.assets.tr,
        actions: [
          Icon(Icons.dashboard_customize_outlined,
              size: 15, color: AppColors.textMuted),
        ],
        child: Row(
          children: [
            Expanded(
              child: Text(
                I18n.show_assets.tr,
                style: AppText.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Switch.adaptive(
              value: prefs.showAssetsPanel.value,
              onChanged: prefs.setShowAssetsPanel,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final localeService = Get.find<LocaleService>();

    return Obx(() {
      final bool isEn = localeService.language.value == 'en-US';
      return _Section(
        title: I18n.change_language.tr,
        actions: [
          Icon(Icons.translate_rounded, size: 15, color: AppColors.textMuted),
        ],
        child: Align(
          alignment: Alignment.centerLeft,
          child: _Segmented(
            children: [
              _Segment(
                selected: !isEn,
                label: I18n.zh_cn.tr,
                onTap: () => localeService.switchLanguage('zh-CN'),
              ),
              _Segment(
                selected: isEn,
                label: I18n.en_us.tr,
                onTap: () => localeService.switchLanguage('en-US'),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ServerSection extends StatelessWidget {
  const _ServerSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: I18n.setup_deploy.tr,
      actions: [
        Icon(Icons.dns_outlined, size: 15, color: AppColors.textMuted),
      ],
      child: _PanelActionButton(
        icon: Icons.power_settings_new_rounded,
        label: I18n.kill_oas_server.tr,
        foreground: AppColors.danger,
        background: AppColors.dangerSoft,
        borderColor: AppColors.danger,
        onPressed: _confirmKillServer,
      ),
    );
  }

  void _confirmKillServer() {
    Get.defaultDialog(
      title: I18n.are_you_sure_kill.tr,
      textCancel: I18n.cancel.tr,
      textConfirm: I18n.confirm.tr,
      onCancel: () {},
      onConfirm: () async => await Get.find<SettingsController>().killServer(),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'account'.tr,
      actions: [
        Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textMuted),
      ],
      child: _PanelActionButton(
        icon: Icons.logout_rounded,
        label: I18n.log_out.tr,
        onPressed: () => Get.offAllNamed('/login'),
      ),
    );
  }
}
