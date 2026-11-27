#import <UIKit/UIKit.h>

#import "AxsHG999Private.h"

// 由当前分组数反推出红果原始分组数，最后一组由 HG999 新增。
static NSInteger axs_hg999_originalSectionCount(SSSettingViewController *controller,
                                                 UITableView *tableView) {
    NSInteger count = [controller numberOfSectionsInTableView:tableView] - 1;
    return MAX(count, 0);
}

// 只处理红果设置控制器自己的主表格，并尊重插件启用状态。
static BOOL axs_hg999_shouldInject(SSSettingViewController *controller,
                                    UITableView *tableView) {
    return tableView == controller.tableView &&
           [[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled];
}

%hook SSSettingViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger originalCount = %orig;
    if (!axs_hg999_shouldInject(self, tableView)) {
        return originalCount;
    }
    return originalCount + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) &&
        section == axs_hg999_originalSectionCount(self, tableView)) {
        return 1;
    }
    return %orig;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (axs_hg999_shouldInject(self, tableView) &&
        indexPath.section == axs_hg999_originalSectionCount(self, tableView) &&
        indexPath.row == 0) {
        return axs_hg999_createSettingsEntryCell(self, tableView);
    }
    return %orig;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) &&
        section == axs_hg999_originalSectionCount(self, tableView)) {
        return 12.0;
    }
    return %orig;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) &&
        section == axs_hg999_originalSectionCount(self, tableView)) {
        return 12.0;
    }
    return %orig;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) &&
        section == axs_hg999_originalSectionCount(self, tableView)) {
        return nil;
    }
    return %orig;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) &&
        section == axs_hg999_originalSectionCount(self, tableView)) {
        return nil;
    }
    return %orig;
}

%end
