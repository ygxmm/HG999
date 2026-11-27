DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64 arm64e

# 编译工具包与部署目标由主插件和设置面板共用。
include AxsHG999Build.mk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AxsHG999
AxsHG999_FILES = $(wildcard Hooks/*.xm Sources/*.m)
AxsHG999_CFLAGS = -fobjc-arc -I./Headers -I./Sources
AxsHG999_FRAMEWORKS = UIKit Foundation CoreFoundation
AxsHG999_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
