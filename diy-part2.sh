#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理对齐脚本 (全链路加固版)
# =========================================================

# 1. 路径自动识别
SRC_DIR="$(pwd)/888"
TARGET_DIR="$(pwd)/openwrt"

echo "--- [1/4] 物理强灌：覆盖 Makefile 与注入零件 ---"
# 覆盖核心 Makefile
cp -f "$SRC_DIR/atf-Makefile" "$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek/Makefile"
cp -f "$SRC_DIR/uboot-Makefile" "$TARGET_DIR/package/boot/uboot-mediatek/Makefile"

# 注入 U-Boot 零件 (DTS 和 Defconfig)
mkdir -p "$TARGET_DIR/package/boot/uboot-mediatek/files"
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$TARGET_DIR/package/boot/uboot-mediatek/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$TARGET_DIR/package/boot/uboot-mediatek/files/"

echo "--- [2/4] 物理对齐：强制配置 .config 变量 ---"
# 【关键修复】如果 .config 不存在则创建，防止 sed 报错
[ ! -f "$TARGET_DIR/.config" ] && touch "$TARGET_DIR/.config"

# 定义变体名 (必须与 Makefile 内部对齐)
ATF_VARIANT="mt7981-nor-ddr4"
UBOOT_VARIANT="mt7981_sl3000"

# 物理死锁：先删除可能存在的旧条目，确保唯一性
sed -i "/CONFIG_PACKAGE_arm-trusted-firmware-mediatek/d" "$TARGET_DIR/.config"
sed -i "/CONFIG_PACKAGE_uboot-mediatek/d" "$TARGET_DIR/.config"

# 注入新变体选中状态
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-${ATF_VARIANT}=y" >> "$TARGET_DIR/.config"
echo "CONFIG_PACKAGE_uboot-mediatek-${UBOOT_VARIANT}=y" >> "$TARGET_DIR/.config"

echo "--- [3/4] 物理爆破：清除 OpenWrt 索引缓存 ---"
# 彻底删除 tmp 目录，解决 No rule to make target 错误
rm -rf "$TARGET_DIR/tmp"

echo "--- [4/4] 终端校验：检查物理对齐状态 ---"
if grep -q "${ATF_VARIANT}" "$TARGET_DIR/.config"; then
    echo "✅ [SUCCESS] ATF 变体 ${ATF_VARIANT} 已成功物理锁定！"
else
    echo "❌ [ERROR] 物理对齐失败，请检查脚本执行环境！"
    exit 1
fi
