#
# Copyright (C) 2021 MediaTek Inc.
#

KERNEL_LOADADDR := 0x48080000

# 物理定义：SL-3000 及 MT7981 通用 USB 扩展包
MT7981_USB_PKGS := automount blkid blockdev fdisk \
    kmod-nls-cp437 kmod-nls-iso8859-1 kmod-usb2 kmod-usb3 \
    luci-app-usb-printer luci-i18n-usb-printer-zh-cn \
    kmod-usb-net-rndis usbutils \
    kmod-usb-net-qmi-wwan autoksmbd

# --- 专属魔改设备：SL-3000 eMMC (1024M 内存/救砖版) ---
define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := eMMC-1024M-Recovery
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  
  # 物理定义编译产物：包含救砖镜像(factory)和升级包(sysupgrade)
  IMAGES := factory.bin sysupgrade.bin
  
  # 救砖包物理合并逻辑 (Factory Image)
  # 物理对齐：拼接内核与根文件系统，强制填充至 128MB 以对齐 EMMC 分区表
  IMAGE/factory.bin := append-kernel | append-rootfs | pad-to 128M | check-size
  
  # 升级包物理打包逻辑 (Sysupgrade)
  # 物理兼容：采用 tar 容器封装，物理适配 eMMC 的分区挂载机制
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  
  # 物理驱动包：锁定 eMMC 控制器驱动及 F2FS/EXT4 文件系统工具
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) kmod-mmc-mtk mkf2fs e2fsprogs \
		     kmod-fs-f2fs kmod-fs-ext4 kmod-fs-vfat
endef
TARGET_DEVICES += sl_3000-emmc

# --- 标准参考设备：MT7981 eMMC RFB ---
define Device/mt7981-emmc-rfb
  DEVICE_VENDOR := MediaTek
  DEVICE_MODEL := mt7981-emmc-rfb
  DEVICE_DTS := mt7981-emmc-rfb
  SUPPORTED_DEVICES := mediatek,mt7981-emmc-rfb
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  DEVICE_PACKAGES := mkf2fs e2fsprogs blkid blockdev losetup kmod-fs-ext4 \
		     kmod-mmc kmod-fs-f2fs kmod-fs-vfat kmod-nls-cp437 \
		     kmod-nls-iso8859-1
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981-emmc-rfb

# --- 标准参考设备：MT7981 SD RFB ---
define Device/mt7981-sd-rfb
  DEVICE_VENDOR := MediaTek
  DEVICE_MODEL := mt7981-sd-rfb
  DEVICE_DTS := mt7981-sd-rfb
  SUPPORTED_DEVICES := mediatek,mt7981-sd-rfb
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  DEVICE_PACKAGES := mkf2fs e2fsprogs blkid blockdev losetup kmod-fs-ext4 \
		     kmod-mmc kmod-fs-f2fs kmod-fs-vfat kmod-nls-cp437 \
		     kmod-nls-iso8859-1
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981-sd-rfb

# --- 典型 NAND 设备：360 T7 ---
define Device/mt7981-360-t7
  DEVICE_VENDOR := MediaTek
  DEVICE_MODEL := 360 T7
  DEVICE_DTS := mt7981-360-t7
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := 360,t7
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 36864k
  KERNEL_IN_UBI := 1
  IMAGES += factory.bin
  IMAGE/factory.bin := append-ubi | check-size $$$$(IMAGE_SIZE)
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981-360-t7
