#
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# 修正后的 GPT 分区表（64K 对齐，连续不重叠）
MTK_GPT_PARTS := 256k@64k:preloader 512k@320k:bl31 2048k@832k:u-boot 256k@2880k:u-boot-env 256k@3136k:factory 512k@3392k:production 20480k@3904k:recovery -@24384k:userdata

# GPT 构建宏
define Build/mt798x-gpt
	rm -f $@
	touch $@
	$(STAGING_DIR_HOST)/bin/ptgen \
		-g -o $@.gpt \
		-a 1 -l 1024 \
		$(if $(findstring sd,$(1)), -s 512) \
		$(if $(findstring emmc,$(1)), -s 512) \
		$(foreach part,$(MTK_GPT_PARTS), -p $(part))
	cat $@.gpt >> $@
endef

# 写入 BL2
define Build/mt7981-bl2
	@echo "--- 写入 BL2 ---"
	mkdir -p $(STAGING_DIR_HOST)/share/u-boot
	cat $(STAGING_DIR_HOST)/share/u-boot/mt7981-$(1)-bl2.bin >> $@
endef

# 写入 FIP
define Build/mt7981-bl31-uboot
	cat $(STAGING_DIR_HOST)/share/u-boot/mt7981-$(1)-fip.bin >> $@
endef

# SL-3000 eMMC 设备定义
define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DRAM_SIZE := 1024M
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb

  ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3

  IMAGES := sysupgrade.bin factory.img.gz
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

  # 工厂镜像构建：采用单行命令，避免续行缩进问题
  # 注意：此处的 pad-to 偏移量已调整为与新分区表一致（17k 为 GPT 表预估大小，64k 为 preloader 起始，320k 为 bl31 起始，24384k 为根文件系统起始）
  IMAGE/factory.img.gz := mt798x-gpt emmc | pad-to 17k | mt7981-bl2 emmc-ddr3 | pad-to 320k | mt7981-bl31-uboot emmc-ddr3 | pad-to 24384k | append-image squashfs-sysupgrade.itb | gzip
endef

TARGET_DEVICES += sl_3000-emmc
