from pathlib import Path
import re
import plistlib

root = Path(__file__).resolve().parents[1]
layout = (root / "Hooks/AxsHG999FullscreenLayout.xm").read_text(encoding="utf-8")
style = (root / "Hooks/AxsHG999VideoFullscreen.xm").read_text(encoding="utf-8")
setting = (root / "Sources/AxsHG999FullscreenSetting.m").read_text(encoding="utf-8")
page = (root / "Hooks/AxsHG999SettingsPage.xm").read_text(encoding="utf-8")
private = (root / "Headers/AxsHG999Private.h").read_text(encoding="utf-8")
filter_plist = plistlib.loads((root / "AxsHG999.plist").read_bytes())

checks = {
    "插件只注入红果": filter_plist["Filter"]["Bundles"] == ["com.phoenix.video"],
    "只在首页竖屏视频流启用": all(x in layout for x in ["isBottomFeedTab", "SSVideoSeriesFeedViewController", "size.height > size.width"]),
    "列表视口随开关扩展并可恢复": all(x in layout for x in ["boundsSize.height", "originalHeight", "collectionView.frame = frame", "invalidateLayout"]),
    "分页尺寸适配全屏 viewport": "originalSize.height = fullScreenSize.height" in layout,
    "播放器画面填满 cell 且原生控制 inset 补偿": "mediaContainer.frame = cellView.bounds" in layout and "playerView.frame = mediaContainer.bounds" in layout and "setContentInsetBottom:" in layout and "bottomInset = enabled" in layout,
    "分页后回到当前同一作品": "scrollToItemAtIndexPath:currentIndexPath" in layout,
    "关闭开关时能跨标签恢复原始分页": "activeFeedController ?:" in layout and "axs_hg999_findVideoFeedController(tabController, 0)" in layout and "CGFloat targetHeight = enabled ? boundsSize.height : originalHeight;" in layout,
    "开关同时刷新外观和布局": all(x in setting for x in ["axs_hg999_refreshVideoTabBarAppearance()", "axs_hg999_refreshVideoFeedLayout()"]),
    "底栏保留前景透明仅改背景": all(x in style for x in ["backgroundColor = [UIColor clearColor]", "lightViewAlpha = 0.0", "darkViewAlpha = 0.0", "buttonAlpha = nativeStyle.buttonAlpha"]),
    "唯一声明头含布局刷新函数": private.count("axs_hg999_refreshVideoFeedLayout") == 1,
    "页面包含视频全屏开关": "视频全屏播放底栏透明" in setting and "axs_hg999_createVideoFullscreenOptionCell" in page,
    "没有全局视图几何 hook": not re.search(r"%hook\s+(UIView|UICollectionView|UITableView|UIViewController)\b", layout),
    "分页 Hook selector 唯一": len(re.findall(r"(?m)^%hook FQVShortVideoListViewController$", layout)) == 1 and len(re.findall(r"(?m)^%hook FQVShortVideoSectionController$", layout)) == 1 and len(re.findall(r"(?m)^%hook FQVShortVideoPlayerCellView$", layout)) == 1,
}
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL"), name)
if not all(checks.values()):
    raise SystemExit(1)
