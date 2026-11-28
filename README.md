# HG999

红果短剧独立 Theos 插件工程。源码仓库：<https://github.com/ygxmm/HG999>。

- **目标应用：** `com.phoenix.video`。上传的声明包来自 Eggplant 7.4.5 / build 7.4.5.33；本轮只读真机探针确认当前安装运行版本为 7.4.7。涉及 TabBar 的运行时 selector 已以当前运行时信息校准，旧版本声明仅作结构参考。
- **软件包标识：** `com.axs.hg999`。
- **代码命名空间：** `AxsHG999`。
- **功能：** 在红果原生设置列表最前方新增独立分组“HG999”；原有设置分组保持原顺序，不倒序、不重排。点击后打开标题为“HG999”的一级设置页。页面采用 iOS 分组列表和系统导航栏风格；首个开关为“视频全屏播放底栏透明”，默认关闭。用户确认范围为**首页竖屏短视频流**：开启时将视频分页 viewport / cell / 播放器画面扩至列表宿主整屏高度，使画面延伸到首页 TabBar 背后；TabBar 背景透明、按钮和视频互动控件维持原位。关闭时恢复红果原生 viewport 高度；横屏和其他页面不处理。
- **注入范围：** `AxsHG999.plist` 仅匹配 `com.phoenix.video`。设置列表由单一 `%hook SSSettingViewController` 扩展；视频底栏外观通过独立 Hook 模块处理。

## 模块结构

- `Headers/AxsHG999Private.h`：唯一声明文件，集中放置用到的红果私有接口、本插件页面类声明和模块函数声明。
- `Hooks/AxsHG999Main.xm`：初始化配置模块。
- `Hooks/AxsHG999SettingsEntry.xm`：只负责向原生设置列表注入入口分组。
- `Hooks/AxsHG999SettingsPage.xm`：实现 HG999 首层页面与功能列表。
- `Hooks/AxsHG999VideoFullscreen.xm`：以当前根控制器、首页视频 Feed 控制器身份和底部 Feed 标签状态为门控，按 Eggplant 7.4.7 实际 `applyTabBarAppearanceStyle:refreshForeground:refreshImages:` selector 透明化 TabBar 背景。
- `Hooks/AxsHG999FullscreenLayout.xm`：开启时把首页竖屏短视频列表与 IGList 视频分页扩到宿主全高；播放器画面跟随 cell 延伸到 TabBar 后方；互动控件调用红果原生 `setContentInsetBottom:` 保持在 TabBar 上沿。关闭时按方向恢复记录的原生 viewport 高度，跨到底栏其他标签关闭也会恢复，并重新对齐当前作品。
- `Sources/AxsHG999FullscreenSetting.m`：使用红果 `SSSettingTableViewCell.switchChangedCallback` 原生回调保存开关，并触发底栏外观与视频视口刷新；不额外给 `SSMaterialSwitch` 叠加第二个事件 target。
- `Sources/AxsHG999NativeSettings.m`：运行时查找红果私有单元格并创建，不让私有类产生静态链接依赖。
- `Sources/AxsHG999SettingsEntry.m`：构造 HG999 原生入口行并负责页面跳转。
- `Sources/AxsHG999FullscreenSetting.m`：使用红果 `SSSettingTableViewCell.switchChangedCallback` 原生回调保存开关，并触发底栏外观与视频视口刷新；不额外给 `SSMaterialSwitch` 叠加第二个事件 target。
- `Sources/AxsHG999Config.m`、`AxsHG999Preferences.m`、`AxsHG999Paths.m`：分别管理配置快照、容器内偏好文件读写和越狱资源路径适配。开关配置保存在 Eggplant 沙盒的 `Library/Application Support/HG999/preferences.plist`；不用越狱全局偏好目录。
- `Sources/AxsHG999Config.h`、`AxsHG999Preferences.h`、`AxsHG999Paths.h`：仅为工程模板兼容转发头；实际声明都集中在 `Headers/AxsHG999Private.h`。

