import 'package:flutter/material.dart';

import 'package:oasx/config/design/app_theme.dart';

/// 右侧资产面板的展示模型。
///
/// 注意：这里的数据目前是**占位数据**，用于先把界面结构做出来。
/// 需求明确要求暂不接入游戏资源的提取/检测，所以不要在这里接 OCR 或游戏数据。
class AssetItemModel {
  const AssetItemModel({
    required this.nameKey,
    required this.value,
    required this.icon,
    required this.color,
    this.delta,
    this.deltaPositive = true,
  });

  /// i18n key 或已经是可显示文本
  final String nameKey;
  final String value;
  final IconData icon;
  final Color color;

  /// 变化量，如 "+72万" / "1-15"
  final String? delta;
  final bool deltaPositive;

  static const List<AssetItemModel> placeholders = [
    AssetItemModel(
        nameKey: '金币',
        value: '5412.3万',
        icon: Icons.monetization_on_rounded,
        color: AppColors.assetGold,
        delta: '+72万'),
    AssetItemModel(
        nameKey: '体力',
        value: '4.97万',
        icon: Icons.local_fire_department_rounded,
        color: AppColors.assetAp,
        delta: '+138'),
    AssetItemModel(
        nameKey: '勾玉',
        value: '1.87万',
        icon: Icons.circle,
        color: AppColors.assetJade,
        delta: '1-15',
        deltaPositive: false),
    AssetItemModel(
        nameKey: '神秘的符咒',
        value: '122',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.assetBlue,
        delta: '+4'),
    AssetItemModel(
        nameKey: '御行达摩',
        value: '4',
        icon: Icons.egg_alt_rounded,
        color: AppColors.assetPurple),
    AssetItemModel(
        nameKey: '御行达摩碎片',
        value: '191',
        icon: Icons.egg_outlined,
        color: AppColors.textSecondary,
        delta: '+4'),
    AssetItemModel(
        nameKey: '现世符咒',
        value: '3',
        icon: Icons.style_rounded,
        color: AppColors.assetPurple),
    AssetItemModel(
        nameKey: '魂玉',
        value: '9',
        icon: Icons.wb_incandescent_rounded,
        color: AppColors.assetPurple),
    AssetItemModel(
        nameKey: '大蛇的逆鳞',
        value: '1973',
        icon: Icons.shield_moon_rounded,
        color: AppColors.assetRed),
    AssetItemModel(
        nameKey: '逢魔之魂',
        value: '1244',
        icon: Icons.whatshot_rounded,
        color: AppColors.assetAp),
    AssetItemModel(
        nameKey: '御灵境之钥',
        value: '2658',
        icon: Icons.vpn_key_rounded,
        color: AppColors.assetGold,
        delta: '+3'),
    AssetItemModel(
        nameKey: '百鬼夜行门票',
        value: '4163',
        icon: Icons.confirmation_number_rounded,
        color: AppColors.assetBlue,
        delta: '+3'),
    AssetItemModel(
        nameKey: '荣誉',
        value: '6570',
        icon: Icons.workspace_premium_rounded,
        color: AppColors.assetTeal),
    AssetItemModel(
        nameKey: '勋章',
        value: '8.43万',
        icon: Icons.military_tech_rounded,
        color: AppColors.assetGold),
    AssetItemModel(
        nameKey: '功勋',
        value: '1.21万',
        icon: Icons.hexagon_rounded,
        color: AppColors.assetAp,
        delta: '1-890',
        deltaPositive: false),
    AssetItemModel(
        nameKey: '绘卷碎片·大',
        value: '0',
        icon: Icons.collections_bookmark_rounded,
        color: AppColors.textMuted),
    AssetItemModel(
        nameKey: '绘卷碎片·中',
        value: '0',
        icon: Icons.collections_bookmark_outlined,
        color: AppColors.textMuted),
    AssetItemModel(
        nameKey: '绘卷碎片·小',
        value: '0',
        icon: Icons.layers_rounded,
        color: AppColors.textMuted),
  ];
}
