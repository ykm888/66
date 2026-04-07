# 像素级全链路修复版 - 适配 SL3000 32MB SPI-NOR
define Device/sl_3000-spi-nor
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000
  DEVICE_VARIANT := 1GB-RAM-Rescue-Ready
  # 修正 1：物理溯源 - 必须使用 spi-nor 专用的 DTS
  DEVICE_DTS := mt7981b-sl-3000-spi-nor
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-spi-nor
  # 修正 2：内存对齐 - 确保 BL2 训练 1024M
  DEVICE_DRAM_SIZE := 1024M
  KERNEL_LOADADDR := 0x44000000
  # 修正 3：分区定义 - 预留 4MB 给 Bootloader，剩余 28MB 给系统
  IMAGE_SIZE := 28672k
  
  DEVICE_PACKAGES := \
    kmod-mt7981-firmware kmod-mt798x-phy-mt7976 kmod-mt7915e \
    kmod-fs-f2fs f2fs-tools \
    block-mount mtd-utils uboot-envtools fdisk lsblk blkid \
    luci-app-ttyd luci-i18n-ttyd-zh-cn
    
  # 修正 4：构建全家桶所需的镜像逻辑
  IMAGES := sysupgrade.itb factory.bin
  # 生成用于网页升级的 ITB
  IMAGE/sysupgrade.itb := append-kernel | pad-to 64k | append-rootfs | pad-to 64k | append-metadata
  # 生成用于编程器直刷的 Factory (含补位逻辑)
  IMAGE/factory.bin := append-kernel | pad-to 28672k
endef

TARGET_DEVICES += sl_3000-spi-nor
