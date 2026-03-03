# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

DEVICE_VARS += NETGEAR_ENC_MODEL NETGEAR_ENC_REGION NETGEAR_ENC_HW_ID_LIST NETGEAR_ENC_MODEL_LIST

# 物理内存加载地址定义
loadaddr-$(CONFIG_TARGET_mediatek_mt7622) := 0x44000000
loadaddr-$(CONFIG_TARGET_mediatek_mt7623) := 0x80008000
loadaddr-$(CONFIG_TARGET_mediatek_mt7629) := 0x40008000
loadaddr-$(CONFIG_TARGET_mediatek_filogic) := 0x44000000

# 全局默认设备模板
define Device/Default
  PROFILES = Default $$(DEVICE_NAME)
  KERNEL_NAME := Image
  KERNEL = kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS = kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd
  KERNEL_LOADADDR = $(loadaddr-y)
  FILESYSTEMS := squashfs
  DEVICE_DTS_DIR := $(DTS_DIR)
endef

# 物理审计点：必须包含此行以引入 filogic.mk
-include $(SUBTARGET).mk

define Image/Build
	$(call Image/Build/$(1),$(1))
endef

$(eval $(call BuildImage))
