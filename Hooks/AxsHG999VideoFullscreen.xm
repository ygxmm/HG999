#import <objc/message.h>
#import <objc/runtime.h>

#import "AxsHG999Private.h"

// 通过运行时获取红果根标签栏控制器，避免生成私有类链接符号。
static SSTabBarController *axs_hg999_rootTabBarController(void) {
    Class managerClass = objc_getClass("SSNavigationManager");
    if (!managerClass) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(managerClass,
                                           @selector(getRootTabBarController));
}

// 复制红果当前样式，只将底栏背景相关字段改为透明。
static SSTabBarAppearanceStyle *axs_hg999_transparentTabBarStyle(
    SSTabBarAppearanceStyle *nativeStyle) {
    if (!nativeStyle) {
        return nil;
    }

    Class styleClass = objc_getClass("SSTabBarAppearanceStyle");
    if (!styleClass) {
        return nil;
    }
    id allocated = ((id (*)(id, SEL))objc_msgSend)(styleClass, @selector(alloc));
    id styleObject = ((id (*)(id, SEL))objc_msgSend)(allocated, @selector(init));
    SSTabBarAppearanceStyle *style = styleObject;
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

// 只在红果根底栏的“我的/首页视频流”页面启用透明背景。
static BOOL axs_hg999_isHomeVideoFeedTab(SSTabBarController *controller) {
    if (!controller || !controller.isBottomFeedTab) {
        return NO;
    }

    Class feedClass = objc_getClass("SSVideoSeriesFeedViewController");
    UIViewController *selectedController = controller.selectedViewController;
    return feedClass && selectedController &&
           [selectedController isKindOfClass:feedClass];
}

// 当前功能只改红果首页竖屏短视频流的底栏外观。
static BOOL axs_hg999_shouldClearVideoFeedTabBar(SSTabBar *tabBar) {
    if (![[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled] ||
        !axs_hg999_isVideoFullscreenTabBarTransparent()) {
        return NO;
    }

    SSTabBarController *controller = axs_hg999_rootTabBarController();
    return controller && controller.customTabBar == tabBar &&
           axs_hg999_isHomeVideoFeedTab(controller);
}

%hook SSTabBar

- (void)applyTabBarAppearanceStyle:(SSTabBarAppearanceStyle *)style
                  refreshForeground:(BOOL)refreshForeground
                      refreshImages:(BOOL)refreshImages {
    if (axs_hg999_shouldClearVideoFeedTabBar(self)) {
        SSTabBarAppearanceStyle *transparentStyle =
            axs_hg999_transparentTabBarStyle(style);
        if (transparentStyle) {
            %orig(transparentStyle, refreshForeground, refreshImages);
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
    SSTabBarController *rootController = axs_hg999_rootTabBarController();
    if (rootController != self ||
        !axs_hg999_isHomeVideoFeedTab(self) ||
        ![[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled] ||
        !axs_hg999_isVideoFullscreenTabBarTransparent() || !self.customTabBar) {
        return;
    }

    SSTabBarAppearanceStyle *transparentStyle =
        axs_hg999_transparentTabBarStyle(self.customTabBar.appearanceStyle);
    if (transparentStyle) {
        [self.customTabBar applyTabBarAppearanceStyle:transparentStyle
                                    refreshForeground:NO
                                        refreshImages:NO];
    }
}

%end
