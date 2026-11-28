#import <objc/message.h>
#import <objc/runtime.h>

#import "AxsHG999Private.h"

static NSString * const axs_hg999_videoFullscreenTabBarTransparentKey =
    @"video_fullscreen_tab_bar_transparent";

// 读取“视频全屏播放底栏透明”开关，首次安装时默认关闭。
BOOL axs_hg999_isVideoFullscreenTabBarTransparent(void) {
    id value = [[AxsHG999Config axs_hg999_shared]
                axs_hg999_valueForKey:axs_hg999_videoFullscreenTabBarTransparentKey
                defaultValue:@NO];
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : NO;
}

// 保存开关状态并立即请求红果刷新当前底栏外观。
BOOL axs_hg999_setVideoFullscreenTabBarTransparent(BOOL enabled) {
    NSError *error = nil;
    BOOL saved = axs_hg999_writePreference(axs_hg999_videoFullscreenTabBarTransparentKey,
                                           @(enabled), &error);
    if (!saved) {
        return NO;
    }

    [[AxsHG999Config axs_hg999_shared] axs_hg999_reload];
    axs_hg999_refreshVideoTabBarAppearance();
    axs_hg999_refreshVideoFeedLayout();
    return YES;
}

// 按红果当前选中的标签页和样式参数重新应用原生底栏外观。
void axs_hg999_refreshVideoTabBarAppearance(void) {
    void (^refresh)(void) = ^{
        Class managerClass = objc_getClass("SSNavigationManager");
        if (!managerClass) {
            return;
        }
        SSTabBarController *controller = ((id (*)(id, SEL))objc_msgSend)(
            managerClass, @selector(getRootTabBarController));
        if (!controller) {
            return;
        }

        id tabModel = controller.settledBottomTabBarAppearanceTabModel;
        BOOL useVideoFeedStyle = controller.settledBottomTabBarAppearanceUseVideoFeedStyle;
        UIViewController *sourceViewController =
            controller.settledBottomTabBarAppearanceSourceViewController;
        if (tabModel) {
            [controller invalidateSettledBottomTabBarAppearanceCache];
            [controller settleBottomTabBarAppearanceWithTabModel:tabModel
                                             useVideoFeedStyle:useVideoFeedStyle
                                           sourceViewController:sourceViewController];
        } else {
            [controller resetCurrentBottomTabBackgroundColor];
        }
        [controller.customTabBar setNeedsLayout];
    };

    if ([NSThread isMainThread]) {
        refresh();
    } else {
        dispatch_async(dispatch_get_main_queue(), refresh);
    }
}

// 创建红果原生样式的功能开关行，并绑定其原生切换控件。
UITableViewCell *axs_hg999_createVideoFullscreenOptionCell(UITableView *tableView) {
    static NSString * const reuseIdentifier = @"AxsHG999.videoFullscreenTabBar";
    SSSettingTableViewCell *cell = (SSSettingTableViewCell *)
        axs_hg999_dequeueNativeSettingCell(tableView, reuseIdentifier);
    if (!cell) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:reuseIdentifier];
    }

    cell.titleStr = @"视频全屏播放底栏透明";
    cell.shouldShowRightArrow = NO;
    cell.shouldShowRightSwitch = YES;
    cell.rightSwitchInteractionEnabled = YES;
    cell.rightSwitchOn = axs_hg999_isVideoFullscreenTabBarTransparent();
    cell.shouldShowTopCorner = YES;
    cell.shouldShowBottomCorner = YES;

    // 使用红果单元格自身的 switchChangedCallback，由其原生 target-action 转发。
    __weak SSSettingTableViewCell *weakCell = cell;
    cell.switchChangedCallback = [^(BOOL nextValue) {
        if (!axs_hg999_setVideoFullscreenTabBarTransparent(nextValue)) {
            __strong SSSettingTableViewCell *strongCell = weakCell;
            strongCell.rightSwitchOn = !nextValue;
        }
    } copy];
    return cell;
}
