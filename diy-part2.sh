#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理死锁投递脚本 (Final Hardened Version)
# =========================================================

WORK_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
SRC_DIR="$WORK_DIR/888"
TARGET_DIR="$WORK_DIR/openwrt"

echo "--- [物理溯源]：锁定构建根目录 $WORK_DIR ---"

# 定义零件路径
ATF_PATH="$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek"
UBOOT_PATH="$TARGET_DIR/package/boot/uboot-mediatek"

# 创建零件收纳盒
mkdir -p "$ATF_PATH/files"
mkdir -p "$UBOOT_PATH/files"

# 1. 物理强灌：Makefile 覆盖 (确保使用的是我们修复的完整版)
cp -f "$SRC_DIR/atf-Makefile" "$ATF_PATH/Makefile"
cp -f "$SRC_DIR/uboot-Makefile" "$UBOOT_PATH/Makefile"

# 2. 物理强灌：ATF 1MB 偏移核心补丁
cp -f "$SRC_DIR/bl2_dev_spi_nor.c" "$ATF_PATH/files/"
cp -f "$SRC_DIR/platform_def.h"    "$ATF_PATH/files/"
cp -f "$SRC_DIR/platform.mk"      "$ATF_PATH/files/"
cp -f "$SRC_DIR/bl2.mk"           "$ATF_PATH/files/"
cp -f "$SRC_DIR/mt7981-spi2.dts"  "$ATF_PATH/files/"

# 3. 物理强灌：U-Boot 零件与设备树
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$UBOOT_PATH/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$UBOOT_PATH/files/"

# 4. 配置物理死锁：清除旧配置，强制选中新变体
sed -i '/CONFIG_PACKAGE_arm-trusted-firmware-mediatek/d' "$TARGET_DIR/.config"
sed -i '/CONFIG_PACKAGE_uboot-mediatek/d' "$TARGET_DIR/.config"
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y" >> "$TARGET_DIR/.config"
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y" >> "$TARGET_DIR/.config"

# 5. 【核心修复】暴力切断旧索引缓存，强制系统重新扫描 Makefile
rm -rf "$TARGET_DIR/tmp"

echo "--- [物理溯源]：变体 mt7981-nor-ddr4 与 mt7981_sl3000 已完成对齐注入 ---"
