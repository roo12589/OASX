# 未发布 | Unreleased
## 新增 | New
- 恢复首页「更新器 / 工具」入口：内容区顶部子页切换条 + 标题栏快捷按钮 + 标签栏固定「主页」
- 工具页新增「系统通知」开关：异常时调用原生能力弹出系统通知（Windows Toast / macOS / Linux）
- 通知支持手动测试与模拟异常上报，默认关闭，开关持久化

## 改进 | Improved
- 异常统一走 ErrorReporter：HTTP 请求异常、WebSocket 断开、脚本 ERROR 日志、全局未捕获异常
- 标题栏拖拽区与按钮区分离，修复按钮点击要等双击超时才响应的问题

## 修复 | Fix
- 切换回首页时二级菜单落在不存在的 Overview，导致无任何菜单高亮

# v0.3.2
## 新增 | New
- 懒得翻优化了什么，更新就对了

# v0.3.1
## 新增 | New
- 翻译
- 日志自动滚动按钮，复制日志按钮
## 改进 | Improved
- 更新Flutter到版本3.27.1
- 限制日志最大数量
- Windows窗体缩小后可移动
- 增加侧边栏滚动条，修复配置文件过多，溢出窗口时无法滚动的问题

# v0.2.6
## 新增 | New
- 翻译
## 改进 | Improved
- 修复Windows深色模式下，OASX无法切换深色模式

# v0.2.5
## 新增 | New
- 翻译
## 改进 | Improved
- 更新Flutter到版本3.24.3

# v0.2.3
## 新增 | New
- 翻译
- 新增网页版: https://runhey.github.io/OASX/

# v0.2.2
## 新增 | New
- 翻译

# v0.2.1
## 新增 | New
- 完成所有翻译工作，妈妈再也不怕看不懂了
- 手动更新 OAS 按键

## 改进 | Improved
- 限制websocket重连次数

## 修复 | Fix
- xxx

# v0.1.9
## 新增 | New
- 配置部署文件
- 添加界面翻译

## 改进 | Improved
- 优化面板显示
- 调整配置项的间隔

## 修复 | Fix
- xxx

# v0.1.7
## 新增 | New
- 管理OAS服务进程(仅限windows)

## 改进 | Improved
- 优化README显示
- 优化日志显示（对齐）
- 更新 flutter 版本(3.16.4)
- 自动重连 OAS 

## 修复 | Fix
- 无法正确地获取本地的版本信息

# v0.1.5
## 新增 | New
- 清空日志缓存
- 添加设备相关翻译
- 添加更新器Updater

## 改进 | Improved
- 移动端 二级菜单展示
- CI/CD 自动修改版本号
- 移动端 调整日志字号
- 移动端 优化参数配置的布局

## 修复 | Fix
- xxx

# v0.1.1
## 新增 | New
- 添加消息推送测试
- 检测最新版弹窗
- 首页同步OAS仓库README, 赋予其缓存
- 结束服务按钮

## 改进 | Improved
- 日志显示对齐
- 优化路由导航

## 修复 | Fix
- xxx

# v0.0.1
None


# v0.0.0
## 新增 | New
- xxx

## 改进 | Improved
- xxx

## 修复 | Fix
- xxx
