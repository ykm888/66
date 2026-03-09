#
# SL-3000 物理定制版：针对 NOR-BOOT + eMMC-STORAGE + 1024M-RAM
# 修复重点：文件名强制对齐、强制文件检查、分区名统一
#

SL3000_PKGS := kmod-mmc-mtk kmod-mtk-sd kmod-mt7531 f2fs-tools e2fsprogs kmod-fs-f2fs \
               kmod-fs-ext4 parted resize2fs datconf-lua

# --- 1. 合成 32MB NOR 救砖包 ---
define Build/sl3000-nor-bundle
	rm -f $@.nor
	truncate -s 32M $@.nor
	# BL2 检查与写入
	test -f $(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img || { echo "BL2 missing"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	# FIP 检查与写入（文件名与 U-Boot 输出一致）
	test -f $(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin || { echo "FIP missing"; exit 1; }
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-fip.bin of=$@.nor bs=1k seek=1024 conv=notrunc
	cp $@.nor $@
endef

# --- 2. 生成 eMMC GPT 分区表（包含独立 kernel 和 rootfs 分区）---
define Build/mt798x-gpt-emmc-production
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@5M \
		-t 0x83	-N kernel	-r	-p 64M@64M \
		-t 0x83	-N rootfs			-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@128M
	cat $@.tmp >> $@
	rm $@.tmp
endef

# --- 3. 设备定义 ---
define Device/sl_3000-nor-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := NOR-Boot-1024M-Final
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := $(SL3000_PKGS)

  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  IMAGE_SIZE := 1024M

  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | \
                               pad-to 64M | append-kernel | \
                               pad-to 128M | append-rootfs | \
                               check-size | append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
