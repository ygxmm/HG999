#import "AxsHG999Private.h"

@implementation AxsHG999SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"HG999"];

    // 沿用红果原生导航栏、自适应背景与分组间距。
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.rowHeight = 56.0;
    self.tableView.sectionHeaderHeight = 12.0;
    self.tableView.sectionFooterHeight = 12.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return axs_hg999_createVideoFullscreenOptionCell(tableView);
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:nil];
}

@end
