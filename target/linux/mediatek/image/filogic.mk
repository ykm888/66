# Copyright (C) 2021 MediaTek Inc.
KERNEL_LOADADDR := 0x48080000
MT7981_USB_PKGS := automount blkid blockdev fdisk kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 luci-app-usb-printer luci-i18n-usb-printer-zh-cn kmod-usb-net-rndis usbutils kmod-usb-net-qmi-wwan
define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC-1024M-Recovery
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  IMAGES := factory.bin sysupgrade.bin
  IMAGE_SIZE := 120M
  IMAGE/factory.bin := append-kernel | append-rootfs | pad-to $(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) kmod-mmc-mtk mkf2fs e2fsprogs kmod-fs-f2fs kmod-fs-ext4 kmod-fs-vfat
endef
TARGET_DEVICES += sl_3000-emmc
