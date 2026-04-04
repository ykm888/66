define Device/mt7981_sl3000_emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := eMMC (1GB-RAM)
  DEVICE_DTS := mt7981b-sl3000-emmc
  SUPPORTED_DEVICES := sl,sl3000
  # 🔴 关键：明确 1024M 内存支持
  DEVICE_DRAM_SIZE := 1024M
  # 🔴 关键：对齐底层 U-Boot 加载地址
  KERNEL_LOADADDR := 0x44000000
  DEVICE_PACKAGES := \
    luci luci-base luci-mod-system luci-theme-bootstrap \
    block-mount e2fsprogs f2fs-tools \
    kmod-fs-ext4 kmod-fs-f2fs \
    kmod-mtd kmod-mtd-rw \
    kmod-mmc kmod-sdhci-mtk \
    dropbear \
    lsblk blkid mount-utils fdisk \
    mtd-utils uboot-envtools
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

TARGET_DEVICES += mt7981_sl3000_emmc