源码中的说明性代码注释统一使用中文；系统/应用要求实现的原生 selector 保持原名。

## 头文件来源

原始头文件包保留在本机 `Research/Headers/RedFruit-7.4.5-all-classes.zip`，共 80,432 个 `.h` 条目。该压缩包约 145.5 MiB，超过 GitHub 单文件限制，因此通过 `.gitignore` 排除，不会上传到公开仓库；目录中的归档说明会随源码上传。HG999 仅在唯一声明文件中保留当前实际使用的接口，不把整包头文件加入编译路径。原包 manifest 标记为 `complete-with-recoverable-errors`，记录 14 个超长 Swift 类型名文件写入错误，因此不是无遗漏的转储。

## 视频铺屏现状与修复设计

用户补充的 7.4.7.32 页面运行时 ZIP 显示：Feed 根容器高 852pt；短视频 `FQVCollectionView`、IGList 视频页 `FQVShortVideoSectionController -sizeForItemAt:`、cell、`FQVPlayer` 和 `TTPlayerView` 都只有 762pt；底部 `SSTabBar` 从 y=768 开始，形成 90pt 保留区。旧 5.2.0-5 只处理底栏样式，不修改这些尺寸，因此不能将画面铺到屏幕底部。

当前本地源码加入同一开关控制的几何扩展：Feed viewport 与 IGList 视频页随宿主扩到 852pt，视频画面随 cell 扩展；播放器控制层保持在原 TabBar 上沿的安全高度，并尽量恢复当前视频页索引；关闭开关恢复记录的原生列表高度。横屏与其他页面不处理。此修改目前只完成源代码和静态检查，尚未 CI 编译或真机验收。

## 设置置顶闪退候选修正

由于尚未获得本次 `.ips` 崩溃报告，不能把原因定案。代码审计发现置顶实现把显示组索引映射成原生索引后调用 `%orig`；若红果原生回调内部通过 `self` 重入同一表格委托，旧 hook 会再次转换原生索引。现加线程本地、可嵌套的原生回调深度保护：进入原生 `%orig` 期间，所有相关表格委托都透传原生索引和分组数，离开后在 `@finally` 恢复保护状态。新增纯模型测试覆盖 cell 内重入的组数、行数、行高和索引保持。它验证了候选修复的逻辑，不证明红果原生实现实际重入，也不替代 crash 堆栈确认。

## 本轮开关持久化与验收

- 动态观察到的旧版失败路径：HG999 原生行已显示，红果 `Library/Application Support/HG999/preferences.plist` 已创建且目录可写，但开关值为 `0`；旧 `SSMaterialSwitch` target 只有红果 cell 自身的 `onSwitchValueChanged:`，没有 HG999 写配置的 target。因此现象是事件未接入，不是偏好路径不可写。
- 当前 e9357cd 源码使用 `SSSettingTableViewCell.switchChangedCallback` 原生 block，并在写入失败时回滚 UI；v5.2.0-9 的 Rootless CI 已成功，但未记录到该版实际点按 block 与重启后读回的运行时回执。
- RED/GREEN 回归：从已安装失败基线 `decf86a` 运行 `Tests/check_setting_toggle_contract.py` 退出 1，准确失败四项回调接线断言；对当前源码退出 0。其余设置顺序重入测试、铺屏契约及功能静态断言通过。Python 状态模型不执行 UIKit，只验证配置转换规则。
- 独立只读审查未发现当前源代码中新的明确静态缺陷；审查也强调原生 block 的目标机调用尚待验证。
- 本地 Theos 不可用；本轮没有推送、安装或触发 CI。新增回归测试已加入本地 workflow，等待获得推送授权后由远端 CI 实跑。目标机当前未处于 HG999 设置页，因此本轮未点击开关、未改变配置；最新运行快照显示开关仍为关闭。
