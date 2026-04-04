define Device/mt7981_sl3000_emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := SL3000
  DEVICE_VARIANT := NOR-32MB
  DEVICE_DTS := mt7981b-sl3000-emmc
  SUPPORTED_DEVICES := sl,sl3000

  # ==============================
  # 32MB SPI NOR (BY25Q256FS) 标准分区
  # ==============================
  KERNEL_SIZE := 4096k
  ROOTFS_SIZE := 26624k
  IMAGE_SIZE := 30720k
  BLOCKSIZE := 64k
  KERNEL_LOADADDR := 0x48000000

  # 救砖全家桶（精简不超容）
  DEVICE_PACKAGES := \
	luci luci-base luci-mod-system luci-theme-bootstrap \
	block-mount e2fsprogs f2fs-tools \
	kmod-fs-ext4 kmod-fs-f2fs \
	kmod-mtd kmod-mtd-rw \
	kmod-spi-nor kmod-sdhci-mtk \
	dropbear \
	lsblk blkid mount-utils \
	mtd-utils uboot-envtools

  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += mt7981_sl3000_emmc
