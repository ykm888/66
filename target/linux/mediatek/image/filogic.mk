#
# SL-3000 物理定制版：针对 NOR-BOOT + eMMC-STORAGE + 1024M-RAM
#

# 物理组件包：确保 1024M 环境下的存储与网络性能
SL3000_PKGS := kmod-mmc-mtk kmod-mt7531 mkf2fs e2fsprogs kmod-fs-f2fs \
               kmod-fs-ext4 parted resize2fs datconf-lua luci-app-mtk

# --- 物理修正：生成 32MB NOR 编程器固件 (用于救砖) ---
define Build/sl3000-nor-bundle
	# 物理合成：BL2 在 0 偏移，FIP 在 1MB 偏移 (1024KB)
	rm -f $@.nor
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-u-boot.fip of=$@.nor bs=1k seek=1024 conv=notrunc
	# 物理填充至 32MB，匹配 SPI NOR 芯片物理容量
	truncate -s 32M $@.nor
endef

# --- 物理修正：生成 eMMC 系统分区表 (不含引导区，节省空间) ---
define Build/mt798x-gpt-emmc-production
	cp $@ $@.tmp 2>/dev/null || true
	# 物理分区定义：ubootenv(512k), factory(2M), production(剩余全部空间)
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		-t 0x83	-N ubootenv	-r	-p 512k@4M \
		-t 0x83	-N factory	-r	-p 2M@4608k \
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

  # 物理产出物定义
  IMAGES := nor-programmer-dump.bin emmc-sysupgrade.bin
  IMAGE_SIZE := 512M

  # 1. 编程器镜像：直接物理烧录 32MB NOR Flash
  IMAGE/nor-programmer-dump.bin := sl3000-nor-bundle

  # 2. 系统升级镜像：引导后通过 Web 救砖页面或命令行物理写入 eMMC
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-production | append-kernel | pad-to 64M | \
                               append-rootfs | pad-to $(IMAGE_SIZE) | check-size | append-metadata
endef
TARGET_DEVICES += sl_3000-nor-emmc
