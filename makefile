ARCHS := arm64
TARGET := iphone:clang:16.5:14.0
DEBUG = 0
FINALPACKAGE = 1
FOR_RELEASE = 1
INSTALL_TARGET_PROCESSES := TrollSpeed

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := TrollSpeed

$(APPLICATION_NAME)_USE_MODULES := 0
$(APPLICATION_NAME)_FILES += $(wildcard sources/*.mm sources/*.m)
$(APPLICATION_NAME)_FILES += $(wildcard sources/KIF/*.mm sources/KIF/*.m)
$(APPLICATION_NAME)_FILES += $(wildcard esp/drawing_view/*.m)
$(APPLICATION_NAME)_FILES += $(wildcard esp/drawing_view/*.mm)
$(APPLICATION_NAME)_FILES += $(wildcard esp/drawing_view/*.cpp)
$(APPLICATION_NAME)_FILES += $(wildcard esp/helpers/*.m)
$(APPLICATION_NAME)_FILES += $(wildcard esp/helpers/*.mm)
$(APPLICATION_NAME)_FILES += $(wildcard esp/unity_api/*.m)
$(APPLICATION_NAME)_FILES += $(wildcard esp/unity_api/*.mm)

sources/KIF/UITouch-KIFAdditions.m_CFLAGS := $(filter-out -mllvm -enable-fco,$(TrollSpeed_CFLAGS))

$(APPLICATION_NAME)_CFLAGS += -fobjc-arc -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-value -Wno-module-import-in-extern-c -Wunused-but-set-variable
$(APPLICATION_NAME)_CFLAGS += -Iheaders
$(APPLICATION_NAME)_CFLAGS += -Isources
$(APPLICATION_NAME)_CFLAGS += -Isources/KIF
$(APPLICATION_NAME)_CFLAGS += -DNOTIFY_DESTROY_HUD="\"dev.metaware.external.hud.destroy\""
$(APPLICATION_NAME)_CFLAGS += -DPID_PATH="@\"/var/mobile/Library/Caches/dev.metaware.external.pid\""
$(APPLICATION_NAME)_CCFLAGS += -std=c++17

$(APPLICATION_NAME)_FRAMEWORKS += CoreGraphics CoreServices QuartzCore IOKit UIKit
$(APPLICATION_NAME)_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices SpringBoardServices
$(APPLICATION_NAME)_CODESIGN_FLAGS += -Slayout/entitlements.plist
$(APPLICATION_NAME)_RESOURCE_DIRS = ./layout/Resources

include $(THEOS_MAKE_PATH)/application.mk

include $(THEOS_MAKE_PATH)/aggregate.mk


after-package::
	@rm -rf Payload
	@mkdir -p Payload
	@cp -r .theos/_/Applications/$(APPLICATION_NAME).app Payload/
	@chmod 755 Payload/$(APPLICATION_NAME).app/$(APPLICATION_NAME)
	@zip -rq $(APPLICATION_NAME).tipa Payload
	@rm -rf Payload
	@mkdir -p packages
	@mv $(APPLICATION_NAME).tipa packages/
	@echo "[*] Success: packages/$(APPLICATION_NAME).tipa"
	
