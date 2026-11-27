#import <CoreFoundation/CoreFoundation.h>

#import "AxsHG999Private.h"

@interface AxsHG999Config ()
@property (atomic, copy) NSDictionary *snapshot;
@property (nonatomic, strong) dispatch_queue_t reloadQueue;
@end

static void axs_hg999_preferencesDidChange(CFNotificationCenterRef center, void *observer,
                                          CFStringRef name, const void *object, CFDictionaryRef info) {
    AxsHG999Config *config = (__bridge AxsHG999Config *)observer;
    dispatch_async(config.reloadQueue, ^{
        [config axs_hg999_reload];
    });
}

@implementation AxsHG999Config

+ (instancetype)axs_hg999_shared {
    static AxsHG999Config *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _reloadQueue = dispatch_queue_create("com.axs.hg999.preferences", DISPATCH_QUEUE_SERIAL);
        [self axs_hg999_reload];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)self, axs_hg999_preferencesDidChange,
            (__bridge CFStringRef)AxsHG999PreferencesChanged, NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        // 补读首轮读取与注册观察者之间发生的偏好变更。
        dispatch_async(_reloadQueue, ^{ [self axs_hg999_reload]; });
    }
    return self;
}

- (void)axs_hg999_reload {
    self.snapshot = axs_hg999_readPreferences();
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:AxsHG999PreferencesChanged object:self];
    });
}

- (id)axs_hg999_valueForKey:(NSString *)key defaultValue:(id)defaultValue {
    return self.snapshot[key] ?: defaultValue;
}

- (BOOL)axs_hg999_isEnabled {
    id value = [self axs_hg999_valueForKey:@"enabled" defaultValue:@(YES)];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : YES;
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            (__bridge const void *)self);
}

@end
