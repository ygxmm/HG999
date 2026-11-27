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

// 返回红果应用容器内偏好文件的可写路径，不使用系统全局偏好目录。
NSString *axs_hg999_preferencesPath(void) {
    NSURL *url = [[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                        inDomains:NSUserDomainMask].firstObject;
    if (!url) {
        return nil;
    }
    return [[url URLByAppendingPathComponent:@"HG999" isDirectory:YES]
            URLByAppendingPathComponent:@"preferences.plist"].path;
}
