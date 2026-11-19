import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/service/notification_service.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 工具页：原有功能（服务端消息推送测试）+ 新增「系统通知」分区。
///
/// 系统通知分区包含：
/// - 总开关（异常时是否弹原生系统通知）→ [NotificationService.enabled]
/// - 手动测试按钮 → 无视开关强制发一条，用于确认原生能力真的可用
class ToolView extends StatelessWidget {
  const ToolView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppMetrics.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SystemNotifySection(),
          SizedBox(height: AppMetrics.gap),
          NotifyTest(),
        ],
      ),
    );
  }
}

/// 系统通知开关分区
class _SystemNotifySection extends StatelessWidget {
  const _SystemNotifySection();

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationService>()) {
      return const SizedBox.shrink();
    }
    final service = Get.find<NotificationService>();
    final supported = NotificationService.isSupported;
    return Obx(() {
      final enabled = service.enabled.value;
      return AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  size: 15,
                  color: supported ? AppColors.accent : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Text(I18n.system_notify.tr, style: AppText.sectionTitle),
                const Spacer(),
                if (!supported)
                  Text(
                    I18n.system_notify_unsupported.tr,
                    style: AppText.caption.copyWith(color: AppColors.warning),
                  ),
                const SizedBox(width: 6),
                Switch.adaptive(
                  value: supported && enabled,
                  onChanged:
                      supported ? (value) => service.setEnabled(value) : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              supported
                  ? I18n.system_notify_help.tr
                  : I18n.system_notify_unsupported_help.tr,
              style: AppText.caption,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: supported ? () => _test(service) : null,
                  icon: const Icon(Icons.notifications_none_rounded, size: 15),
                  label: Text(I18n.system_notify_test.tr),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: supported
                      ? () => _reportSample(service)
                      : null,
                  icon: const Icon(Icons.bug_report_outlined, size: 15),
                  label: Text(I18n.system_notify_report_error_test.tr),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _test(NotificationService service) async {
    final ok = await service.test(
      title: 'OASX',
      body: I18n.system_notify_test_content.tr,
    );
    Get.snackbar(
      I18n.tip.tr,
      ok ? I18n.system_notify_test_success.tr : I18n.system_notify_test_failed.tr,
      duration: const Duration(seconds: 2),
    );
  }

  /// 用一条仿真异常走完整的「异常上报」链路，验证开关生效
  Future<void> _reportSample(NotificationService service) async {
    await service.reportError(I18n.system_notify_sample_error.tr);
    Get.snackbar(
      I18n.tip.tr,
      service.enabled.value
          ? I18n.system_notify_report_sent.tr
          : I18n.system_notify_report_off.tr,
      duration: const Duration(seconds: 2),
    );
  }
}

/// 原有功能：服务端消息推送测试（保持原有能力不变）
class NotifyTest extends StatefulWidget {
  const NotifyTest({Key? key}) : super(key: key);

  @override
  NotifyTestState createState() => NotifyTestState();
}

class NotifyTestState extends State<NotifyTest> {
  String testConfig = 'provider:';
  String testTitle = 'Title';
  String testContent = 'Content';

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.send_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text(I18n.notify_test.tr, style: AppText.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          _config(),
          const SizedBox(height: 10),
          _title(),
          const SizedBox(height: 10),
          _content(),
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerLeft, child: _send()),
        ],
      ),
    );
  }

  Widget _config() {
    return TextFormField(
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: null,
        initialValue: testConfig,
        style: AppText.body,
        decoration: InputDecoration(
            labelText: I18n.notify_test_config.tr,
            helperText: I18n.notify_test_help.tr,
            helperMaxLines: 3),
        onChanged: (value) {
          setState(() {
            testConfig = value;
          });
        });
  }

  Widget _title() {
    return TextFormField(
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: null,
        initialValue: testTitle,
        style: AppText.body,
        decoration: InputDecoration(
          labelText: I18n.notify_test_title.tr,
        ),
        onChanged: (value) {
          setState(() {
            testTitle = value;
          });
        });
  }

  Widget _content() {
    return TextFormField(
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: null,
        initialValue: testContent,
        style: AppText.body,
        decoration: InputDecoration(
          labelText: I18n.notify_test_content.tr,
        ),
        onChanged: (value) {
          setState(() {
            testContent = value;
          });
        });
  }

  Widget _send() {
    return FilledButton.icon(
      onPressed: () {
        ApiClient().notifyTest(testConfig, testTitle, testContent);
      },
      icon: const Icon(Icons.send_rounded, size: 15),
      label: Text(I18n.notify_test_send.tr),
    );
  }
}
