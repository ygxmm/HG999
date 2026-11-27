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

NSString *axs_hg999_resourcePath(NSString *rootfsPath);
NSString *axs_hg999_preferencesPath(void);
NSDictionary *axs_hg999_readPreferences(void);
BOOL axs_hg999_writePreference(NSString *key, id value, NSError **error);

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

@interface AxsHG999FullscreenOptionCell : SSSettingTableViewCell
- (void)axs_hg999_switchValueChanged:(SSMaterialSwitch *)switchControl;
@end

@interface AxsHG999SettingsViewController : FQReaderSaaSBaseTableViewController
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
- (void)applyTabBarAppearanceStyle:(id)style refreshForeground:(BOOL)refreshForeground;
@end

@interface SSTabBarController : UIViewController
@property (nonatomic, strong) SSTabBar *customTabBar;
@property (nonatomic, assign) BOOL settledBottomTabBarAppearanceUseVideoFeedStyle;
@property (nonatomic, weak) id settledBottomTabBarAppearanceTabModel;
@property (nonatomic, weak) UIViewController *settledBottomTabBarAppearanceSourceViewController;
- (void)invalidateSettledBottomTabBarAppearanceCache;
- (void)resetCurrentBottomTabBackgroundColor;
- (void)settleBottomTabBarAppearanceWithTabModel:(id)tabModel
                             useVideoFeedStyle:(BOOL)useVideoFeedStyle
                           sourceViewController:(id)viewController;
@end

@interface SSNavigationManager : NSObject
+ (SSTabBarController *)getRootTabBarController;
@end

// 创建首个功能开关单元格，并在变更后写入配置。
UITableViewCell *axs_hg999_createVideoFullscreenOptionCell(UITableView *tableView);
BOOL axs_hg999_isVideoFullscreenTabBarTransparent(void);
BOOL axs_hg999_setVideoFullscreenTabBarTransparent(BOOL enabled);
void axs_hg999_refreshVideoTabBarAppearance(void);

// 由设置入口模块创建原生风格单元格并打开 HG999 一级页面。
UITableViewCell *axs_hg999_createSettingsEntryCell(SSSettingViewController *controller,
                                                   UITableView *tableView);
