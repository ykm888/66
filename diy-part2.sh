#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理硬核对齐脚本 (暴力重建版)
# =========================================================

SRC_DIR="$(pwd)/888"
TARGET_DIR="$(pwd)/openwrt"

echo "--- [1/3] 物理覆盖 Makefile ---"
# 直接覆盖，确保系统只能读到我们的自定义版本
cp -f "$SRC_DIR/atf-Makefile" "$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek/Makefile"
cp -f "$SRC_DIR/uboot-Makefile" "$TARGET_DIR/package/boot/uboot-mediatek/Makefile"

# 注入 U-Boot 零件
mkdir -p "$TARGET_DIR/package/boot/uboot-mediatek/files"
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$TARGET_DIR/package/boot/uboot-mediatek/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$TARGET_DIR/package/boot/uboot-mediatek/files/"

echo "--- [2/3] 物理死锁架构：MediaTek MT7981 ---"
# 强行初始化最纯净的架构配置，杜绝 x86 干扰
printf "CONFIG_TARGET_mediatek=y\n" > "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y\n" >> "$TARGET_DIR/.config"

# 【核心改进】不使用变量名，直接使用包名全称，强迫系统选中
printf "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y\n" >> "$TARGET_DIR/.config"

echo "--- [3/3] 缓存爆破与强制扫描 ---"
rm -rf "$TARGET_DIR/tmp"
echo "✅ 物理地基已强行夯实"
