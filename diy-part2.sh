#!/bin/bash
# =========================================================
# SL-3000 终极救砖零件物理死锁脚本 (物理全对齐版)
# =========================================================

SRC_DIR="$(pwd)/888"
TARGET_DIR="$(pwd)/openwrt"

echo "--- [1/4] 物理强灌：Makefile 覆盖与源码平铺预处理 ---"
# 物理覆盖核心编译描述文件
cp -f "$SRC_DIR/atf-Makefile" "$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek/Makefile"
cp -f "$SRC_DIR/uboot-Makefile" "$TARGET_DIR/package/boot/uboot-mediatek/Makefile"

# 注入 U-Boot 零件
mkdir -p "$TARGET_DIR/package/boot/uboot-mediatek/files"
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$TARGET_DIR/package/boot/uboot-mediatek/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$TARGET_DIR/package/boot/uboot-mediatek/files/"

echo "--- [2/4] 架构死锁：物理抹除 x86 并锁定 MT7981 ---"
# 强制初始化配置，彻底切断 x86 路径
printf "CONFIG_TARGET_mediatek=y\n" > "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y\n" >> "$TARGET_DIR/.config"

echo "--- [3/4] 索引重置：解决 No rule to make target ---"
rm -rf "$TARGET_DIR/tmp"

echo "--- [4/4] 物理校验 ---"
grep "CONFIG_TARGET_mediatek=y" "$TARGET_DIR/.config" && echo "✅ MT7981 架构已锁定"
