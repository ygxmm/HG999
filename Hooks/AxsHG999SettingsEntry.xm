#import <UIKit/UIKit.h>

#import "AxsHG999Private.h"

// 只处理红果原生设置主表，不改动其他表格或系统设置界面。
static BOOL axs_hg999_shouldInject(SSSettingViewController *controller,
                                    UITableView *tableView) {
    return tableView == controller.tableView &&
           [[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled];
}

// 将插入新分组后的显示索引映射回原生分组索引。
static NSInteger axs_hg999_originalSectionForDisplay(
    SSSettingViewController *controller, UITableView *tableView,
    NSInteger displaySection) {
    if (axs_hg999_shouldInject(controller, tableView)) {
        return displaySection - 1;
    }
    return displaySection;
}

// 在红果原有分组最前方插入 HG999，不重排原有分组。
%hook SSSettingViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger originalCount = %orig;
    if (!axs_hg999_shouldInject(self, tableView)) {
        return originalCount;
    }
    return originalCount + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) && section == 0) {
        return 1;
    }

    NSInteger originalSection =
        axs_hg999_originalSectionForDisplay(self, tableView, section);
    if (originalSection < 0) {
        return 0;
    }
    return %orig(tableView, originalSection);
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (axs_hg999_shouldInject(self, tableView) &&
        indexPath.section == 0 && indexPath.row == 0) {
        return axs_hg999_createSettingsEntryCell(self, tableView);
    }

    NSInteger originalSection =
        axs_hg999_originalSectionForDisplay(self, tableView, indexPath.section);
    if (originalSection < 0) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
    }
    NSIndexPath *originalIndexPath = [NSIndexPath indexPathForRow:indexPath.row
                                                        inSection:originalSection];
    return %orig(tableView, originalIndexPath);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (axs_hg999_shouldInject(self, tableView) &&
        indexPath.section == 0 && indexPath.row == 0) {
        return 56.0;
    }

    NSInteger originalSection =
        axs_hg999_originalSectionForDisplay(self, tableView, indexPath.section);
    if (originalSection < 0) {
        return tableView.rowHeight;
    }
    NSIndexPath *originalIndexPath = [NSIndexPath indexPathForRow:indexPath.row
                                                        inSection:originalSection];
    return %orig(tableView, originalIndexPath);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) && section == 0) {
        return 12.0;
    }

    NSInteger originalSection =
        axs_hg999_originalSectionForDisplay(self, tableView, section);
    if (originalSection < 0) {
        return 12.0;
    }
    return %orig(tableView, originalSection);
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) && section == 0) {
        return 12.0;
    }

    NSInteger originalSection =
        axs_hg999_originalSectionForDisplay(self, tableView, section);
    if (originalSection < 0) {
        return 12.0;
    }
    return %orig(tableView, originalSection);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) && section == 0) {
        return nil;
    }

    NSInteger originalSection =
        axs_hg999_originalSectionForDisplay(self, tableView, section);
    if (originalSection < 0) {
        return nil;
    }
    return %orig(tableView, originalSection);
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (axs_hg999_shouldInject(self, tableView) && section == 0) {
        return nil;
    }

    NSInteger originalSection =
        axs_hg999_originalSectionForDisplay(self, tableView, section);
    if (originalSection < 0) {
        return nil;
    }
    return %orig(tableView, originalSection);
}

%end
