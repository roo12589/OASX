# OASX 项目结构与 UI 改造说明

> 本文档记录 OASX（Flutter 全平台 GUI）的代码结构，以及本轮「按设计稿重做 UI」的改动范围与约定。
> 设计目标图为外部提供的参考图，未纳入仓库（不打包游戏美术资源）。

---

## 一、技术栈与运行方式

| 项 | 值 |
| --- | --- |
| 框架 | Flutter（本项目在 **Flutter 3.38.3 / Dart 3.10.1** 上验证通过；README 里写的是 3.27.1） |
| 状态管理 | GetX（`Get.put` / `GetX<T>` / `Obx`） |
| 网络 | dio（经 `flutter_nb_net` 封装）+ `dio_cache_interceptor` |
| 实时通信 | `web_socket_channel`，连 OAS 后端的 `/ws/{script_name}` |
| 本地存储 | `get_storage` |
| 桌面窗口 | `window_manager`（自绘标题栏、无边框窗口） |
| 响应式 | `responsive_builder`（mobile / tablet / desktop） |

构建与运行（Flutter SDK 不在全局 PATH 时用绝对路径）：

```powershell
& 'D:\develop\flutter\bin\flutter.bat' pub get
& 'D:\develop\flutter\bin\flutter.bat' analyze lib
& 'D:\develop\flutter\bin\flutter.bat' test
& 'D:\develop\flutter\bin\flutter.bat' build windows --debug
& 'D:\develop\flutter\bin\flutter.bat' run -d windows
```

OAS 后端默认地址 `127.0.0.1:22288`（登录页可改）。

---

## 二、目录结构

```
lib/
├── main.dart                     # 入口：初始化服务、GetMaterialApp、暗色主题
├── api/
│   ├── api_client.dart           # 所有 HTTP 接口（配置/脚本/参数/翻译）
│   ├── api_interceptor.dart
│   ├── home_model.dart
│   └── update_info_model.dart
├── component/
│   ├── log/
│   │   ├── log_mixin.dart        # 日志缓冲、节流刷新、自动滚动、复制/清空
│   │   └── log_widget.dart       # 通用日志面板（服务端页复用）
│   └── dio_http_cache/           # 内联的 dio 缓存实现
├── config/
│   ├── design/
│   │   └── app_theme.dart        # ★ 设计令牌：AppColors/AppRadius/AppMetrics/AppDecorations/AppText
│   ├── theme.dart                # ★ ThemeData（亮/暗两套，暗色为默认）
│   ├── constants.dart
│   ├── global.dart
│   ├── github_readme.dart
│   └── translation/              # i18n：i18n_content.dart（键）+ i18n_cn/us.dart（值）
├── controller/
│   ├── ctrl_nav.dart             # ★ 顶层导航：脚本标签、二级菜单、配置增删改
│   ├── settings.dart             # 版本号、临时目录、结束 OAS 服务
│   ├── args/args_controller.dart # 参数分组加载与回写
│   ├── overview/overview_controller.dart  # ★ 总览：任务聚合/搜索/调度操作
│   ├── login/login_controller.dart
│   └── server/server_controller.dart
├── model/
│   ├── script_model.dart         # ScriptModel + ScriptState（running/inactive/warning/updating）
│   ├── task_item_model.dart      # ★ 任务项：next_run 解析、timeLabel、dateLabel、isToday
│   ├── asset_model.dart          # ★ 资产面板占位数据
│   └── const/storage_key.dart
├── service/
│   ├── script_service.dart       # ★ 脚本实例管理 + WebSocket 消息分发
│   ├── websocket_service.dart    # WS 客户端（重连、监听器广播）
│   ├── theme_service.dart        # 主题服务（当前固定暗色）
│   ├── locale_service.dart       # 语言切换 + 服务端下发翻译
│   └── window_service.dart       # 窗口尺寸/无边框初始化
├── utils/                        # logger / platform_utils / check_version / yaml_utils ...
└── views/
    ├── routes.dart               # /login /main /settings /server
    ├── common/app_widgets.dart   # ★ 通用组件：AppPanel/AppDivider/AppIconButton/AppChip/AppHoverRow...
    ├── layout/
    │   ├── layout.dart           # 响应式分派
    │   ├── desktop.dart          # 桌面壳（appBar + content）
    │   ├── mobile.dart           # 移动壳（抽屉导航）
    │   ├── appbar.dart           # ★ 自绘标题栏：Logo + 脚本标签 + 窗口按钮
    │   ├── title.dart            # 各路由的标题内容
    │   ├── content.dart          # 内容区路由：总览 / 参数页 / 首页子页
    │   └── binding.dart          # NavCtrl / ArgsController / ScriptService 注入
    ├── overview/                 # ★ 总览页（本轮重点）
    │   ├── overview_view.dart    # 三栏布局编排（桌面）/ 纵向堆叠（移动）
    │   ├── overview_model.dart   # DateBucket / TaskRow / buildDateBuckets
    │   ├── date_distribution_panel.dart
    │   ├── task_list_panel.dart
    │   ├── taskitem_view.dart
    │   ├── overview_banner.dart
    │   └── overview_log_panel.dart
    ├── asset/asset_panel.dart    # 右侧资产面板（占位数据）
    ├── nav/                      # view_nav.dart（移动端图标栏）+ tree_menu_view.dart（二级菜单）
    ├── args/                     # 参数配置页（ExpansionTile → AppPanel 分组）
    ├── login/  settings/  server/
    └── home/                     # Home（README 渲染）/ Updater / Tool
```

