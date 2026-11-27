#import "AxsHG999Private.h"

// 复制红果当前样式，只将底栏背景相关字段改为透明。
static SSTabBarAppearanceStyle *axs_hg999_transparentTabBarStyle(
    SSTabBarAppearanceStyle *nativeStyle) {
    if (!nativeStyle) {
        return nil;
    }

    SSTabBarAppearanceStyle *style = [[SSTabBarAppearanceStyle alloc] init];
    style.ratio = nativeStyle.ratio;
    style.darkMode = nativeStyle.darkMode;
    style.foregroundStyle = nativeStyle.foregroundStyle;
    style.backgroundColor = [UIColor clearColor];
    style.textColor = nativeStyle.textColor;
    style.selectedTextColor = nativeStyle.selectedTextColor;
    style.imageColor = nativeStyle.imageColor;
    style.selectedImageColor = nativeStyle.selectedImageColor;
    style.lightViewAlpha = 0.0;
    style.darkViewAlpha = 0.0;
    style.buttonAlpha = nativeStyle.buttonAlpha;
    return style;
}

// 只在红果根底栏正在采用视频流样式时启用背景透明。
static BOOL axs_hg999_shouldClearVideoFeedTabBar(SSTabBar *tabBar) {
    if (![[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled] ||
        !axs_hg999_isVideoFullscreenTabBarTransparent()) {
        return NO;
    }

    SSTabBarController *controller = [SSNavigationManager getRootTabBarController];
    return controller && controller.customTabBar == tabBar &&
           controller.settledBottomTabBarAppearanceUseVideoFeedStyle;
}

%hook SSTabBar

- (void)applyTabBarAppearanceStyle:(SSTabBarAppearanceStyle *)style
                  refreshForeground:(BOOL)refreshForeground {
    if (axs_hg999_shouldClearVideoFeedTabBar(self)) {
        SSTabBarAppearanceStyle *transparentStyle =
            axs_hg999_transparentTabBarStyle(style);
        if (transparentStyle) {
            %orig(transparentStyle, refreshForeground);
            return;
        }
    }
    %orig;
}

%end

%hook SSTabBarController

- (void)settleBottomTabBarAppearanceWithTabModel:(id)tabModel
                              useVideoFeedStyle:(BOOL)useVideoFeedStyle
                            sourceViewController:(id)sourceViewController {
    %orig;
    SSTabBarController *rootController = [SSNavigationManager getRootTabBarController];
    if (!useVideoFeedStyle || rootController != self ||
        ![[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled] ||
        !axs_hg999_isVideoFullscreenTabBarTransparent() || !self.customTabBar) {
        return;
    }

    SSTabBarAppearanceStyle *transparentStyle =
        axs_hg999_transparentTabBarStyle(self.customTabBar.appearanceStyle);
    if (transparentStyle) {
        [self.customTabBar applyTabBarAppearanceStyle:transparentStyle
                                    refreshForeground:NO];
    }
}

%end
