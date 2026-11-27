# HG999

红果短剧独立 Theos 插件工程。源码仓库：<https://github.com/ygxmm/HG999>。

- **目标应用：** `com.phoenix.video`；随附运行时清单标记版本 7.4.5 / build 7.4.5.33、iOS 16.6。
- **软件包标识：** `com.axs.hg999`。
- **代码命名空间：** `AxsHG999`。
- **功能：** 在红果原生 `SSSettingViewController` 设置列表末尾新增独立分组“HG999”；点击后用红果原生 `SSSettingTableViewCell` 和 `FQReaderSaaSBaseTableViewController` 导航栈打开一级页面，标题为“HG999”。首个开关为“视频全屏播放底栏透明”，默认关闭。用户确认范围为**首页竖屏短视频流**：启用后仅在红果根底栏采用视频流样式时将背景颜色及明暗背景层透明化，保留图标、文字和按钮；不改播放器尺寸或播放布局。
- **注入范围：** `AxsHG999.plist` 仅匹配 `com.phoenix.video`。设置列表由单一 `%hook SSSettingViewController` 扩展；视频底栏外观通过独立 Hook 模块处理。

## 模块结构

- `Headers/AxsHG999Private.h`：唯一声明文件，集中放置用到的红果私有接口、本插件页面类声明和模块函数声明。
- `Hooks/AxsHG999Main.xm`：初始化配置模块。
- `Hooks/AxsHG999SettingsEntry.xm`：只负责向原生设置列表注入入口分组。
- `Hooks/AxsHG999SettingsPage.xm`：实现 HG999 首层页面与功能列表。
- `Hooks/AxsHG999VideoFullscreen.xm`：只改红果视频流样式下的底栏背景，不触碰播放器布局或按钮层。
- `Sources/AxsHG999SettingsEntry.m`：构造 HG999 原生入口行并负责页面跳转。
- `Sources/AxsHG999FullscreenSetting.m`：构造功能开关、保存偏好并触发原生底栏样式刷新。
- `Sources/AxsHG999Config.m`、`AxsHG999Preferences.m`、`AxsHG999Paths.m`：分别管理配置快照、偏好读写和越狱路径适配。
- `Sources/AxsHG999Config.h`、`AxsHG999Preferences.h`、`AxsHG999Paths.h`：仅为工程模板兼容转发头；实际声明都集中在 `Headers/AxsHG999Private.h`。

源码中的说明性代码注释统一使用中文；系统/应用要求实现的原生 selector 保持原名。

## 头文件来源

原始头文件包保留在本机 `Research/Headers/RedFruit-7.4.5-all-classes.zip`，共 80,432 个 `.h` 条目。该压缩包约 145.5 MiB，超过 GitHub 单文件限制，因此通过 `.gitignore` 排除，不会上传到公开仓库；目录中的归档说明会随源码上传。HG999 仅在唯一声明文件中保留当前实际使用的接口，不把整包头文件加入编译路径。原包 manifest 标记为 `complete-with-recoverable-errors`，记录 14 个超长 Swift 类型名文件写入错误，因此不是无遗漏的转储。

## 验证与工作流

工程结构检查和 17 项针对性静态断言通过，原始头文件归档的本机完整性检查也通过。推送到 `main` 会自动运行 Rootless 构建并上传 Actions 制品；为避免未经要求的公开发版，Release 仅在手动触发工作流时创建。

当前 iSH 未配置 `THEOS`，且缺少 `make`、`dpkg-deb`，本机没有编译 `.deb`、安装或真机验收。底栏样式接口来自 7.4.5 头文件声明；播放时的实际样式覆盖、透明效果与关闭后的恢复仍待目标机验证。静态检查不等同于编译或视觉验收。