---

## 三、设计系统约定

所有 UI 代码**只允许**从设计令牌取色/取字号，禁止硬编码颜色。

```dart
// 背景层级（由暗到亮）
AppColors.bg → AppColors.panel → AppColors.panelSoft → AppColors.panelHi → AppColors.panelHover

// 描边
AppColors.borderSoft（细分割线） → AppColors.border → AppColors.borderStrong

// 文本
AppColors.textPrimary → textSecondary → textMuted

// 强调 / 语义
AppColors.accent（薄荷绿，主操作）
AppColors.danger / warning / info / purple / cyan
```

文本样式一律用 `AppText.*`：`pageTitle` / `sectionTitle` / `body` / `label` / `caption` / `mono` / `number`。

通用容器用 `AppPanel`（圆角 16 + 细描边 + 阴影），列表行 hover 用 `AppHoverRow`，图标按钮用 `AppIconButton`（自带 hover / selected 态）。

### 关键尺寸

| 常量 | 值 | 用途 |
| --- | --- | --- |
| `AppMetrics.titleBarHeight` | 52 | 自绘标题栏高度 |
| `AppMetrics.pagePadding` | 12 | 页面四周留白 |
| `AppMetrics.gap` | 12 | 面板间距 |
| `AppRadius.panel` | 16 | 面板圆角 |
| `AppRadius.card` | 12 | 次级卡片圆角 |

---

## 四、总览页布局（对齐设计稿）

```
┌──────────────────────────────────────────────────────────────────────────┐
│ [Logo] OASX │ 脚本名          [oas1 ⏻][oas2 ⏻]... [+]   [🎨][⚙][—][□][✕] │  ← appbar
├────────────────┬──────────────────────────────┬──────────────────────────┤
│ 任务日期分布    │  横幅（脚本名 + START/ONCE）   │  资产                    │
│ 今天 19 | 周二…│                              │  ┌────────┬────────┐    │
├────────────────┤  ┌────────────────────────┐  │  │ 金币    │ 体力    │    │
│ 任务  其余 18项 │  │ 日志 运行日志 错误日志2 │  │  ├────────┼────────┤    │
│ ┌────────────┐ │  │ 任务统计        [⚡][⧉][🗑]│  │  │ 勾玉    │ 符咒    │    │
│ │00:35 结界蹭卡│ │  ├────────────────────────┤  │  └────────┴────────┘    │
│ │01:00 百鬼棋局│ │  │ 00:33:15 INFO ...      │  │                        │
│ └────────────┘ │  │ 00:33:15 INFO ...      │  │  18 项 · 每日 23:55 ...  │
└────────────────┴──┴────────────────────────┴──┴──────────────────────────┘
```

