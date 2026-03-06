#!/bin/bash
# [2026-03-05] SL-3000 物理级修复脚本 - 准则：原文照抄、静默审计

PATCH_DIR="target/linux/mediatek/patches-6.6"

echo "🧹 1. 物理清淤：通过关键词二次确认环境纯净..."
# 再次确保没有任何 MT7988 相关的补丁进入编译环境
find "$PATCH_DIR" -type f -name "*mt7988*" -delete
find "$PATCH_DIR" -type f -name "*mt753x*" -delete
find "$PATCH_DIR" -type f -name "999-*.patch" ! -name "998-pwm-fan-fix.patch" -delete

echo "🛠️ 2. API 强制对齐..."
find "$PATCH_DIR" -type f -name "*.patch" -exec sed -i 's/struct ethtool_eee/struct ethtool_keee/g' {} +

echo "🧠 3. 物理注入 SL-3000 1024M 核心定义..."
# 延续您记忆中保存的 DTS 配置
MAKEFILE="target/linux/mediatek/image/filogic.mk"
if ! grep -q "sl_3000-emmc" "$MAKEFILE"; then
cat << 'EOF' >> "$MAKEFILE"

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
EOF
fi

echo "📦 4. U-Boot 1024M 物理源码锁定..."
sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" package/boot/uboot-mediatek/Makefile
sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" package/boot/uboot-mediatek/Makefile
