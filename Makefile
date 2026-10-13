ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = StikJITVPNAutoStart
StikJITVPNAutoStart_FILES = Tweak.x
StikJITVPNAutoStart_FRAMEWORKS = Foundation UIKit NetworkExtension
StikJITVPNAutoStart_CFLAGS = -fobjc-arc
StikJITVPNAutoStart_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