- **左栏**：`DateDistributionPanel`（今天 + 未来 7 天，每格显示任务数，今天用浅绿底）+ `TaskListPanel`（时间徽章、任务名、常驻操作按钮：立即运行 / 置顶 / 置底 / 参数）。
  - 时间徽章对非今天任务额外显示 `MM-DD`，过期任务显示红色边框。
  - 点击任意任务行 = 打开该任务的参数页。
- **中栏**：`OverviewBanner`（脚本名 + 调度器状态 + START/ONCE，背景为程序化绘制的青色光晕，不引入游戏立绘）+ `OverviewLogPanel`（四个 Tab：日志 / 运行日志 / 错误日志 / 任务统计，带行级 INFO/WARNING/ERROR 着色）。
- **右栏**：`AssetPanel`，2 列网格 18 个资产格。**数据为占位**，见下节。
- 宽度不足时按 `1120 / 780` 两个阈值隐藏右栏、左栏，保证中栏日志可用；竖屏改为纵向堆叠滚动。

---

## 五、明确未做的事（重要）

按需求「先调整原有 UI，不要添加资源的提取检测」：

- **资产面板是纯占位数据**，定义在 `lib/model/asset_model.dart` 的 `AssetItemModel.placeholders`，**没有**接入 OCR、截图识别或游戏数据读取。面板右下角有 `I18n.assets_placeholder_tip` 提示。后续接数据时只需替换 `AssetPanel` 的数据源。
- 横幅背景用 `CustomPainter` 程序化绘制，**不打包任何游戏立绘/截图**。设计参考图不纳入仓库。
- 主题**固定暗色**：`ThemeService.themeMode` 恒为 `ThemeMode.dark`。亮色主题未适配，设置页的主题区显示为只读的 "Dark" 标签，避免出现「暗色面板 + 亮色输入框」的混搭。若要支持亮色，需把 `AppColors` 改成随主题切换的调色板，而不是只切 `ThemeData`。
- `DevicePreview` 默认关闭（`lib/main.dart` 的 `kDevicePreviewEnabled = false`），它会给桌面窗口套一层模拟设备外框，妨碍按设计稿调尺寸。

---

## 六、数据流

```
OAS 后端 (127.0.0.1:22288)
   │
   ├── HTTP ──► ApiClient ──► NavCtrl(配置列表/菜单) / ArgsController(参数) / SettingsController
   │
   └── WS /ws/{script}
          │  {"state": 1}                → ScriptModel.state
          │  {"schedule": {...}}         → runningTask / pendingTaskList / waitingTaskList
          │  纯文本日志行                 → OverviewController.addLog()
          ▼
     ScriptService.wsListener ──► ScriptService.scriptModelMap
                                        │
                                        ▼
                              OverviewController（聚合/搜索/排序）
                                        │
                                        ▼
                     DateDistributionPanel / TaskListPanel / OverviewBanner / LogPanel
```

- 任务时间来自 `schedule` 消息里每个任务的 `next_run`（格式 `YYYY-MM-DD HH:MM:SS`，可能带时区）。
- `buildDateBuckets` 只做展示层聚合：8 天窗口内的按天计数，**过期任务计入「今天」**（OAS 配置里常见 `2023-01-01` 这类默认值）。
- 「立即运行 / 置顶」= 把 `next_run` 写为当前时间；「置底」= 写为一年后；随后发 `get_schedule` 刷新。

---

## 七、验证清单

