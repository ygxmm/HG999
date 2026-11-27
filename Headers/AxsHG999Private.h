#pragma once

#import <UIKit/UIKit.h>

// 本文件集中声明 HG999 使用的原生接口、插件类与模块函数。
@interface AxsHG999Config : NSObject
+ (instancetype)axs_hg999_shared;
- (BOOL)axs_hg999_isEnabled;
- (id)axs_hg999_valueForKey:(NSString *)key defaultValue:(id)defaultValue;
- (void)axs_hg999_reload;
@end

FOUNDATION_EXPORT NSString * const AxsHG999PreferencesDomain;
FOUNDATION_EXPORT NSString * const AxsHG999PreferencesChanged;

#if defined(__cplusplus)
extern "C" {
#endif

NSString *axs_hg999_resourcePath(NSString *rootfsPath);
NSString *axs_hg999_preferencesPath(void);
NSDictionary *axs_hg999_readPreferences(void);
BOOL axs_hg999_writePreference(NSString *key, id value, NSError **error);
#if defined(__cplusplus)
}
#endif

@interface FQReaderSaaSBaseViewController : UIViewController
- (void)setTitle:(NSString *)title;
@end

@interface FQReaderSaaSBaseTableViewController : FQReaderSaaSBaseViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
- (instancetype)initWithStyle:(UITableViewStyle)style;
@end

@interface SSSettingViewController : FQReaderSaaSBaseTableViewController
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
@end

@interface SSMaterialSwitch : UIControl
@property (nonatomic, assign) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@interface SSSettingTableViewCell : UITableViewCell
@property (nonatomic, strong) SSMaterialSwitch *rightSwitch;
@property (nonatomic, copy) id callback;
@property (nonatomic, copy) NSString *titleStr;
@property (nonatomic, assign) BOOL shouldShowRightArrow;
@property (nonatomic, assign) BOOL shouldShowRightSwitch;
@property (nonatomic, assign) BOOL rightSwitchOn;
@property (nonatomic, assign) BOOL rightSwitchInteractionEnabled;
@property (nonatomic, assign) BOOL shouldShowTopCorner;
@property (nonatomic, assign) BOOL shouldShowBottomCorner;
- (void)setCallback:(id)callback;
- (void)setTitleStr:(NSString *)title;
- (void)setShouldShowRightArrow:(BOOL)show;
- (void)setShouldShowRightSwitch:(BOOL)show;
- (void)setRightSwitchOn:(BOOL)on;
- (void)setRightSwitchInteractionEnabled:(BOOL)enabled;
- (void)setShouldShowTopCorner:(BOOL)show;
- (void)setShouldShowBottomCorner:(BOOL)show;
@end

// 只刷新 HG999 功能开关所用的原生单元格事件。
#if defined(__cplusplus)
extern "C" {
#endif
void axs_hg999_prepareFullscreenSettingCell(SSSettingTableViewCell *cell);
BOOL axs_hg999_isFullscreenSettingCell(SSSettingTableViewCell *cell);
#if defined(__cplusplus)
}
#endif

// 仅通过运行时查找创建红果私有设置行，避免生成私有类链接符号。
#if defined(__cplusplus)
extern "C" {
#endif
UITableViewCell *axs_hg999_dequeueNativeSettingCell(UITableView *tableView,
                                                     NSString *reuseIdentifier);
#if defined(__cplusplus)
}
#endif

@interface AxsHG999SettingsViewController : UITableViewController
@end

@interface AxsHG999FullscreenSwitchAction : NSObject
- (void)axs_hg999_switchValueChanged:(SSMaterialSwitch *)switchControl;
@end

@interface SSTabBarAppearanceStyle : NSObject
@property (nonatomic, assign) double ratio;
@property (nonatomic, assign) BOOL darkMode;
@property (nonatomic, assign) long long foregroundStyle;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *selectedTextColor;
@property (nonatomic, strong) UIColor *imageColor;
@property (nonatomic, strong) UIColor *selectedImageColor;
@property (nonatomic, assign) double lightViewAlpha;
@property (nonatomic, assign) double darkViewAlpha;
@property (nonatomic, assign) double buttonAlpha;
@end

@interface SSTabBar : UIView
@property (nonatomic, strong) SSTabBarAppearanceStyle *appearanceStyle;
- (void)applyTabBarAppearanceStyle:(id)style
                 refreshForeground:(BOOL)refreshForeground
                     refreshImages:(BOOL)refreshImages;
@end

@interface SSTabBarController : UIViewController
@property (nonatomic, strong) SSTabBar *customTabBar;
@property (nonatomic, readonly, strong) UIViewController *selectedViewController;
@property (nonatomic, assign) BOOL settledBottomTabBarAppearanceUseVideoFeedStyle;
@property (nonatomic, weak) id settledBottomTabBarAppearanceTabModel;
@property (nonatomic, weak) UIViewController *settledBottomTabBarAppearanceSourceViewController;
- (BOOL)isBottomFeedTab;
- (void)invalidateSettledBottomTabBarAppearanceCache;
- (void)resetCurrentBottomTabBackgroundColor;
- (void)settleBottomTabBarAppearanceWithTabModel:(id)tabModel
                             useVideoFeedStyle:(BOOL)useVideoFeedStyle
                           sourceViewController:(id)viewController;
@end

@interface SSNavigationManager : NSObject
+ (SSTabBarController *)getRootTabBarController;
@end

#if defined(__cplusplus)
extern "C" {
#endif

// 创建首个功能开关单元格，并在变更后写入配置。
UITableViewCell *axs_hg999_createVideoFullscreenOptionCell(UITableView *tableView);
BOOL axs_hg999_isVideoFullscreenTabBarTransparent(void);
BOOL axs_hg999_setVideoFullscreenTabBarTransparent(BOOL enabled);
void axs_hg999_refreshVideoTabBarAppearance(void);
void axs_hg999_refreshVideoFeedLayout(void);

// 由设置入口模块创建原生风格单元格并打开 HG999 一级页面。
UITableViewCell *axs_hg999_createSettingsEntryCell(SSSettingViewController *controller,
                                                   UITableView *tableView);
#if defined(__cplusplus)
}
#endif
