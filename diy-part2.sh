#!/bin/bash
# =========================================================
# SL-3000 救砖全链路物理修复脚本 (自愈版)
# =========================================================

# 1. 物理定义绝对路径 (对齐 GitHub Actions 执行环境)
GITHUB_WORKSPACE="/home/runner/work/66/66"
REPO_PATH="${GITHUB_WORKSPACE}/sl3000-repo"

# 2. 物理平铺：直接对齐 package 目录，消除嵌套
if [ -d "$REPO_PATH/package" ]; then
    cp -rf "$REPO_PATH/package"/* ./package/
    echo "✅ 底层仓库 package 目录物理对齐完成"
else
    echo "❌ 物理错误：找不到底层仓库 package 目录"
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
