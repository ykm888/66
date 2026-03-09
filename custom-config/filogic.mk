#
# SL-3000 物理定制版：针对 NOR-BOOT + eMMC-STORAGE + 1024M-RAM
#

# 物理组件包：修正 5.15 下的包名冲突，确保 eMMC 格式化工具物理就位
SL3000_PKGS := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools e2fsprogs kmod-fs-f2fs \
               kmod-fs-ext4 parted resize2fs datconf-lua luci-app-mtk

# --- 物理修正：生成 32MB NOR 编程器固件 ---
define Build/sl3000-nor-bundle
	# 物理合成：BL2 必须是 DDR4 1024M 版本
	rm -f $@.nor
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	# 物理校验：请核实编译输出目录下 FIP 的确切文件名，通常不带 u-boot 字样
	[ -f $(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin ] && \
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	# 物理强制对齐 32MB
	truncate -s 32M $@.nor
	# 物理导出
	cp $@.nor $@
endef

# --- 物理修正：生成 eMMC GPT 分区表 ---
define Build/mt798x-gpt-emmc-production
	cp $@ $@.tmp 2>/dev/null || true
	# 物理偏移对齐：1M=2048s。确保 production 分区在 64MB (131072s) 物理对齐点
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@5M \
		-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M
	cat $@.tmp >> $@
	rm $@.tmp
endef

define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-v2
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  DEVICE_PACKAGES := $(SL3000_PKGS)

  # 物理产出物定义：增加 .bin 后缀对齐常规编程器习惯
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  IMAGE_SIZE := 512M

  # 1. 编程器镜像
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle

  # 2. 系统升级镜像
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | append-kernel | pad-to 64M | \
                               append-rootfs | pad-to $(IMAGE_SIZE) | check-size | append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
