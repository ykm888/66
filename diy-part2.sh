#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理死锁投递脚本 (Final Hardened Version)
# =========================================================

WORK_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
SRC_DIR="$WORK_DIR/888"
TARGET_DIR="$WORK_DIR/openwrt"

echo "--- [物理溯源]：锁定构建根目录 $WORK_DIR ---"

ATF_PATH="$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek"
UBOOT_PATH="$TARGET_DIR/package/boot/uboot-mediatek"

mkdir -p "$ATF_PATH/files"
mkdir -p "$UBOOT_PATH/files"

# 1. 物理强灌：Makefile 替换
cp -f "$SRC_DIR/atf-Makefile" "$ATF_PATH/Makefile"
cp -f "$SRC_DIR/uboot-Makefile" "$UBOOT_PATH/Makefile"

# 2. 物理强灌：零件补丁
cp -f "$SRC_DIR/bl2_dev_spi_nor.c" "$ATF_PATH/files/"
cp -f "$SRC_DIR/platform_def.h"    "$ATF_PATH/files/"
cp -f "$SRC_DIR/platform.mk"      "$ATF_PATH/files/"
cp -f "$SRC_DIR/bl2.mk"           "$ATF_PATH/files/"
cp -f "$SRC_DIR/mt7981-spi2.dts"  "$ATF_PATH/files/"

# 3. 物理强灌：U-Boot 零件
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$UBOOT_PATH/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$UBOOT_PATH/files/"

# 4. 配置物理死锁：强制选中新变体名
echo "--- [物理溯源]：执行配置物理注入 ---"
sed -i 's/CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-sl3000-nor=y//g' "$TARGET_DIR/.config" 2>/dev/null
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y" >> "$TARGET_DIR/.config"
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y" >> "$TARGET_DIR/.config"

# 5. 权限硬化
chmod -R 755 "$ATF_PATH"
chmod -R 755 "$UBOOT_PATH"
rm -rf "$TARGET_DIR/tmp"

echo "--- [物理溯源]：变体 mt7981-nor-ddr4 已完成对齐注入 ---"
