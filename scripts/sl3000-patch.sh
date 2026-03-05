#!/bin/bash
# [2026-03-05] SL-3000 物理级修复脚本
# 规则：原文照抄、物理修复、不画蛇添足、静默审计

PATCH_DIR="target/linux/mediatek/patches-6.6"

echo "🧹 1. 物理清淤：从源头彻底切除不相关补丁..."
# 1.1 彻底切除 17xx 系列 (导致 1708 报错的元凶)
rm -fv "$PATCH_DIR"/999-17*.patch || true

# 1.2 彻底切除 27xx 系列 (导致 2714 报错及其他 EEE 冲突)
# 这里执行连坐法，确保相关损坏补丁全部消失
rm -fv "$PATCH_DIR"/999-2713-*.patch || true
rm -fv "$PATCH_DIR"/999-2714-*.patch || true
rm -fv "$PATCH_DIR"/999-2755-*.patch || true

# 1.3 切除不相关的 15xx 系列
rm -fv "$PATCH_DIR"/999-15*.patch || true

echo "🛠️ 2. API 物理对齐：强制锁定 ethtool_keee..."
# 对剩余的 MTK 核心驱动进行原子级结构体替换，适配 Linux 6.6
find "$PATCH_DIR" -type f -exec sed -i 's/struct ethtool_eee/struct ethtool_keee/g' {} +
find "$PATCH_DIR" -type f -exec sed -i 's/\.supported/\.supported_u32/g' {} +

echo "🧠 3. 物理锁定 1024M 内存与设备定义..."
# 注入 Device 定义（基于您的记忆，确保救砖全家桶生成逻辑）
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

echo "📦 4. U-Boot 1024M 物理源码重定向..."
sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" package/boot/uboot-mediatek/Makefile
sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" package/boot/uboot-mediatek/Makefile
