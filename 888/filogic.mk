#
# Copyright (C) 2024-2026 ykm888
# 物理修复 4 版：增强型物理路径搜寻，解决 bl2.img 缺失导致的 Error 1
#

# --- 1. 定义 GPT eMMC 分区布局 (物理对齐 128M 起始 RootFS) ---
define Build/mt798x-gpt-emmc-production
	ptgen -g -o $@ -a 1 \
		-t 0x83 -N ubootenv -r -p 512k@4M \
		-t 0x83 -N factory -r -p 2M@5M \
		-t 0x83 -N kernel -r -p 64M@64M \
		-t 0x83 -N production -p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
endef

# --- 2. 定义 32MB NOR 救砖合成逻辑 (4版：物理增强搜寻) ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	touch $@.nor
	# 物理锁定 32MB 空间
	truncate -s 32M $@.nor
	
	# [物理零件 A]: 智能搜寻 ATF 零件 (bl2.img)
	# 物理优先级：1. Staging Image 2. KDIR (工地直取) 3. TFA_PART 变体名
	BL2_FILE=""; \
	[ -f "$(STAGING_DIR_IMAGE)/bl2.img" ] && BL2_FILE="$(STAGING_DIR_IMAGE)/bl2.img"; \
	[ -z "$$BL2_FILE" -a -f "$(KDIR)/bl2.img" ] && BL2_FILE="$(KDIR)/bl2.img"; \
	[ -z "$$BL2_FILE" -a -f "$(STAGING_DIR_IMAGE)/$(TFA_PART)-bl2.bin" ] && BL2_FILE="$(STAGING_DIR_IMAGE)/$(TFA_PART)-bl2.bin"; \
	[ -z "$$BL2_FILE" -a -f "$(KDIR)/$(TFA_PART)-bl2.bin" ] && BL2_FILE="$(KDIR)/$(TFA_PART)-bl2.bin"; \
	if [ -n "$$BL2_FILE" ]; then \
		echo "Physical Found BL2: $$BL2_FILE"; \
		dd if=$$BL2_FILE of=$@.nor bs=1k conv=notrunc; \
	else \
		echo "!!! ERROR: bl2.img 未找到，物理零件缺失 !!!"; \
		echo "Searching in KDIR: $(KDIR)"; ls -l $(KDIR)/*.bin || true; \
		exit 1; \
	fi; \
	
	# [物理零件 B]: 智能搜寻 U-Boot 零件 (u-boot.bin)
	UBOOT_FILE=""; \
	[ -f "$(STAGING_DIR_IMAGE)/$(TFA_PART)-u-boot.bin" ] && UBOOT_FILE="$(STAGING_DIR_IMAGE)/$(TFA_PART)-u-boot.bin"; \
	[ -z "$$UBOOT_FILE" -a -f "$(KDIR)/$(TFA_PART)-u-boot.bin" ] && UBOOT_FILE="$(KDIR)/$(TFA_PART)-u-boot.bin"; \
	[ -z "$$UBOOT_FILE" -a -f "$(STAGING_DIR_IMAGE)/u-boot.bin" ] && UBOOT_FILE="$(STAGING_DIR_IMAGE)/u-boot.bin"; \
	if [ -n "$$UBOOT_FILE" ]; then \
		echo "Physical Found U-Boot: $$UBOOT_FILE"; \
		dd if=$$UBOOT_FILE of=$@.nor bs=1k seek=1024 conv=notrunc; \
	else \
		echo "!!! ERROR: u-boot.bin 未找到，物理链路断裂 !!!"; exit 1; \
	fi; \
	
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 3. 设备定义 (SL-3000 物理闭环) ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := ykm888
  DEVICE_MODEL := SL-3000
  DEVICE_VARIANT := 512M/1024M-Auto-Adaptive
  # 物理路径：必须与 target/linux/mediatek/dts/ 下的文件名对齐
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := ykm888,sl-3000
  
  # 物理零件索引：必须与 U-Boot/ATF Makefile 里的 VARIANT (mt7981-nor-ddr4) 严格物理对应
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
