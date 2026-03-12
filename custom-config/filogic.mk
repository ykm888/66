#
# Copyright (C) 2024-2026 ykm888
# 物理修复：对齐 hanwckf 零件产出与 1024M GPT eMMC 分区打包
#

# --- 1. 定义 GPT eMMC 分区布局 (物理对齐 128M 起始 RootFS) ---
define Build/mt798x-gpt-emmc-production
	ptgen -g -o $@ -a 1 \
		-t 0x83 -N ubootenv -r -p 512k@4M \
		-t 0x83 -N factory -r -p 2M@5M \
		-t 0x83 -N kernel -r -p 64M@64M \
		-t 0x83 -N production -p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
endef

# --- 2. 定义 32MB NOR 救砖合成逻辑 (物理对齐零件名) ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	touch $@.nor
	truncate -s 32M $@.nor
	# 物理定位：从 STAGING_DIR_IMAGE 抓取由 ATF Makefile 产出的 bl2.img
	@test -f $(STAGING_DIR_IMAGE)/bl2.img || { \
		echo "!!! ERROR: ATF零件(bl2.img)未找到，请检查 ATF Makefile 编译状态 !!!"; \
		exit 1; \
	}
	dd if=$(STAGING_DIR_IMAGE)/bl2.img of=$@.nor bs=1k conv=notrunc
	# 物理定位：抓取由 U-Boot Makefile 产出的 fip.bin
	# 注意：在 filogic 架构中，FIP 通常由 mtk-eMMC-pack-fip 产生或直接复用 u-boot.bin
	@test -f $(STAGING_DIR_IMAGE)/$(TFA_PART)-u-boot.bin || { \
		echo "!!! ERROR: FIP零件($(TFA_PART)-u-boot.bin)未找到 !!!"; \
		exit 1; \
	}
	dd if=$(STAGING_DIR_IMAGE)/$(TFA_PART)-u-boot.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 3. 设备定义 (物理锁死 1024M 适配) ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := ykm888
  DEVICE_MODEL := SL-3000
  DEVICE_VARIANT := 1024M-DDR4-eMMC-Flash
  # 物理对齐：确保与 target/linux/mediatek/dts/ 下的文件名严格一致
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := ykm888,sl-3000
  
  # 物理核心：穿透引用我们在 Makefile 中定义的 ATF 零件变体名
  TFA_PART := mt7981-nor-ddr4
  
  DEVICE_PACKAGES := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools kmod-fs-f2fs \
                     kmod-fs-ext4 parted resize2fs luci-app-turboacc-mtk
  
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  
  # 物理合成工序
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | \
                               pad-to 64M | append-kernel | \
                               pad-to 128M | append-rootfs | \
                               append-metadata
endef

TARGET_DEVICES += sl_3000-nor-emm
