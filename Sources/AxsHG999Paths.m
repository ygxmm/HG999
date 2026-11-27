#import "AxsHG999Private.h"

#ifdef THEOS_PACKAGE_SCHEME_ROOTHIDE
#import <roothide.h>
#else
#import <rootless.h>
#endif

// 越狱资源路径适配：根据打包方案应用正确的安装根路径。
NSString *axs_hg999_resourcePath(NSString *rootfsPath) {
#ifdef THEOS_PACKAGE_SCHEME_ROOTHIDE
    return jbroot(rootfsPath);
#else
    return ROOT_PATH_NS_VAR(rootfsPath);
#endif
}

// 偏好文件位于移动用户目录，不随越狱安装路径改写。
NSString *axs_hg999_preferencesPath(void) {
    NSString *path = @"/var/mobile/Library/Preferences/com.axs.hg999.plist";
#ifdef THEOS_PACKAGE_SCHEME_ROOTHIDE
    return jbroot(path);
#else
    return path;
#endif
}
