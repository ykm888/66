#
# Copyright (C) 2021 MediaTek Inc.
#

KERNEL_LOADADDR := 0x48080000
# 物理组件包：针对 SL-3000 的 128G eMMC 和交换机进行优化
MT7981_USB_PKGS := automount blkid blockdev fdisk kmod-nls-cp437 kmod-nls-iso8859-1 \
                   kmod-usb2 kmod-usb3 kmod-usb-storage-uas usbutils \
                   kmod-usb-net-rndis kmod-usb-net-qmi-wwan

define Image/Prepare
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

define Build/mt7981-bl2
	cat $(STAGING_DIR_IMAGE)/mt7981-$1-bl2.img >> $@
endef

define Build/mt7981-bl31-uboot
	cat $(STAGING_DIR_IMAGE)/mt7981_$1-u-boot.fip >> $@
endef

define Build/mt798x-gpt
	cp $@ $@.tmp 2>/dev/null || true
	ptgen -g -o $@.tmp -a 1 -l 1024 \
		$(if $(findstring emmc,$1), \
			-t 0x83	-N ubootenv	-r	-p 512k@4M \
			-t 0x83	-N factory	-r	-p 2M@4608k \
			-t 0xef	-N fip		-r	-p 4M@6656k \
				-N recovery	-r	-p 32M@12M \
			-t 0x2e -N production		-p $(CONFIG_TARGET_ROOTFS_PARTSIZE)M@64M \
		)
	cat $@.tmp >> $@
	rm $@.tmp
endef

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC-DDR4-1024M
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  # 物理注入：必须包含 kmod-mt7531 否则网口不通
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) kmod-mmc-mtk kmod-mt7531 mkf2fs \
                     e2fsprogs kmod-fs-f2fs kmod-fs-ext4 parted resize2fs \
                     kmod-mt7981-firmware mt7981-wo-firmware

  IMAGES := factory.bin sysupgrade.bin
  IMAGE_SIZE := 512M

  # 物理封包逻辑
  IMAGE/factory.bin := mt798x-gpt emmc | pad-to 17k | \
                       mt7981-bl2 emmc-ddr4 | pad-to 6656k | \
                       mt7981-bl31-uboot sl_3000-emmc | \
                       pad-to 12M | append-kernel | pad-to 64M | \
                       append-rootfs | pad-to $(IMAGE_SIZE) | check-size

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000-emmc
