#import <objc/message.h>
#import <objc/runtime.h>

#import "AxsHG999Private.h"

static char axs_hg999_nativeViewportHeightsKey;
static char axs_hg999_nativeViewportGapKey;
static char axs_hg999_lastControlInsetKey;

// 获取红果当前根标签栏控制器。
static SSTabBarController *axs_hg999_layoutRootTabBarController(void) {
    Class managerClass = objc_getClass("SSNavigationManager");
    if (!managerClass) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(managerClass,
                                           @selector(getRootTabBarController));
}

// 判断当前是不是首页竖屏视频流。
static SSTabBarController *axs_hg999_homePortraitFeedController(void) {
    SSTabBarController *tabController = axs_hg999_layoutRootTabBarController();
    if (!tabController || !tabController.isBottomFeedTab) {
        return nil;
    }

    Class feedClass = objc_getClass("SSVideoSeriesFeedViewController");
    UIViewController *selectedController = tabController.selectedViewController;
    if (!feedClass || !selectedController ||
        ![selectedController isKindOfClass:feedClass]) {
        return nil;
    }

    CGSize size = selectedController.view.bounds.size;
    return size.height > size.width ? tabController : nil;
}

// 搜索已加载的首页视频流，用于在非首页页面关闭开关时恢复原布局。
static UIViewController *axs_hg999_findVideoFeedController(UIViewController *controller,
                                                            NSUInteger depth) {
    if (!controller || depth > 10) {
        return nil;
    }
    Class feedClass = objc_getClass("SSVideoSeriesFeedViewController");
    if (feedClass && [controller isKindOfClass:feedClass]) {
        return controller;
    }
    for (UIViewController *child in controller.childViewControllers) {
        UIViewController *found = axs_hg999_findVideoFeedController(child, depth + 1);
        if (found) {
            return found;
        }
    }
    return nil;
}

// 找到首页视频列表控制器，避免修改剧场和其他列表。
static UIViewController *axs_hg999_findHomeFeedListController(
    UIViewController *controller, UIViewController *feedController, NSUInteger depth) {
    if (!controller || !feedController || depth > 10) {
        return nil;
    }

    Class listClass = objc_getClass("FQVShortVideoListViewController");
    if (listClass && [controller isKindOfClass:listClass]) {
        UIViewController *parent = controller;
        while (parent && parent != feedController) {
            parent = parent.parentViewController;
        }
        return parent == feedController ? controller : nil;
    }

    for (UIViewController *child in controller.childViewControllers) {
        UIViewController *found =
            axs_hg999_findHomeFeedListController(child, feedController, depth + 1);
        if (found) {
            return found;
        }
    }
    return nil;
}

// 递归找到数据源确实为 IGListAdapter 的短视频分页集合视图。
static UICollectionView *axs_hg999_findVideoCollectionView(UIView *view,
                                                             NSUInteger depth) {
    if (!view || depth > 10) {
        return nil;
    }

    Class collectionClass = objc_getClass("FQVCollectionView");
    if (collectionClass && [view isKindOfClass:collectionClass] &&
        [view respondsToSelector:@selector(dataSource)]) {
        id dataSource = ((id (*)(id, SEL))objc_msgSend)(view, @selector(dataSource));
        if ([NSStringFromClass([dataSource class]) containsString:@"IGListAdapter"]) {
            return (UICollectionView *)view;
        }
    }

    for (UIView *child in view.subviews) {
        UICollectionView *found =
            axs_hg999_findVideoCollectionView(child, depth + 1);
        if (found) {
            return found;
        }
    }
    return nil;
}

