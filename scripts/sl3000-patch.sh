#!/bin/bash
# [2026-03-05] SL-3000 物理级终极清淤脚本 - 像素级对齐截图
# 准则：只修改错误，不画蛇添足，不偷工减料，生成禁用 EOF

PATCH_DIR="target/linux/mediatek/patches-6.6"

echo "🧹 正在根据截图内容执行【物理清淤】..."

# 1. 物理爆破：截图中“禁用 eMMC”和“旧架构”的毒瘤 (103-116 系列)
# 核心修复：114-dts-bpi64-disable-emmc.patch 必须死，否则找不到硬盘
rm -fv "$PATCH_DIR"/114-dts-bpi64-disable-emmc.patch
find "$PATCH_DIR" -type f \( -name "*mt7622*" -o -name "*mt7623*" -o -name "*bpi*" \) -delete

# 2. 物理爆破：截图中所有 NAND/SNAND 存储补丁 (330-344 系列)
# SL-3000 是 eMMC 版，这些补丁会干扰存储控制器
find "$PATCH_DIR" -type f \( -name "*snand*" -o -name "*spinand*" -o -name "*nand*" \) -delete

# 3. 物理爆破：截图中不相关的硬件与跨版本补丁 (244-250, 830, 860 系列)
# 核心修复：250(mt7988) 和 830(mt8192) 是导致编译报错的直接元凶
rm -fv "$PATCH_DIR"/*v6.7* "$PATCH_DIR"/*v6.8*
find "$PATCH_DIR" -type f \( -name "*mt7988*" -o -name "*mt81*" -o -name "*ASoC*" -o -name "*mt65xx*" \) -delete

# 4. 物理爆破：截图中不相关的网络与 PCIe 魔改 (601-710, 734-739 系列)
# 核心修复：PCIe 补丁会导致 Kernel Panic，Airoha 补丁导致网口不通
find "$PATCH_DIR" -type f \( -name "*PCI-mediatek*" -o -name "*pcie-mediatek*" -name "*Air*" \) -delete
rm -fv "$PATCH_DIR"/722-remove-300Hz-*.patch
rm -fv "$PATCH_DIR"/739-net-add-negotia*.patch
rm -fv "$PATCH_DIR"/960-asus-hack-*.patch

# 5. 物理爆破：所有 999 系列魔改 (保留 998 风扇)
find "$PATCH_DIR" -type f -name "999-*.patch" ! -name "998-pwm-fan-fix.patch" -delete
rm -fv "$PATCH_DIR"/999[7-9]-*.patch

# 6. API 物理对齐：锁定 ethtool_keee (防止网络驱动报错)
find "$PATCH_DIR" -type f -name "*.patch" -exec sed -i 's/struct ethtool_eee/struct ethtool_keee/g' {} +

echo "🧠 正在注入 SL-3000 1024M 核心定义到 filogic.mk..."
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

echo "📦 锁定 U-Boot 1024M 物理源码..."
sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" package/boot/uboot-mediatek/Makefile
sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" package/boot/uboot-mediatek/Makefile
