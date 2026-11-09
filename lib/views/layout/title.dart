import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/controller/ctrl_nav.dart';
import 'package:oasx/config/translation/i18n_content.dart';

/// 标题栏左侧：Logo + OASX + 当前脚本
Widget getTitle() {
  var routePath = Get.currentRoute;
  return switch (routePath) {
    '/main' => const MainTitleBar(),
    '/login' => const LoginTitle(),
    '/settings' => const SettingTitle(),
    '/server' => const ServerTitle(),
    _ => const SettingTitle(),
  };
}

class MainTitleBar extends StatelessWidget {
  const MainTitleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NavCtrl>()) {
      return const _BaseTitle(text: '');
    }
    return GetX<NavCtrl>(builder: (controller) {
      final name = controller.selectedScript.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Image.asset(
              'assets/images/Icon-app.png',
              width: 26,
              height: 26,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'OASX',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 18, color: AppColors.border),
          const SizedBox(width: 10),
          Text(
            name == 'Home' ? 'Home' : name,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    });
  }
}

/// 通用标题基座：Logo + 文本
class _BaseTitle extends StatelessWidget {
  const _BaseTitle({
    required this.text,
    this.showBack = false,
    this.onBack,
  });

  final String text;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBack)
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            onPressed: onBack ?? () => Get.offAllNamed(Get.previousRoute),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset(
            'assets/images/Icon-app.png',
            width: 26,
            height: 26,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'OASX',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 10),
        Container(width: 1, height: 18, color: AppColors.border),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class LoginTitle extends StatelessWidget {
  const LoginTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _BaseTitle(text: I18n.login.tr);
  }
}

class SettingTitle extends StatelessWidget {
  const SettingTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showBack = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return _BaseTitle(
      text: I18n.setting.tr,
      showBack: showBack,
      onBack: () => Get.offAllNamed('/main'),
    );
  }
}

class ServerTitle extends StatelessWidget {
  const ServerTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final showBack = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return _BaseTitle(
      text: 'Server',
      showBack: showBack,
      onBack: () => Get.back(),
    );
  }
}
