#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理对齐脚本 (Final Hardened Version)
# =========================================================

SRC_DIR="$(pwd)/888"
TARGET_DIR="$(pwd)/openwrt"

echo "--- [1/4] 物理强灌：覆盖 Makefile 与注入零件 ---"
# 物理覆盖
cp -f "$SRC_DIR/atf-Makefile" "$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek/Makefile"
cp -f "$SRC_DIR/uboot-Makefile" "$TARGET_DIR/package/boot/uboot-mediatek/Makefile"

# 注入 U-Boot 零件
mkdir -p "$TARGET_DIR/package/boot/uboot-mediatek/files"
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$TARGET_DIR/package/boot/uboot-mediatek/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$TARGET_DIR/package/boot/uboot-mediatek/files/"

echo "--- [2/4] 物理对齐：强制配置 .config 变量 ---"
# 【修复点】确保文件存在，防止 sed 报错
[ ! -f "$TARGET_DIR/.config" ] && touch "$TARGET_DIR/.config"

# 物理死锁变体名
sed -i "/CONFIG_PACKAGE_arm-trusted-firmware-mediatek/d" "$TARGET_DIR/.config"
sed -i "/CONFIG_PACKAGE_uboot-mediatek/d" "$TARGET_DIR/.config"
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y" >> "$TARGET_DIR/.config"
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y" >> "$TARGET_DIR/.config"

echo "--- [3/4] 物理爆破：清除索引缓存 ---"
# 这是解决 No rule to make target 的唯一物理手段
rm -rf "$TARGET_DIR/tmp"

echo "--- [4/4] 验证对齐状态 ---"
grep "mt7981" "$TARGET_DIR/.config" && echo "✅ 物理变量对齐成功"
