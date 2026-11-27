DEBUG ?= 0
FINALPACKAGE ?= 1
ARCHS = arm64 arm64e

# 无根目录与隐藏根目录打包方案要求最低支持 iOS 15。
ifneq ($(filter rootless roothide,$(THEOS_PACKAGE_SCHEME)),)
TARGET = iphone:clang:16.5:15.0
else
TARGET = iphone:clang:16.5:15.0
endif