```powershell
& 'D:\develop\flutter\bin\flutter.bat' analyze lib   # 0 error
& 'D:\develop\flutter\bin\flutter.bat' test          # 20 passed
& 'D:\develop\flutter\bin\flutter.bat' build windows --debug
& 'D:\develop\flutter\bin\flutter.bat' build windows --release
```

单测覆盖（21 例）：

| 文件 | 覆盖 |
| --- | --- |
| `test/overview_model_test.dart` | `next_run` 多格式解析、时区转本地、今天/非今天标签、相等性去抖、日期分布统计（含过期任务、窗口外、upcomingTimes、跨零点边界）、星期标签 |
| `test/design_system_test.dart` | 背景层级亮度递增、圆角/间距为正、文本样式层级递减、资产占位数据数量与唯一性、新增 i18n 键存在 |
| `test/overview_log_panel_test.dart` | 日志面板真实渲染（INFO/WARNING/ERROR 着色的 RichText）、无时间戳行兜底、错误计数 badge、任务统计 Tab 切换、空日志占位文案 |

### 实测截图

| 页面 | 文件 |
| --- | --- |
| 总览（三栏） | `docs/screenshots/overview.png` |
| 参数配置 | `docs/screenshots/args.png` |
| 设置 | `docs/screenshots/settings.png` |


对比要点（总览 vs 设计稿）：

- ✅ 顶部单行标题栏：Logo + OASX + 脚本标签（带电源点）+ 右侧工具/窗口按钮
- ✅ 左栏上：任务日期分布（今天浅绿高亮 + 未来 7 天）
- ✅ 左栏下：任务列表（时间徽章 + 名称 + 常驻操作图标）
- ✅ 中栏上：横幅（脚本名 + 状态点 + START/ONCE）
- ✅ 中栏下：日志面板（日志/运行日志/错误日志/任务统计 四 Tab + 右上操作图标 + 展开/收起）
- ✅ 右栏：资产 2 列网格 + 底部「18 项 · 每日 23:55 自动读取」
- ➖ 中栏横幅用程序化光晕替代角色立绘（不打包游戏资源）

---

## 八、首页入口与系统通知（本轮修复）

### 8.1 恢复被弄丢的「更新器 / 工具」入口

重做暗色 UI 时，`Home` 只剩 README 渲染：`UpdaterView` / `ToolView` 文件还在，
但**没有任何入口能到达**。本轮补回三处入口，并加测试防回归：

| 位置 | 组件 | 说明 |
| --- | --- | --- |
| 内容区顶部 | `lib/views/home/home_sub_nav.dart` → `HomeSubNav` | 首页固定三段切换条：主页 / 更新器 / 工具 |
| 标题栏右侧 | `lib/views/layout/appbar.dart` → `_HomeEntryActions` | 两个图标按钮，任意页面一键跳到更新器 / 工具 |
| 标签栏最左 | `lib/views/layout/script_tab_bar.dart` | 固定「主页」标签，不参与排序 / 显隐 |

菜单逻辑抽成纯函数 `lib/controller/home_menu.dart`：

- `kHomeMenuOrder` = `['Home', 'Updater', 'Tool']`，**永远排在最前且不重复**；
  即使服务端 `home_menu` 少返回一项，入口也不会再丢。
- `buildHomeMenus()` / `isHomeMenuPage()` 均为纯函数，见 `test/home_menu_test.dart`。
- `NavCtrl.openHomePage(menu)`：先切到 Home 脚本再切子页；`selectScript('Home')`
  默认落在「主页」（原来落在不存在的 `Overview`，导致二级菜单一个都不高亮）。

> 排查中发现的实际缺陷：`DragToMoveArea`（window_manager）带 `onDoubleTap`，
> 手势竞技场里一旦存在双击识别器，**子级所有单击都要等约 300ms 双击超时才触发**。
> 原来整条标题栏（含右侧按钮）都包在拖拽区里，按钮点下去像没反应。
> 现在拖拽区只包「标题 + 标签栏」，按钮区在拖拽区之外，单击即时生效
> （`test/appbar_entry_test.dart` 有专门用例锁定）。

