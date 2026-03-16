#!/bin/bash
# =========================================================
# SL-3000 救砖全链路物理修复脚本 (自愈版)
# =========================================================

# 1. 物理创建零件工厂路径
mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

# 2. 物理平铺：使用绝对路径确保搬运成功
# 溯源诊断：GitHub Actions 默认 WORKSPACE 路径对齐
GITHUB_WORKSPACE="/home/runner/work/66/66"
REPO_PATH="${GITHUB_WORKSPACE}/sl3000-repo"

if [ -d "$REPO_PATH/atf" ]; then
    cp -rf "$REPO_PATH/atf"/* package/boot/arm-trusted-firmware-mediatek/
    echo "✅ ATF 源码已平铺到标准路径"
else
    echo "❌ 物理错误：找不到 ATF 源码路径 $REPO_PATH/atf"
    exit 1
fi

if [ -d "$REPO_PATH/u-boot" ]; then
    cp -rf "$REPO_PATH/u-boot"/* package/boot/uboot-mediatek/
    echo "✅ U-Boot 源码已平铺到标准路径"
else
    echo "❌ 物理错误：找不到 U-Boot 源码路径 $REPO_PATH/u-boot"
    exit 1
fi

# 3. 物理修正 U-Boot 1MB 偏移与 31.1 救砖 IP
UBOOT_DEF="package/boot/uboot-mediatek/configs/mt7981_nor_emmc_rfb_defconfig"
if [ -f "$UBOOT_DEF" ]; then
    sed -i 's/CONFIG_IPADDR=.*/CONFIG_IPADDR="192.168.31.1"/' "$UBOOT_DEF"
    sed -i 's/CONFIG_MTDPARTS_DEFAULT=.*/CONFIG_MTDPARTS_DEFAULT="nor0:1024k(bl2),2048k(fip),-(storage)"/' "$UBOOT_DEF"
    grep -q "CONFIG_SYS_UBOOT_BASE" "$UBOOT_DEF" || echo "CONFIG_SYS_UBOOT_BASE=0x40100000" >> "$UBOOT_DEF"
    echo "✅ U-Boot defconfig 物理修正完成"
fi

# 4. 彻底删除旧索引缓存 (全链路溯源强制要求)
rm -rf tmp
