import 'dart:convert';

import 'package:get/get.dart';

import 'package:oasx/api/api_client.dart';
import 'package:oasx/controller/ctrl_nav.dart';

/// 参数配置控制器：加载任务的参数分组并回写
class ArgsController extends GetxController {
  final groups = Rx<List<GroupsModel>>([]);
  final groupsName = Rx<List<String>>([]);
  final groupsData = Rx<Map<String, GroupsModel>>({});

  void loadModel(Map<String, dynamic> json) {
    groups.value = [];
    json.forEach((key, value) {
      groups.value.add(GroupsModel(groupName: key, members: value));
    });
  }

  void loadModelfromStr(String json) {
    loadModel(jsonDecode(json));
  }

  /// 加载 groups 数据
  Future<void> loadGroups({String config = "", String task = ""}) async {
    groupsName.value = [];
    groupsData.value = {};
    final groupsNameTemp = <String>[];

    final json = await ApiClient().getScriptTask(config, task);
    for (final entry in json.entries) {
      groupsNameTemp.add(entry.key);
      final arguments = <ArgumentModel>[];
      for (final argument in entry.value) {
        arguments.add(ArgumentModel.fromJson(argument));
      }
      groupsData.value[entry.key] =
          GroupsModel(groupName: entry.key, members: arguments);
    }
    groupsName.value = groupsNameTemp;
  }

  Future<void> setArgument(String? config, String? task, String? group,
      String argument, String type, dynamic value) async {
    if (config == null || task == null || group == null) return;
    if (config.isEmpty || task.isEmpty || group.isEmpty) {
      final NavCtrl navCtrl = Get.find<NavCtrl>();
      config = navCtrl.selectedScript.value;
      task = navCtrl.selectedMenu.value;
    }
    await ApiClient().putScriptArg(config, task, group, argument, type, value);
    printInfo(
        info:
            'setArgument config: $config, task: $task, group: $group, argument: $argument, value: $value');
  }
}

class GroupsModel {
  final String groupName;
  List<dynamic> members;

  GroupsModel({required this.groupName, required this.members});

  String getGroupName() => groupName;
}

class ArgumentModel {
  final String title;
  dynamic value;
  final String type;
  final String? description;
  final List<String>? enumEnum;
  final dynamic minimum;
  final dynamic maximum;
  final dynamic defaultValue;

  ArgumentModel(
    this.enumEnum,
    this.minimum,
    this.maximum,
    this.defaultValue,
    this.description, {
    required this.title,
    required this.value,
    required this.type,
  });

  factory ArgumentModel.fromJson(Map<String, dynamic> json) {
    return ArgumentModel(
      List<String>.from(json["enumEnum"]?.map((x) => x) ?? []),
      json['minimum'],
      json['maximum'],
      json['defaultValue'],
      json['description'],
      title: json['name'] as String,
      value: json['value'],
      type: json['type'] as String,
    );
  }

  set setValue(dynamic newValue) => value = newValue;
}
