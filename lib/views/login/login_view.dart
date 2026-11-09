library login;

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/model/const/storage_key.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/views/common/app_widgets.dart';
import 'package:oasx/views/layout/appbar.dart';

part './login_binding.dart';
part '../../controller/login/login_controller.dart';

class LoginView extends StatelessWidget {
  LoginView({Key? key}) : super(key: key);
  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: buildPlatformAppBar(context, isCollapsed: false),
      floatingActionButton: PlatformUtils.isWindows ? _serverButton() : null,
      body: _login(context),
    );
  }

  Widget _login(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgDeep, AppColors.bg],
        ),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double minHeight = constraints.maxHeight - 48 > 0
              ? constraints.maxHeight - 48
              : 0;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: AppPanel(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _brand(),
                          const SizedBox(height: 26),
                          _address(),
                          const SizedBox(height: 14),
                          _username(),
                          const SizedBox(height: 14),
                          _password(),
                          const SizedBox(height: 26),
                          _signin(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _brand() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          child: Image.asset(
            'assets/images/Icon-app.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'OASX',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          I18n.project_statement.tr,
          textAlign: TextAlign.center,
          style: AppText.label,
        ),
      ],
    );
  }

  Widget _username() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'username',
      initialValue: loginController.username.value,
      style: AppText.body,
      decoration: const InputDecoration(
        labelText: 'Username',
        prefixIcon: Icon(Icons.person_outline_rounded, size: 16),
        prefixIconConstraints: BoxConstraints(minWidth: 38, minHeight: 38),
      ),
    );
  }

  Widget _password() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'password',
      initialValue: loginController.password.value,
      style: AppText.body,
      decoration: const InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outline_rounded, size: 16),
        prefixIconConstraints: BoxConstraints(minWidth: 38, minHeight: 38),
      ),
      obscureText: true,
    );
  }

  Widget _address() {
    LoginController loginController = Get.find<LoginController>();
    return FormBuilderTextField(
      name: 'address',
      initialValue: loginController.address.value,
      style: AppText.body,
      decoration: const InputDecoration(
        labelText: 'Address',
        prefixIcon: Icon(Icons.dns_outlined, size: 16),
        prefixIconConstraints: BoxConstraints(minWidth: 38, minHeight: 38),
      ),
    );
  }

  Widget _signin() {
    LoginController loginController = Get.find<LoginController>();
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF06231A),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        onPressed: () async {
          if (_formKey.currentState?.saveAndValidate() ?? false) {
            await loginController.toMain(data: _formKey.currentState!.value);
          }
        },
        child: Text(I18n.login.tr),
      ),
    );
  }

  Widget _serverButton() {
    return FloatingActionButton(
      heroTag: 'SERVER',
      elevation: 0,
      backgroundColor: AppColors.panelHi,
      foregroundColor: AppColors.accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: const Icon(Icons.developer_board_rounded, size: 18),
      onPressed: () {
        Get.toNamed('/server');
      },
    );
  }
}
