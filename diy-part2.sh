#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理自动对齐脚本 (2026 最终修复版)
# =========================================================

# 1. 自动定位路径 (兼容本地测试与 GitHub Actions)
SRC_DIR="$(pwd)/888"
TARGET_DIR="$(pwd)/openwrt"

echo "--- [1/4] 开始物理强灌零件 ---"
# 物理覆盖 Makefile：确保 OpenWrt 认领我们的救砖分支
cp -f "$SRC_DIR/atf-Makefile" "$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek/Makefile"
cp -f "$SRC_DIR/uboot-Makefile" "$TARGET_DIR/package/boot/uboot-mediatek/Makefile"

# 注入 U-Boot 必要零件 (设备树与配置)
mkdir -p "$TARGET_DIR/package/boot/uboot-mediatek/files"
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$TARGET_DIR/package/boot/uboot-mediatek/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$TARGET_DIR/package/boot/uboot-mediatek/files/"

echo "--- [2/4] 执行变量自动对齐检查 ---"
# 定义我们想要的黄金变体名 (必须与 Makefile 内部对齐)
ATF_VARIANT="mt7981-nor-ddr4"
UBOOT_VARIANT="mt7981_sl3000"

# 2. 物理死锁变量：在 .config 中暴力同步
# 逻辑：删除所有旧的 arm-trusted-firmware 和 uboot 选中行，确保干净
sed -i "/CONFIG_PACKAGE_arm-trusted-firmware-mediatek/d" "$TARGET_DIR/.config"
sed -i "/CONFIG_PACKAGE_uboot-mediatek/d" "$TARGET_DIR/.config"

# 重新注入：强制选中我们修复后的变体
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-${ATF_VARIANT}=y" >> "$TARGET_DIR/.config"
echo "CONFIG_PACKAGE_uboot-mediatek-${UBOOT_VARIANT}=y" >> "$TARGET_DIR/.config"

echo "--- [3/4] 物理缓存爆破 (解决 No rule 错误的关键) ---"
# 【核心步骤】删除 tmp 目录。不删这个，OpenWrt 就不会重新扫描 Makefile
rm -rf "$TARGET_DIR/tmp"

echo "--- [4/4] 终端对齐验证 ---"
# 简单验证注入是否成功
if grep -q "${ATF_VARIANT}" "$TARGET_DIR/.config"; then
    echo "✅ [SUCCESS] ATF 变体 ${ATF_VARIANT} 已锁定！"
else
    echo "❌ [ERROR] ATF 变体注入失败，请检查脚本权限！"
    exit 1
fi

echo "--- 物理溯源全链路对齐完成 ---"
