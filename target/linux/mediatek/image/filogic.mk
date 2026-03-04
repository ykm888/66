#
# SPDX-License-Identifier: GPL-2.0-only
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# 修正后的 GPT 分区表（64K 对齐，连续不重叠）
# 格式：Size@Offset:Name
MTK_GPT_PARTS_SL3000 := \
	256k@64k:preloader \
	512k@320k:bl31 \
	2048k@832k:u-boot \
	256k@2880k:u-boot-env \
	256k@3136k:factory \
	512k@3392k:production \
	20480k@3904k:recovery \
	-@24384k:userdata

# GPT 生成宏（基于 ptgen）
define Build/mt798x-gpt
	rm -f $@.gpt
	$(STAGING_DIR_HOST)/bin/ptgen \
		-g -o $@.gpt \
		-a 1 -l 1024 \
		-s 512 \
		$(foreach part,$(1), -p $(part))
	dd if=$@.gpt of=$@ conv=notrunc 2>/dev/null
	rm -f $@.gpt
endef

# 在指定偏移（KB）写入文件
define Build/write-at-offset
	( \
		offset_kb=$(1); \
		src_file="$(2)"; \
		[ -f "$$src_file" ] || { echo "Error: $$src_file not found"; exit 1; }; \
		dd if="$$src_file" of="$@" bs=1k seek=$$offset_kb conv=notrunc 2>/dev/null; \
	)
endef

# 写入 BL2（文件名与 U-Boot 包生成一致）
define Build/mt7981-bl2
	$(call Build/write-at-offset,64,$(STAGING_DIR_HOST)/share/u-boot/mt7981-$(1)-bl2.bin)
endef

# 写入 FIP（BL31 + U-Boot）
define Build/mt7981-bl31-uboot
	$(call Build/write-at-offset,320,$(STAGING_DIR_HOST)/share/u-boot/mt7981-$(1)-fip.bin)
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
  ARTIFACT/emmc-gpt.bin := mt798x-gpt "$(MTK_GPT_PARTS_SL3000)"
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3

  IMAGES := sysupgrade.bin factory.img.gz
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

  # 工厂镜像构建：所有命令写在一行，避免续行符后出现 Tab
  IMAGE/factory.img.gz := dd if=/dev/zero of="$@" bs=1M count=64 2>/dev/null && \
	$(call Build/mt798x-gpt,$(MTK_GPT_PARTS_SL3000)) && \
	$(call Build/mt7981-bl2,emmc-ddr3) && \
	$(call Build/mt7981-bl31-uboot,emmc-ddr3) && \
	$(call Build/write-at-offset,24384,$(KDIR)/squashfs-sysupgrade.itb) && \
	gzip -f "$@"
endef

TARGET_DEVICES += sl_3000-emmc

$(eval $(call BuildImage))
