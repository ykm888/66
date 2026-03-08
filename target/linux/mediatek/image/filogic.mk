#
# Copyright (C) 2021 MediaTek Inc.
# 物理修正版：针对 NOR引导 + eMMC存储 + 1024M内存 架构
#

KERNEL_LOADADDR := 0x48080000

# 物理组件包：包含 WiFi 驱动依赖和 1024M 内存必要工具
MT7981_USB_PKGS := automount blkid blockdev fdisk kmod-nls-cp437 kmod-nls-iso8859-1 \
                   kmod-usb2 kmod-usb3 kmod-usb-storage-uas usbutils \
                   kmod-usb-net-rndis kmod-usb-net-qmi-wwan

define Image/Prepare
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

# --- 物理修正 A：NOR Flash 专用封包逻辑 ---
define Build/sl3000-nor-bundle
	# 物理合成：BL2 (0x0) + FIP (0x100000/1MB 偏移)
	# 适用于用编程器直接烧录 32MB NOR Flash
	rm -f $@.nor
	dd if=$(STAGING_DIR_IMAGE)/mt7981-nor-ddr4-bl2.img of=$@.nor bs=1k conv=notrunc
	dd if=$(STAGING_DIR_IMAGE)/mt7981_sl_3000-nor-u-boot.fip of=$@.nor bs=1k seek=1024 conv=notrunc
	# 填充至 32MB 确保物理镜像完整
	truncate -s 32M $@.nor
endef

# --- 物理修正 B：eMMC 专用 GPT 分区表 (剔除引导区) ---
define Build/mt798x-gpt-emmc-only
	cp $@ $@.tmp 2>/dev/null || true
	# 仅在 eMMC 上创建数据分区，因为引导已经在 NOR 里了
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
  DEVICE_VARIANT := NOR-Boot-1024M
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) kmod-mmc-mtk kmod-mt7531 mkf2fs \
                     e2fsprogs kmod-fs-f2fs kmod-fs-ext4 parted resize2fs \
                     kmod-mt7981-firmware mt7981-wo-firmware datconf-lua

  # 物理生成两个文件：一个给编程器(NOR)，一个给系统(eMMC)
  IMAGES := nor-flash-dump.bin emmc-sysupgrade.bin
  IMAGE_SIZE := 512M

  # 1. 生成 32MB NOR 物理全镜像 (用于编程器救砖)
  IMAGE/nor-flash-dump.bin := sl3000-nor-bundle

  # 2. 生成 eMMC 系统固件 (引导后由 U-Boot 读取)
  IMAGE/emmc-sysupgrade.bin := mt798x-gpt-emmc-only | append-kernel | pad-to 64M | \
                               append-rootfs | pad-to $(IMAGE_SIZE) | check-size | append-metadata

endef
TARGET_DEVICES += sl_3000-nor-emmc
