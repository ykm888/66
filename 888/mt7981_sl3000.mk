# Device Definition for SL3000 (1GB RAM / 32MB SPI-NOR)
define Device/sl_3000-spi-nor
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := 1GB-RAM-Recovery
  DEVICE_DTS := mt7981b-sl3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-spi-nor
  DEVICE_DRAM_SIZE := 1024M
  KERNEL_LOADADDR := 0x44000000
  IMAGE_SIZE := 28672k
  DEVICE_PACKAGES := \
    kmod-mt7981-firmware kmod-mt798x-phy-mt7976 kmod-mt7915e \
    kmod-mmc kmod-sdhci-mtk \
    kmod-fs-ext4 kmod-fs-f2fs f2fs-tools \
    block-mount mtd-utils uboot-envtools fdisk lsblk blkid \
    luci-app-ttyd
  IMAGES := sysupgrade.itb
  IMAGE/sysupgrade.itb := append-kernel | pad-to 64k | append-rootfs | pad-to 64k | append-metadata
endef

TARGET_DEVICES += sl_3000-spi-nor
