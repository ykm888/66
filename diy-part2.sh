#!/bin/bash
# =========================================================
# SL-3000 救砖物理对齐脚本
# =========================================================

GITHUB_WORKSPACE="/home/runner/work/66/66"
REPO_PATH="${GITHUB_WORKSPACE}/sl3000-repo"

# 1. 物理对齐 package
if [ -d "$REPO_PATH/package" ]; then
    cp -rf "$REPO_PATH/package"/* ./package/
    echo "✅ 底层仓库 package 目录物理对齐完成"
fi

# 2. 物理修正 U-Boot 参数
UBOOT_DEF="package/boot/uboot-mediatek/configs/mt7981_nor_emmc_rfb_defconfig"
if [ -f "$UBOOT_DEF" ]; then
    sed -i 's/CONFIG_IPADDR=.*/CONFIG_IPADDR="192.168.31.1"/' "$UBOOT_DEF"
    sed -i 's/CONFIG_MTDPARTS_DEFAULT=.*/CONFIG_MTDPARTS_DEFAULT="nor0:1024k(bl2),2048k(fip),-(storage)"/' "$UBOOT_DEF"
    grep -q "CONFIG_SYS_UBOOT_BASE" "$UBOOT_DEF" || echo "CONFIG_SYS_UBOOT_BASE=0x40100000" >> "$UBOOT_DEF"
    echo "✅ U-Boot defconfig 物理修正完成"
fi

# 3. 彻底刷新索引
rm -rf tmp
