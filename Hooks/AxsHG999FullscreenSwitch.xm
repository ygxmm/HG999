#import "AxsHG999Private.h"

%hook SSSettingTableViewCell

- (void)layoutSubviews {
    %orig;
    if (axs_hg999_isFullscreenSettingCell(self)) {
        axs_hg999_prepareFullscreenSettingCell(self);
    }
}

%end