### 8.2 系统通知（异常时弹原生通知）

| 文件 | 作用 |
| --- | --- |
| `lib/service/notification_service.dart` | `NotificationService`：开关、测试发送、异常上报（带节流）+ 原生投放双层实现 |
| `lib/utils/error_reporter.dart` | `ErrorReporter`：全局异常统一入口（日志 + 系统通知） |
| `lib/views/home/tool_view.dart` | 工具页「系统通知」分区：开关 + 发送测试 + 模拟异常上报 |
| `lib/model/const/storage_key.dart` | 新增 `StorageKey.systemNotify` |

**开关**：工具页 → 系统通知，默认**关闭**，持久化在 get_storage 的 `systemNotify`。

**投放通道（两层 + 静默降级，全部 try/catch，绝不影响主流程）**

1. `local_notifier` 插件（Windows WinToast / macOS UNUserNotificationCenter / Linux libnotify）；
2. 插件不可用时回退到零依赖实现：Windows = PowerShell + WinRT `ToastNotificationManager`
   （AUMID 运行时写 `HKCU\Software\Classes\AppUserModelId`，免管理员权限）；
   macOS = `osascript`；Linux = `notify-send`。

> 实测：Windows PowerShell 5.1 可用；**PowerShell 7 无法解析旧式 WinRT 类型语法**
> （`[Windows.UI.Notifications.ToastNotificationManager, ..., ContentType=WindowsRuntime]`），
> 所以候选顺序必须是 `powershell.exe (5.1)` → `powershell.exe` → `pwsh.exe`。
> 全量自检：`$env:OASX_REAL_TOAST=1; flutter test test/manual_real_toast_test.dart`
> → `REAL_TOAST_OK=true channel=windows-toast`。

**异常挂钩点**

| 位置 | 触发条件 |
| --- | --- |
| `lib/api/api_client.dart` | 任意 HTTP 请求抛异常 |
| `lib/service/websocket_service.dart` | WS 连接错误 / SocketException / onError |
| `lib/component/log/log_mixin.dart` | 脚本日志里出现 `ERROR` / `CRITICAL` |
| `lib/main.dart` | `FlutterError.onError` + `PlatformDispatcher.onError`（全局兜底） |

节流：5 秒内最多 1 条，相同文本 60 秒内不重复（进程内状态，重启清零）。

### 8.3 本轮新增测试

| 文件 | 覆盖 |
| --- | --- |
| `test/home_menu_test.dart` | 首页固定菜单在最前、不重复、空项忽略、兜底菜单 |
| `test/nav_home_entry_test.dart` | `selectScript('Home')` 默认子页、`switchContent`、`openHomePage` |
| `test/home_sub_nav_test.dart` | 子页切换条渲染与点击切换 |
| `test/appbar_entry_test.dart` | 标题栏窄宽不溢出、四个入口都在、单击不能被双击识别器拖慢 |
| `test/tool_view_test.dart` | 工具页开关读写、未注册服务时降级、原有推送测试区块保留 |
| `test/error_reporter_test.dart` | 开关打开/关闭/未注册时异常上报行为、标题透传 |
| `test/notification_service_test.dart` | 开关持久化、节流去重、XML/AppleScript 转义、UTF-16LE 编码、全局入口 |
| `test/tool_view_golden_test.dart` | 工具页暗色视觉快照 `test/goldens/tool_view_dark.png` |

验证命令：

```powershell
& 'D:\develop\flutter\bin\flutter.bat' analyze lib    # 0 error（10 条既有 warning/info）
& 'D:\develop\flutter\bin\flutter.bat' test           # 150 passed, 2 skipped（手动 toast 自检）
& 'D:\develop\flutter\bin\flutter.bat' build windows --debug
```

