# AovDarksword 1.4 — Theos Makefile for SRD
# Build: make package FINALPACKAGE=1
# Install: make install THEOS_DEVICE_IP=<SRD_IP>

ARCHS = arm64
TARGET := iphone:clang:latest:17.0
INSTALL_TARGET_PROCESSES = AovCheat

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = AovDarksword

# === Source Files ===

AovDarksword_FILES = \
	main.m \
	AppDelegate.m \
	SceneDelegate.m \
	ViewController.m \
	CoreRuntime.m \
	KFCameraSettingsVC.m \
	Core/task_for_pid.c \
	Core/krw.c \
	Core/kexploit.c \
	Core/sandbox_patch.c \
	Core/remote_call.c \
	Core/mig_bypass.c \
	Core/grab_kernelcache.m \
	Core/vm_shmem.c \
	Game/il2cpp_resolver.c \
	Game/hero_helper.m \
	Game/game_state.c \
	HUD/KFHUDWindow.m \
	HUD/KFHUDESPView.m \
	HUD/KFESPView.m \
	HUD/overlay_manager.m \
	HUD/SecureESPField.m \
	HUD/DisplayLayer.m \
	HUD/ContentLayer.m \
	HUD/KFHUDAppDelegate.m \
	HUD/KFHUDViewController.m \
	HUD/metal_hud.m \
	HUD/hud_launcher.m \
	Mod/ModFile.m \
	Mod/VideoSanh.m \
	Tweaks/StatusBarTweak.m \
	Tweaks/HideLabels.m \
	Tweaks/FiveIconDock.m \
	Utils/AudioKeepAlive.m \
	Utils/DeviceInfo.m

# === Compiler Flags ===

AovDarksword_CFLAGS = \
	-fobjc-arc \
	-Wno-unused-variable \
	-Wno-unused-function \
	-ICore -IGame -IHUD -IMod -ITweaks -IUtils \
	-DVERSION=\"1.4\"

AovDarksword_CCFLAGS = $(AovDarksword_CFLAGS)

AovDarksword_LDFLAGS = -L$(THEOS_OBJ_DIR) -lxpf

# === Frameworks ===

AovDarksword_FRAMEWORKS = \
	Foundation UIKit QuartzCore CoreGraphics \
	IOSurface Photos PhotosUI Security \
	MobileCoreServices UniformTypeIdentifiers \
	AVFAudio AVKit CoreFoundation \
	SafariServices WebKit

AovDarksword_PRIVATE_FRAMEWORKS = \
	BackBoardServices \
	FrontBoardServices \
	SpringBoardServices

AovDarksword_LIBRARIES = c++ z

# === Codesign ===

AovDarksword_CODESIGN_FLAGS = \
	-SAovDarksword.entitlements \
	--entitlements AovDarksword.entitlements

# === Install ===

after-install::
	install.exec "killall -9 AovCheat 2>/dev/null; true"

include $(THEOS_MAKE_PATH)/application.mk

# === Copy libxpf.dylib ===

after-stage::
	@echo "Copying libxpf.dylib..."
	@cp -f ../Payload/libxpf.dylib $(THEOS_STAGING_DIR)/Applications/AovDarksword.app/libxpf.dylib
	@echo "Copying Settings.bundle..."
	@cp -rf ../Payload/Settings.bundle $(THEOS_STAGING_DIR)/Applications/AovDarksword.app/Settings.bundle
	@echo "Copying Info.plist..."
	@cp -f Info.plist $(THEOS_STAGING_DIR)/Applications/AovDarksword.app/Info.plist
