#
# Copyright (C) 2024-2026 ykm888
# 司络 SL-3000 硬件终极适配版 (512M RAM 稳定模式)
#

# --- 1. 定义 GPT eMMC 分区布局 (物理对齐 128G 硬件) ---
# 注意：production 分区直接给 1024M，不再受 32M Flash 限制
define Build/mt798x-gpt-emmc-production
	ptgen -g -o $@ -a 1 \
		-t 0x83 -N ubootenv -r -p 512k@4M \
		-t 0x83 -N factory -r -p 2M@5M \
		-t 0x83 -N kernel -r -p 64M@64M \
		-t 0x83 -N production -p 1024M@128M
endef

# --- 2. 定义 32MB NOR 救砖全家桶 (物理真名搜索版) ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	touch $@.nor
	# 物理红线：强行锁定 32MB 空间，适配 25Q256 芯片
	truncate -s 32M $@.nor
	
	# [物理零件 A]: 智能搜寻 BL2 (ATF)
	# 物理修正：对齐 trusted-firmware-a.mk 生成的真实文件名
	BL2_FILE=""; \
	[ -f "$(STAGING_DIR_IMAGE)/bl2.img" ] && BL2_FILE="$(STAGING_DIR_IMAGE)/bl2.img"; \
	[ -z "$$BL2_FILE" -a -f "$(KDIR)/bl2.img" ] && BL2_FILE="$(KDIR)/bl2.img"; \
	[ -z "$$BL2_FILE" -a -f "$(STAGING_DIR_IMAGE)/trusted-firmware-a-$(TFA_PART)-bl2.bin" ] && BL2_FILE="$(STAGING_DIR_IMAGE)/trusted-firmware-a-$(TFA_PART)-bl2.bin"; \
	if [ -n "$$BL2_FILE" ]; then \
		echo "Physical Found BL2: $$BL2_FILE"; \
		dd if=$$BL2_FILE of=$@.nor bs=1k conv=notrunc; \
	else \
		echo "!!! ERROR: bl2.img 未找到，物理名匹配失败 !!!"; exit 1; \
	fi; \
	
	# [物理零件 B]: 智能搜寻 U-Boot 并注入 1MB (1024k) 偏移
	# 物理修正：对齐 uboot-mediatek 导出的变体名
	UBOOT_FILE=""; \
	[ -f "$(STAGING_DIR_IMAGE)/uboot-$(TFA_PART)-u-boot.bin" ] && UBOOT_FILE="$(STAGING_DIR_IMAGE)/uboot-$(TFA_PART)-u-boot.bin"; \
	[ -z "$$UBOOT_FILE" -a -f "$(STAGING_DIR_IMAGE)/u-boot.bin" ] && UBOOT_FILE="$(STAGING_DIR_IMAGE)/u-boot.bin"; \
	if [ -n "$$UBOOT_FILE" ]; then \
		echo "Physical Found U-Boot: $$UBOOT_FILE"; \
		dd if=$$UBOOT_FILE of=$@.nor bs=1k seek=1024 conv=notrunc; \
	else \
		echo "!!! ERROR: u-boot.bin 未找到 !!!"; exit 1; \
	fi; \
	
	cp $@.nor $@
	rm -f $@.nor
endef

# --- 3. 设备定义 (物理闭环) ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := ykm888
  DEVICE_MODEL := SL-3000
  DEVICE_VARIANT := 512M-RAM-Stable
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := ykm888,sl-3000
  
  # 物理零件索引：对齐你的 Makefile 中定义的变体名
  TFA_PART := mt7981-nor-ddr4
  
  # 物理驱动包：开启 128G eMMC 支持
  DEVICE_PACKAGES := kmod-mmc-mtk kmod-mtk-sd f2fs-tools kmod-fs-f2fs \
                     kmod-fs-ext4 parted resize2fs
  
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  
  # 物理拼接指令
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | pad-to 64M | append-kernel | pad-to 128M | append-rootfs | append-metadata
endef

TARGET_DEVICES += sl_3000-nor-emmc
