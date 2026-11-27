#import <objc/message.h>
#import <objc/runtime.h>

#import "AxsHG999Private.h"

// 通过运行时名称查找原生单元格，避免把红果私有类链接到插件二进制。
UITableViewCell *axs_hg999_dequeueNativeSettingCell(UITableView *tableView,
                                                     NSString *reuseIdentifier) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell) {
        return cell;
    }

    Class cellClass = objc_getClass("SSSettingTableViewCell");
    if (!cellClass) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:reuseIdentifier];
    }

    id allocated = ((id (*)(id, SEL))objc_msgSend)(cellClass, @selector(alloc));
    id initialized = ((id (*)(id, SEL, NSInteger, id))objc_msgSend)(
        allocated, @selector(initWithStyle:reuseIdentifier:),
        UITableViewCellStyleDefault, reuseIdentifier);
    return [initialized isKindOfClass:[UITableViewCell class]] ? initialized : nil;
}
