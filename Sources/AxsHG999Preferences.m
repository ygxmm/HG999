#import <CoreFoundation/CoreFoundation.h>

#import "AxsHG999Private.h"

NSString * const AxsHG999PreferencesDomain = @"com.axs.hg999";
NSString * const AxsHG999PreferencesChanged = @"com.axs.hg999.preferences-changed";

// 从红果应用容器内读取插件偏好，未创建文件时返回空配置。
NSDictionary *axs_hg999_readPreferences(void) {
    NSString *path = axs_hg999_preferencesPath();
    NSDictionary *values = path.length > 0 ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
    return [values isKindOfClass:[NSDictionary class]] ? values : @{};
}

// 由 HG999 设置页面调用，原子保存配置并同步发布变更通知。
BOOL axs_hg999_writePreference(NSString *key, id value, NSError **error) {
    NSString *path = axs_hg999_preferencesPath();
    if (key.length == 0 || path.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:AxsHG999PreferencesDomain code:1
                                    userInfo:@{NSLocalizedDescriptionKey: @"偏好设置路径或键无效"}];
        }
        return NO;
    }

    NSFileManager *manager = [NSFileManager defaultManager];
    NSMutableDictionary *values;
    if ([manager fileExistsAtPath:path]) {
        NSData *existing = [NSData dataWithContentsOfFile:path options:0 error:error];
        id decoded = existing ? [NSPropertyListSerialization propertyListWithData:existing
                         options:NSPropertyListMutableContainers format:NULL error:error] : nil;
        if (![decoded isKindOfClass:[NSDictionary class]]) {
            if (error && !*error) {
                *error = [NSError errorWithDomain:AxsHG999PreferencesDomain code:2
                                        userInfo:@{NSLocalizedDescriptionKey: @"偏好设置数据不是字典"}];
            }
            return NO;
        }
        values = [decoded mutableCopy];
    } else {
        values = [axs_hg999_readPreferences() mutableCopy];
    }

    if (value) values[key] = value;
    else [values removeObjectForKey:key];
    if (![manager createDirectoryAtPath:[path stringByDeletingLastPathComponent]
            withIntermediateDirectories:YES attributes:nil error:error]) {
        return NO;
    }

    NSData *data = [NSPropertyListSerialization dataWithPropertyList:values
                         format:NSPropertyListBinaryFormat_v1_0 options:0 error:error];
    if (!data || ![data writeToFile:path options:NSDataWritingAtomic error:error]) {
        return NO;
    }

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge CFStringRef)AxsHG999PreferencesChanged, NULL, NULL, true);
    return YES;
}
