# HG999

红果短剧独立 Theos 插件工程。源码仓库：<https://github.com/ygxmm/HG999>。

- **目标应用：** `com.phoenix.video`。上传的声明包来自 Eggplant 7.4.5 / build 7.4.5.33；本轮只读真机探针确认当前安装运行版本为 7.4.7。涉及 TabBar 的运行时 selector 已以当前运行时信息校准，旧版本声明仅作结构参考。
- **软件包标识：** `com.axs.hg999`。
- **代码命名空间：** `AxsHG999`。
- **功能：** 在红果原生设置列表末尾新增“HG999”入口，点击打开一级设置页，标题为“HG999”。页面采用 iOS 分组列表和系统导航栏风格；首个开关为“视频全屏播放底栏透明”，默认关闭。用户确认范围为**首页竖屏短视频流**：启用后仅在红果根底栏采用视频流样式时将背景颜色及明暗背景层透明化，保留图标、文字和按钮；不改播放器尺寸或播放布局。
- **注入范围：** `AxsHG999.plist` 仅匹配 `com.phoenix.video`。设置列表由单一 `%hook SSSettingViewController` 扩展；视频底栏外观通过独立 Hook 模块处理。

## 模块结构

- `Headers/AxsHG999Private.h`：唯一声明文件，集中放置用到的红果私有接口、本插件页面类声明和模块函数声明。
- `Hooks/AxsHG999Main.xm`：初始化配置模块。
- `Hooks/AxsHG999SettingsEntry.xm`：只负责向原生设置列表注入入口分组。
- `Hooks/AxsHG999SettingsPage.xm`：实现 HG999 首层页面与功能列表。
- `Hooks/AxsHG999VideoFullscreen.xm`：以当前根控制器、首页视频 Feed 控制器身份和底部 Feed 标签状态为门控，按 Eggplant 7.4.7 实际 `applyTabBarAppearanceStyle:refreshForeground:refreshImages:` selector 透明化背景，不触碰播放器布局或按钮层。
- `Hooks/AxsHG999FullscreenSwitch.xm`：只在 HG999 开关单元格布局后绑定原生开关事件。
- `Sources/AxsHG999NativeSettings.m`：运行时查找红果私有单元格并创建，不让私有类产生静态链接依赖。
- `Sources/AxsHG999SettingsEntry.m`：构造 HG999 原生入口行并负责页面跳转。
- `Sources/AxsHG999FullscreenSetting.m`：构造功能开关、保存偏好并触发原生底栏样式刷新。
- `Sources/AxsHG999Config.m`、`AxsHG999Preferences.m`、`AxsHG999Paths.m`：分别管理配置快照、容器内偏好文件读写和越狱资源路径适配。开关配置保存在 Eggplant 沙盒的 `Library/Application Support/HG999/preferences.plist`；不用越狱全局偏好目录。
- `Sources/AxsHG999Config.h`、`AxsHG999Preferences.h`、`AxsHG999Paths.h`：仅为工程模板兼容转发头；实际声明都集中在 `Headers/AxsHG999Private.h`。

源码中的说明性代码注释统一使用中文；系统/应用要求实现的原生 selector 保持原名。

## 头文件来源

原始头文件包保留在本机 `Research/Headers/RedFruit-7.4.5-all-classes.zip`，共 80,432 个 `.h` 条目。该压缩包约 145.5 MiB，超过 GitHub 单文件限制，因此通过 `.gitignore` 排除，不会上传到公开仓库；目录中的归档说明会随源码上传。HG999 仅在唯一声明文件中保留当前实际使用的接口，不把整包头文件加入编译路径。原包 manifest 标记为 `complete-with-recoverable-errors`，记录 14 个超长 Swift 类型名文件写入错误，因此不是无遗漏的转储。

## 运行时排查更正

已安装的 `5.2.0-4` 虽注入并加载，但只读探针确认它将配置写入 `/var/mobile/Library/Preferences/com.axs.hg999.plist`；该目录在 Eggplant 沙盒内不可写，plist 不存在，配置快照为空，所以开关无法持久化。另在当前 Eggplant 7.4.7 根控制器读到 `isBottomFeedTab=true`，选中控制器为 `SSVideoSeriesFeedViewController_hmd_subfix_`，但 `useVideoFeedStyle=false`；旧逻辑把该值误用为首页短视频流判定，实际一路提前退出。运行时的 TabBar 外观 selector 也与 7.4.5 头文件不同。最新源码改用容器 Application Support 保存、按首页 Feed 控制器身份和底部 Feed 状态门控，并对齐当前三参数 selector；需新 CI 包和真机验收。

## 验证与工作流

此前根提交 `1017536` 的 Rootless CI 构建成功，制品只验证了源码链接和打包。本轮修复尚未构建。推送到 `main` 会自动运行 Rootless 构建并上传 Actions 制品；Release 仅手动触发。

Theos 未配置于本地 iSH；后续由 GitHub Actions 编译。底栏透明的视觉效果和开关保存/关闭恢复，仍须新包安装后真机确认。
