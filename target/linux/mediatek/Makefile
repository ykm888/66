#
# Copyright (c) 2015-2024 OpenWrt.org
#
include $(TOPDIR)/rules.mk

# 物理修复核心：将 ARCH 改为 aarch64
# 官方源码用 arm 是为了兼容老旧设备，但对于 MT7981 救砖，必须锁死 aarch64
ARCH:=aarch64
BOARD:=mediatek
BOARDNAME:=MediaTek Filogic (SL-3000 Dedicated)
# 物理切除：只保留 filogic，避免 mt7622/7623 等 32 位依赖污染索引
SUBTARGETS:=filogic
FEATURES:=dt-overlay emmc fpu gpio nand pci pcie rootfs-part separate_ramdisk squashfs usb

# 锁定 Kernel 5.15
KERNEL_PATCHVER:=5.15

include $(INCLUDE_DIR)/target.mk

# 精简默认包，只保留基础支持
DEFAULT_PACKAGES += \
	kmod-leds-gpio kmod-gpio-button-hotplug \
	autocore-arm

$(eval $(call BuildTarget))
