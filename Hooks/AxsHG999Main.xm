#import "AxsHG999Private.h"

%ctor {
    @autoreleasepool {
        // 启动配置模块并载入当前偏好快照。
        (void)[[AxsHG999Config axs_hg999_shared] axs_hg999_isEnabled];
    }
}
