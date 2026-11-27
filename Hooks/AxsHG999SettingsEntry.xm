#import <UIKit/UIKit.h>

#import "AxsHG999Private.h"

// 只处理红果原生设置主表，不改动其他表格或系统设置界面。
static BOOL axs_hg999_shouldInject(SSSettingViewController *controller,
                                    UITableView *tableView) {
    return tableView == controller.tableView &&
           [[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled];
}

// 在红果原有分组最前方插入 HG999，不重排原有分组。
// 标记当前线程正在执行红果原生回调，避免 self 重入时重复转换索引。
static NSString * const axs_hg999_forwardingNativeCallbackKey =
    @"com.axs.hg999.forwarding-native-settings-callback";

static BOOL axs_hg999_isForwardingNativeCallback(void) {
    return [NSThread.currentThread.threadDictionary[
        axs_hg999_forwardingNativeCallbackKey] unsignedIntegerValue] > 0;
}

static void axs_hg999_beginNativeCallback(void) {
    NSMutableDictionary *threadDictionary = NSThread.currentThread.threadDictionary;
    NSUInteger depth = [threadDictionary[axs_hg999_forwardingNativeCallbackKey]
                        unsignedIntegerValue];
    threadDictionary[axs_hg999_forwardingNativeCallbackKey] = @(depth + 1);
}

static void axs_hg999_endNativeCallback(void) {
    NSMutableDictionary *threadDictionary = NSThread.currentThread.threadDictionary;
    NSUInteger depth = [threadDictionary[axs_hg999_forwardingNativeCallbackKey]
                        unsignedIntegerValue];
    if (depth <= 1) {
        [threadDictionary removeObjectForKey:axs_hg999_forwardingNativeCallbackKey];
    } else {
        threadDictionary[axs_hg999_forwardingNativeCallbackKey] = @(depth - 1);
    }
}

%hook SSSettingViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (axs_hg999_isForwardingNativeCallback() ||
        !axs_hg999_shouldInject(self, tableView)) {
        axs_hg999_beginNativeCallback();
        NSInteger result = 0;
        @try {
            result = %orig;
        } @finally {
            axs_hg999_endNativeCallback();
        }
        return result;
    }

    axs_hg999_beginNativeCallback();
    NSInteger originalCount = 0;
    @try {
        originalCount = %orig;
    } @finally {
        axs_hg999_endNativeCallback();
    }
    return originalCount + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (axs_hg999_isForwardingNativeCallback()) {
        return %orig;
    }

    if (!axs_hg999_shouldInject(self, tableView)) {
        axs_hg999_beginNativeCallback();
        NSInteger result = 0;
        @try { result = %orig; }
        @finally { axs_hg999_endNativeCallback(); }
        return result;
    }
    if (section == 0) {
        return 1;
    }

    NSInteger originalSection = section - 1;
    if (originalSection < 0) {
        return 0;
    }
    axs_hg999_beginNativeCallback();
    NSInteger result = 0;
    @try { result = %orig(tableView, originalSection); }
    @finally { axs_hg999_endNativeCallback(); }
    return result;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (axs_hg999_isForwardingNativeCallback()) {
        return %orig;
    }
    if (!axs_hg999_shouldInject(self, tableView)) {
        axs_hg999_beginNativeCallback();
        UITableViewCell *result = nil;
        @try { result = %orig; }
        @finally { axs_hg999_endNativeCallback(); }
        return result;
    }
    if (indexPath.section == 0 && indexPath.row == 0) {
        return axs_hg999_createSettingsEntryCell(self, tableView);
    }

    NSInteger originalSection = indexPath.section - 1;
    if (originalSection < 0) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:nil];
    }
    NSIndexPath *originalIndexPath = [NSIndexPath indexPathForRow:indexPath.row
                                                        inSection:originalSection];
    axs_hg999_beginNativeCallback();
    UITableViewCell *result = nil;
    @try { result = %orig(tableView, originalIndexPath); }
    @finally { axs_hg999_endNativeCallback(); }
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (axs_hg999_isForwardingNativeCallback()) {
        return %orig;
    }
    if (!axs_hg999_shouldInject(self, tableView)) {
        axs_hg999_beginNativeCallback();
        CGFloat result = 0.0;
        @try { result = %orig; }
        @finally { axs_hg999_endNativeCallback(); }
        return result;
    }
    if (indexPath.section == 0 && indexPath.row == 0) {
        return 56.0;
    }

    NSInteger originalSection = indexPath.section - 1;
    if (originalSection < 0) {
        return tableView.rowHeight;
    }
    NSIndexPath *originalIndexPath = [NSIndexPath indexPathForRow:indexPath.row
                                                        inSection:originalSection];
    axs_hg999_beginNativeCallback();
    CGFloat result = 0.0;
    @try { result = %orig(tableView, originalIndexPath); }
    @finally { axs_hg999_endNativeCallback(); }
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (axs_hg999_isForwardingNativeCallback()) {
        return %orig;
    }
    if (!axs_hg999_shouldInject(self, tableView)) {
        axs_hg999_beginNativeCallback();
        CGFloat result = 0.0;
        @try { result = %orig; }
        @finally { axs_hg999_endNativeCallback(); }
        return result;
    }
    if (section == 0) {
        return 12.0;
    }

    NSInteger originalSection = section - 1;
    axs_hg999_beginNativeCallback();
    CGFloat result = 0.0;
    @try { result = %orig(tableView, originalSection); }
    @finally { axs_hg999_endNativeCallback(); }
    return result;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (axs_hg999_isForwardingNativeCallback()) {
        return %orig;
    }
    if (!axs_hg999_shouldInject(self, tableView)) {
        axs_hg999_beginNativeCallback();
        CGFloat result = 0.0;
        @try { result = %orig; }
        @finally { axs_hg999_endNativeCallback(); }
        return result;
    }
    if (section == 0) {
        return 12.0;
    }

    NSInteger originalSection = section - 1;
    axs_hg999_beginNativeCallback();
    CGFloat result = 0.0;
    @try { result = %orig(tableView, originalSection); }
    @finally { axs_hg999_endNativeCallback(); }
    return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (axs_hg999_isForwardingNativeCallback()) {
        return %orig;
    }
    if (!axs_hg999_shouldInject(self, tableView)) {
        axs_hg999_beginNativeCallback();
        UIView *result = nil;
        @try { result = %orig; }
        @finally { axs_hg999_endNativeCallback(); }
        return result;
    }
    if (section == 0) {
        return nil;
    }

    NSInteger originalSection = section - 1;
    axs_hg999_beginNativeCallback();
    UIView *result = nil;
    @try { result = %orig(tableView, originalSection); }
    @finally { axs_hg999_endNativeCallback(); }
    return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (axs_hg999_isForwardingNativeCallback()) {
        return %orig;
    }
    if (!axs_hg999_shouldInject(self, tableView)) {
        axs_hg999_beginNativeCallback();
        UIView *result = nil;
        @try { result = %orig; }
        @finally { axs_hg999_endNativeCallback(); }
        return result;
    }
    if (section == 0) {
        return nil;
    }

    NSInteger originalSection = section - 1;
    axs_hg999_beginNativeCallback();
    UIView *result = nil;
    @try { result = %orig(tableView, originalSection); }
    @finally { axs_hg999_endNativeCallback(); }
    return result;
}

%end
