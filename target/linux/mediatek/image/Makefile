# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

DEVICE_VARS += NETGEAR_ENC_MODEL NETGEAR_ENC_REGION NETGEAR_ENC_HW_ID_LIST NETGEAR_ENC_MODEL_LIST

# 物理地址修正
loadaddr-$(CONFIG_TARGET_mediatek_mt7622) := 0x44000000
loadaddr-$(CONFIG_TARGET_mediatek_mt7623) := 0x80008000
loadaddr-$(CONFIG_TARGET_mediatek_mt7629) := 0x40008000
loadaddr-$(CONFIG_TARGET_mediatek_filogic) := 0x44000000

# 默认设备模板
define Device/Default
  PROFILES = Default $$(DEVICE_NAME)
  KERNEL_NAME := Image
  KERNEL = kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS = kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd
  KERNEL_LOADADDR = $(loadaddr-y)
  FILESYSTEMS := squashfs
  DEVICE_DTS_DIR := $(DTS_DIR)
  ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3
  IMAGES := sysupgrade.bin factory.img.gz
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  IMAGE/factory.img.gz := mt798x-gpt emmc |\
	pad-to 17k | mt7981-bl2 emmc-ddr3 |\
	pad-to 6656k | mt7981-bl31-uboot emmc-ddr3 |\
	pad-to 64M | append-image squashfs-sysupgrade.itb | gzip
endef

# 【关键点：物理对齐检查】确保这一行前后没有非法字符
-include $(SUBTARGET).mk

define Image/Build
	$(call Image/Build/$(1),$(1))
endef

$(eval $(call BuildImage))
