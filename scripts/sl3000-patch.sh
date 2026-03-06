#!/bin/bash
# [2026-03-05] SL-3000 物理修复与内核优化脚本
# 准则：禁用 EOF，仅保留核心配置修改，原文照抄已修复逻辑。

CONFIG_FILE=".config"

echo "⚙️ 步骤 1: 执行内核与驱动优化 (用户指令对齐)..."

# 1. 启用 mt7981-wo-firmware (硬件卸载固件)
sed -i 's/# CONFIG_PACKAGE_mt7981-wo-firmware is not set/CONFIG_PACKAGE_mt7981-wo-firmware=y/' $CONFIG_FILE

# 2. 关闭内核调试选项 (物理瘦身，防止编译溢出)
sed -i 's/^CONFIG_KERNEL_DEBUG_INFO=y/# CONFIG_KERNEL_DEBUG_INFO is not set/' $CONFIG_FILE
sed -i 's/^CONFIG_KERNEL_DEBUG_KERNEL=y/# CONFIG_KERNEL_DEBUG_KERNEL is not set/' $CONFIG_FILE
sed -i 's/^CONFIG_KERNEL_DEBUG_INFO_REDUCED=y/# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set/' $CONFIG_FILE
sed -i 's/^CONFIG_KERNEL_GDB_SCRIPTS=y/# CONFIG_KERNEL_GDB_SCRIPTS is not set/' $CONFIG_FILE

# 3. 修正 Wi-Fi 驱动加载方式 (保持为模块 m 以确保挂载顺序稳定)
sed -i 's/^CONFIG_MTK_MT_WIFI=y/CONFIG_MTK_MT_WIFI=m/' $CONFIG_FILE

echo "🛡️ 步骤 2: 彻底根除 Error 255 (物理剔除 x86 冗余驱动)..."
# 强制删除导致 package/install 崩溃的非 ARM 驱动定义
for pkg in kmod-e1000 kmod-e1000e kmod-i915 kmod-tg3 kmod-vmxnet3 kmod-bnx2 kmod-8139too kmod-forcedeth kmod-amazon-ena; do
    sed -i "/CONFIG_PACKAGE_$pkg=y/d" $CONFIG_FILE
done

# 修正 dnsmasq 冲突 (确保只启用 full 版)
sed -i 's/CONFIG_PACKAGE_dnsmasq=y/# CONFIG_PACKAGE_dnsmasq is not set/' $CONFIG_FILE
if ! grep -q "CONFIG_PACKAGE_dnsmasq-full=y" $CONFIG_FILE; then
    echo "CONFIG_PACKAGE_dnsmasq-full=y" >> $CONFIG_FILE
fi

echo "🧠 步骤 3: 注入 SL-3000 1024M 物理设备定义..."
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

echo "🚀 执行配置对齐 (make defconfig)..."
make defconfig
