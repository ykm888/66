#!/bin/bash
# [2026-03-05] SL-3000 物理修复脚本
# 准则：禁用 EOF，严格执行内核优化与架构纠偏。

CONFIG_FILE=".config"

echo "⚙️ 1. 执行内核与驱动优化..."
# 启用硬件加速固件
sed -i 's/# CONFIG_PACKAGE_mt7981-wo-firmware is not set/CONFIG_PACKAGE_mt7981-wo-firmware=y/' $CONFIG_FILE
# 物理瘦身：关闭内核调试
sed -i 's/^CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/' $CONFIG_FILE
sed -i 's/^CONFIG_KERNEL_DEBUG_KERNEL=y/# CONFIG_KERNEL_DEBUG_KERNEL is not set/' $CONFIG_FILE
# 保持 Wi-Fi 驱动为模块
sed -i 's/^CONFIG_MTK_MT_WIFI=y/CONFIG_MTK_MT_WIFI=m/' $CONFIG_FILE

echo "🛡️ 2. 物理根除 Error 255 (剔除 x86 冗余驱动)..."
for pkg in kmod-e1000 kmod-e1000e kmod-i915 kmod-tg3 kmod-vmxnet3 kmod-bnx2 kmod-8139too kmod-forcedeth kmod-amazon-ena; do
    sed -i "/CONFIG_PACKAGE_$pkg=y/d" $CONFIG_FILE
done

# 确保 dnsmasq-full 唯一性 (解决依赖冲突)
sed -i 's/CONFIG_PACKAGE_dnsmasq=y/# CONFIG_PACKAGE_dnsmasq is not set/' $CONFIG_FILE

echo "🧠 3. 注入 SL-3000 1024M 物理定义..."
MAKEFILE="target/linux/mediatek/image/filogic.mk"
if ! grep -q "sl_3000-emmc" "$MAKEFILE"; then
cat << 'SL3000' >> "$MAKEFILE"

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC
  DEVICE_DTS := mt7981b-sl-3000-emmc
  DEVICE_DTS_DIR := $(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_DRAM_SIZE := 1024M
  DEVICE_PACKAGES := $(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS := kernel-bin | lzma | fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.bin factory.img.gz
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
  ARTIFACTS := emmc-gpt.bin emmc-preloader.bin emmc-bl31-uboot.fip
  ARTIFACT/emmc-gpt.bin := mt798x-gpt emmc
  ARTIFACT/emmc-preloader.bin := mt7981-bl2 emmc-ddr3
  ARTIFACT/emmc-bl31-uboot.fip := mt7981-bl31-uboot emmc-ddr3
  IMAGE/factory.img.gz := mt798x-gpt emmc |\
	pad-to 17k | mt7981-bl2 emmc-ddr3 |\
	pad-to 6656k | mt7981-bl31-uboot emmc-ddr3 |\
	pad-to 64M | append-image squashfs-sysupgrade.itb | gzip
endef
TARGET_DEVICES += sl_3000-emmc
SL3000
fi

echo "🚀 执行对齐命令 (defconfig)..."
make defconfig
