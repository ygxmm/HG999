#import "AxsHG999Private.h"

// 设置行模块：创建原生入口单元格，并将点击操作路由到 HG999 页面。
UITableViewCell *axs_hg999_createSettingsEntryCell(SSSettingViewController *controller,
                                                   UITableView *tableView) {
    static NSString * const reuseIdentifier = @"AxsHG999.settings.entry";
    SSSettingTableViewCell *cell =
        (SSSettingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[SSSettingTableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
                reuseIdentifier:reuseIdentifier];
    }

    cell.titleStr = @"HG999";
    cell.shouldShowRightArrow = YES;
    cell.shouldShowTopCorner = YES;
    cell.shouldShowBottomCorner = YES;

    __weak SSSettingViewController *weakController = controller;
    cell.callback = [^{
        __strong SSSettingViewController *strongController = weakController;
        UINavigationController *navigationController = strongController.navigationController;
        if (!strongController || !navigationController) {
            return;
        }

        AxsHG999SettingsViewController *page =
            [[AxsHG999SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [navigationController pushViewController:page animated:YES];
    } copy];
    return cell;
}
