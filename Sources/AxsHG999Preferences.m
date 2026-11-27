#import <CoreFoundation/CoreFoundation.h>

#import "AxsHG999Private.h"

NSString * const AxsHG999PreferencesDomain = @"com.axs.hg999";
NSString * const AxsHG999PreferencesChanged = @"com.axs.hg999.preferences-changed";

// 优先从偏好文件读取；文件不可用时回退到同域的系统偏好快照。
NSDictionary *axs_hg999_readPreferences(void) {
    NSString *path = axs_hg999_preferencesPath();
    NSDictionary *values = path.length > 0 ? [NSDictionary dictionaryWithContentsOfFile:path] : nil;
    if ([values isKindOfClass:[NSDictionary class]]) {
        return values;
    }
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:AxsHG999PreferencesDomain];
    [defaults synchronize];
    return [defaults persistentDomainForName:AxsHG999PreferencesDomain] ?: @{};
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

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:AxsHG999PreferencesDomain];
    // 同步写入完整快照，避免系统偏好服务刷回过期的其他键值。
    [defaults setPersistentDomain:values forName:AxsHG999PreferencesDomain];
    [defaults synchronize];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
        (__bridge CFStringRef)AxsHG999PreferencesChanged, NULL, NULL, true);
    return YES;
}
