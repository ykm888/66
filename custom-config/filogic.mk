#
# Copyright (C) 2024-2026 ykm888
# 物理修复：对齐零件产出与 32MB NOR + GPT eMMC 混合打包逻辑
#

# --- 1. 定义 GPT eMMC 分区布局 (物理对齐 128M 起始 RootFS) ---
define Build/mt798x-gpt-emmc-production
	ptgen -g -o $@ -a 1 \
		-t 0x83 -N ubootenv -r -p 512k@4M \
		-t 0x83 -N factory -r -p 2M@5M \
		-t 0x83 -N kernel -r -p 64M@64M \
		-t 0x83 -N production -p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
endef

# --- 2. 定义 32MB NOR 救砖合成逻辑 (物理锁死 32768KB) ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	touch $@.nor
	# 物理锁定 32MB 空间
	truncate -s 32M $@.nor
	
	# [物理零件 A]: 抓取 ATF 产出的 bl2.img (写入 0 偏移)
	@test -f $(STAGING_DIR_IMAGE)/bl2.img || { \
		echo "!!! ERROR: bl2.img 未找到，请检查 ATF 编译状态 !!!"; \
		exit 1; \
	}
	dd if=$(STAGING_DIR_IMAGE)/bl2.img of=$@.nor bs=1k conv=notrunc
	
	# [物理零件 B]: 抓取 U-Boot 产出的 fip (写入 1024KB 偏移)
	# 注意：我们使用 $(TFA_PART)-u-boot.bin 来物理匹配 Makefile 中的定义
	@test -f $(STAGING_DIR_IMAGE)/$(TFA_PART)-u-boot.bin || { \
		echo "!!! ERROR: $(TFA_PART)-u-boot.bin 未找到，请检查 U-Boot Makefile !!!"; \
		exit 1; \
	}
	dd if=$(STAGING_DIR_IMAGE)/$(TFA_PART)-u-boot.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 3. 设备定义 (SL-3000 物理闭环) ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := ykm888
  DEVICE_MODEL := SL-3000
  DEVICE_VARIANT := 512M/1024M-Auto-Adaptive
  # 物理路径：必须与 target/linux/mediatek/dts/ 下的脚本一致
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := ykm888,sl-3000
  
  # 物理零件索引：必须与 U-Boot/ATF Makefile 里的 VARIANT 严格一致
  TFA_PART := mt7981-nor-ddr4
  
  DEVICE_PACKAGES := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools kmod-fs-f2fs \
                     kmod-fs-ext4 parted resize2fs luci-app-turboacc-mtk
  
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  
  # 物理合体动作
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | \
                               pad-to 64M | append-kernel | \
                               pad-to 128M | append-rootfs | \
                               append-metadata
endef

TARGET_DEVICES += sl_3000-nor-emmc