// 按方向保存原生列表高度，用于关闭开关时精确恢复。
static NSMutableDictionary *axs_hg999_viewportHeightMap(
    UIViewController *listController, CGSize boundsSize) {
    NSMutableDictionary *map = objc_getAssociatedObject(
        listController, &axs_hg999_nativeViewportHeightsKey);
    if (!map) {
        map = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(listController, &axs_hg999_nativeViewportHeightsKey,
                                 map, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSString *key = [NSString stringWithFormat:@"%.1f-%.1f",
                     boundsSize.width, boundsSize.height];
    if (!map[key]) {
        map[key] = @(0.0);
    }
    return map;
}

// 取得原生视频内容与底栏之间的保留间距，并跨尺寸方向复用。
static CGFloat axs_hg999_nativeViewportGap(UIViewController *listController,
                                           UICollectionView *collectionView,
                                           SSTabBarController *tabController,
                                           CGFloat originalHeight) {
    NSNumber *savedGap = objc_getAssociatedObject(listController,
                                                  &axs_hg999_nativeViewportGapKey);
    if (savedGap) {
        return savedGap.doubleValue;
    }

    CGFloat gap = 6.0;
    SSTabBar *tabBar = tabController.customTabBar;
    if (tabBar && collectionView.superview &&
        fabs(originalHeight - collectionView.frame.size.height) < 0.5) {
        CGRect tabBarFrame = [tabBar convertRect:tabBar.bounds
                                           toView:collectionView.superview];
        CGFloat observedGap = CGRectGetMinY(tabBarFrame) -
                              CGRectGetMaxY(collectionView.frame);
        if (observedGap > 0.0 && observedGap < 24.0) {
            gap = observedGap;
        }
    }

    objc_setAssociatedObject(listController, &axs_hg999_nativeViewportGapKey,
                             @(gap), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return gap;
}

// 取得被选中的可见视频页，布局变化后仍停留在同一条作品。
static NSIndexPath *axs_hg999_currentVideoIndexPath(UICollectionView *collectionView) {
    NSArray<NSIndexPath *> *paths = collectionView.indexPathsForVisibleItems;
    if (paths.count == 0) {
        return nil;
    }

    CGFloat viewportCenter = collectionView.contentOffset.y +
                             collectionView.bounds.size.height * 0.5;
    NSIndexPath *best = paths.firstObject;
    CGFloat bestDistance = CGFLOAT_MAX;
    for (NSIndexPath *path in paths) {
        UICollectionViewLayoutAttributes *attributes =
            [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:path];
        if (!attributes) {
            continue;
        }
        CGFloat center = CGRectGetMidY(attributes.frame);
        CGFloat distance = fabs(center - viewportCenter);
        if (distance < bestDistance) {
            bestDistance = distance;
            best = path;
        }
    }
    return best;
}

// 把视频分页视口扩到整屏，同时记录原生高度供关闭时还原。
static void axs_hg999_updateVideoListViewport(UIViewController *listController) {
    SSTabBarController *tabController = axs_hg999_layoutRootTabBarController();
    if (!tabController || !listController.isViewLoaded ||
        ![listController.view respondsToSelector:@selector(bounds)]) {
        return;
    }

    UIViewController *activeFeedController =
        axs_hg999_homePortraitFeedController() ? tabController.selectedViewController : nil;
    UIViewController *feedController = activeFeedController ?:
        axs_hg999_findVideoFeedController(tabController, 0);
    if (!feedController ||
        axs_hg999_findHomeFeedListController(feedController, feedController, 0) != listController) {
        return;
    }

    UICollectionView *collectionView =
        axs_hg999_findVideoCollectionView(listController.view, 0);
    if (!collectionView || !collectionView.superview) {
        return;
    }

    CGRect frame = collectionView.frame;
    CGSize boundsSize = listController.view.bounds.size;
    if (boundsSize.height <= boundsSize.width) {
        return;
    }
    NSMutableDictionary *heightMap =
        axs_hg999_viewportHeightMap(listController, boundsSize);
    NSString *key = [NSString stringWithFormat:@"%.1f-%.1f",
                     boundsSize.width, boundsSize.height];
    CGFloat originalHeight = [heightMap[key] doubleValue];
    if (originalHeight <= 0.0) {
        if (frame.size.height <= 0.0) {
            return;
        }
        if (frame.size.height < boundsSize.height - 1.0) {
            originalHeight = frame.size.height;
            axs_hg999_nativeViewportGap(listController, collectionView,
                                         tabController, originalHeight);
        } else {
            CGFloat gap = axs_hg999_nativeViewportGap(listController, collectionView,
                                                      tabController, frame.size.height);
            SSTabBar *tabBar = tabController.customTabBar;
            CGRect tabBarFrame = tabBar
                ? [tabBar convertRect:tabBar.bounds toView:collectionView.superview]
                : CGRectZero;
            originalHeight = tabBar
                ? MIN(boundsSize.height, MAX(0.0,
                    CGRectGetMinY(tabBarFrame) - frame.origin.y - gap))
                : frame.size.height;
            if (originalHeight <= 0.0) {
                originalHeight = frame.size.height;
            }
        }
        heightMap[key] = @(originalHeight);
    }
    BOOL enabled = activeFeedController == feedController &&
                   [[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled] &&
                   axs_hg999_isVideoFullscreenTabBarTransparent();
    CGFloat targetHeight = enabled ? boundsSize.height : originalHeight;
    if (targetHeight <= 0.0) {
        targetHeight = frame.size.height;
    }
    if (fabs(frame.size.height - targetHeight) <= 0.5) {
        return;
    }

    NSIndexPath *currentIndexPath =
        axs_hg999_currentVideoIndexPath(collectionView);
    frame.size.height = targetHeight;
    collectionView.frame = frame;
    [collectionView.collectionViewLayout invalidateLayout];
    [collectionView setNeedsLayout];
    [collectionView layoutIfNeeded];

    if (currentIndexPath) {
        __weak UICollectionView *weakCollectionView = collectionView;
        __weak UIViewController *weakListController = listController;
        dispatch_async(dispatch_get_main_queue(), ^{
            UICollectionView *currentCollection = weakCollectionView;
            UIViewController *currentList = weakListController;
            SSTabBarController *rootController =
                axs_hg999_layoutRootTabBarController();
            UIViewController *feedController = rootController
                ? axs_hg999_findVideoFeedController(rootController, 0) : nil;
            if (!currentCollection || !currentList || !feedController ||
                axs_hg999_findHomeFeedListController(feedController, feedController, 0) != currentList) {
                return;
            }
            if (currentIndexPath.section < [currentCollection numberOfSections] &&
                currentIndexPath.item <
                    [currentCollection numberOfItemsInSection:currentIndexPath.section]) {
                [currentCollection scrollToItemAtIndexPath:currentIndexPath
                                          atScrollPosition:UICollectionViewScrollPositionTop
                                                  animated:NO];
            }
        });
    }
}

// 在原生布局完成后更新首页视频集合的可视高度。
%hook FQVShortVideoListViewController

- (void)viewDidLayoutSubviews {
    %orig;
    UIViewController *listController = (UIViewController *)self;
    SSTabBarController *tabController = axs_hg999_layoutRootTabBarController();
    UIViewController *feedController = tabController
        ? axs_hg999_findVideoFeedController(tabController, 0) : nil;
    if (feedController &&
        axs_hg999_findHomeFeedListController(feedController, feedController, 0) == listController) {
        axs_hg999_updateVideoListViewport(listController);
    }
}

%end

// 视频 cell 加高后只扩展视频画面，互动控件仍停在透明底栏上方。
%hook FQVShortVideoPlayerCellView

- (void)layoutSubviews {
    %orig;
    UIView *cellView = (UIView *)self;
    SSTabBarController *rootController = axs_hg999_layoutRootTabBarController();
    UIViewController *feedController = rootController
        ? axs_hg999_findVideoFeedController(rootController, 0) : nil;
    if (!rootController || !feedController ||
        ![cellView isDescendantOfView:feedController.view]) {
        return;
    }

    UIViewController *activeFeedController =
        axs_hg999_homePortraitFeedController() ? rootController.selectedViewController : nil;
    UIViewController *listController =
        axs_hg999_findHomeFeedListController(feedController, feedController, 0);
    if (!listController) {
        return;
    }
    BOOL enabled = activeFeedController == feedController &&
                   [[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled] &&
                   axs_hg999_isVideoFullscreenTabBarTransparent();

    UIView *mediaContainer =
        ((id (*)(id, SEL))objc_msgSend)(self, @selector(playerSuperView));
    UIView *playerView = ((id (*)(id, SEL))objc_msgSend)(self, @selector(vPlayer));
    if (enabled && mediaContainer &&
        !CGRectEqualToRect(mediaContainer.frame, cellView.bounds)) {
        mediaContainer.frame = cellView.bounds;
        [mediaContainer setNeedsLayout];
        [mediaContainer layoutIfNeeded];
    }
    if (enabled && playerView && mediaContainer &&
        playerView.superview == mediaContainer &&
        !CGRectEqualToRect(playerView.frame, mediaContainer.bounds)) {
        playerView.frame = mediaContainer.bounds;
        [playerView setNeedsLayout];
        [playerView layoutIfNeeded];
    }

    UIView *controlView =
        ((id (*)(id, SEL))objc_msgSend)(self, @selector(vPlayerControlView));
    if (controlView) {
        NSMutableDictionary *heightMap = axs_hg999_viewportHeightMap(
            listController, listController.view.bounds.size);
        NSString *key = [NSString stringWithFormat:@"%.1f-%.1f",
                         listController.view.bounds.size.width,
                         listController.view.bounds.size.height];
        CGFloat originalHeight = [heightMap[key] doubleValue];
        CGFloat bottomInset = enabled && originalHeight > 0.0
            ? MAX(0.0, cellView.bounds.size.height - originalHeight)
            : 0.0;
        NSNumber *previousInset = objc_getAssociatedObject(
            controlView, &axs_hg999_lastControlInsetKey);
        if ([controlView respondsToSelector:@selector(setContentInsetBottom:)] &&
            (enabled || previousInset) &&
            (!previousInset || fabs(previousInset.doubleValue - bottomInset) > 0.5)) {
            ((void (*)(id, SEL, double))objc_msgSend)(
                controlView, @selector(setContentInsetBottom:), bottomInset);
            objc_setAssociatedObject(controlView, &axs_hg999_lastControlInsetKey,
                                     @(bottomInset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

%end

// IGList 以 collectionContext 的容器大小作为视频分页高度；跟随整屏视口重算。
%hook FQVShortVideoSectionController

- (CGSize)sizeForItemAtIndex:(NSInteger)index {
    CGSize originalSize = %orig;
    id collectionContext =
        ((id (*)(id, SEL))objc_msgSend)(self, @selector(collectionContext));
    UIViewController *listController = collectionContext
        ? ((id (*)(id, SEL))objc_msgSend)(collectionContext, @selector(viewController))
        : nil;
    SSTabBarController *tabController = axs_hg999_homePortraitFeedController();
    if (!listController || !tabController ||
        axs_hg999_findHomeFeedListController(tabController.selectedViewController,
                                              tabController.selectedViewController, 0) != listController ||
        ![[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled] ||
        !axs_hg999_isVideoFullscreenTabBarTransparent()) {
        return originalSize;
    }

    CGSize fullScreenSize = listController.view.bounds.size;
    originalSize.height = fullScreenSize.height;
    return originalSize;
}

%end

// 设置开关后立即请求当前首页列表执行一次布局更新。
void axs_hg999_refreshVideoFeedLayout(void) {
    void (^refresh)(void) = ^{
        SSTabBarController *rootController = axs_hg999_layoutRootTabBarController();
        UIViewController *activeFeedController =
            axs_hg999_homePortraitFeedController()
                ? rootController.selectedViewController : nil;
        UIViewController *feedController = activeFeedController ?:
            (rootController ? axs_hg999_findVideoFeedController(rootController, 0) : nil);
        if (!feedController) {
            return;
        }
        UIViewController *listController =
            axs_hg999_findHomeFeedListController(feedController, feedController, 0);
        if (listController.isViewLoaded) {
            [listController.view setNeedsLayout];
            [listController.view layoutIfNeeded];
            axs_hg999_updateVideoListViewport(listController);
        }
    };
    if ([NSThread isMainThread]) {
        refresh();
    } else {
        dispatch_async(dispatch_get_main_queue(), refresh);
    }
}
