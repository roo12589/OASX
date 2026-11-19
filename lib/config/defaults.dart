/// 全局默认外观：亮色。
///
/// 需求要求「添加亮色主题并设置为默认」，所以首次启动是亮色，
/// 用户切换后会被 [StorageKey.dark] 覆盖。
const bool kDefaultDarkMode = false;

/// 默认隐藏游戏资源检测相关的 UI（资产面板）。
///
/// 需求要求「支持隐藏资源检测相关内容并调整界面，默认隐藏」。
/// 资源检测本身尚未实现，这里只是把占位面板的显示开关关掉。
const bool kDefaultShowAssetsPanel = false;
