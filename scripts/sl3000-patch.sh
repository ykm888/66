#!/bin/bash

# 原文照抄原则：延续成功体系，执行救砖三件套补丁，物理修复 6.6 内核报错点
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始执行 43 分钟报错物理熔断补丁..."

# --- 1. 内存与签名物理修改 (用户指定逻辑) ---
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    # 强制锁定 1024MB 内存定义
    sed -i 's/CONFIG_DRAM_SIZE_256M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    sed -i 's/CONFIG_DRAM_SIZE_512M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    echo "物理审计：[成功] 1024MB 内存定义已锁定。"
fi

# 移除固件校验（防止 image id 3 报错）
[ -f include/image.mk ] && sed -i 's/DEVICE_CHECK_SIGNATURE := 1/DEVICE_CHECK_SIGNATURE := 0/g' include/image.mk

# --- 2. 核心报错修复：针对 6.6.95 内核的物理修正 ---
# 锁定仓库精确路径：target/linux/mediatek/filogic/config-6.6
KERNEL_CONFIG="target/linux/mediatek/filogic/config-6.6"
if [ -f "$KERNEL_CONFIG" ]; then
    echo "物理审计：正在执行内核符号表物理修复..."
    # 修复核心：开启 PCIe 物理链路（救砖包识别 eMMC 和无线的基础）
    sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$KERNEL_CONFIG"
    # 物理剔除：禁用导致 Musl 报错的调试选项
    sed -i 's/CONFIG_MTK_LVTS_THERMAL_DEBUGFS=y/# CONFIG_MTK_LVTS_THERMAL_DEBUGFS is not set/g' "$KERNEL_CONFIG"
    # 内存对齐：确保内核知晓 1GB 内存布局
    echo "CONFIG_ZONE_DMA=y" >> "$KERNEL_CONFIG"
    echo "CONFIG_ZONE_DMA32=y" >> "$KERNEL_CONFIG"
fi

# --- 3. 救砖三件套物理覆盖 ---
# 设备树物理适配 (锁定 128GB eMMC 名称)
[ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ] && cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts

# Makefile 物理对齐 (锁定 filogic.mk)
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    # 修改型号标识为 Rescue
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue-1024M/g' target/linux/mediatek/image/filogic.mk
fi

# --- 4. 救砖核心包驱动注入 ---
{
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_uboot-mediatek_mt7981=y"
    echo "CONFIG_UBOOT_VARIANT_mt7981_sl3000=y"
    # 注入之前提到的 ksmbd 软件包逻辑
    echo "CONFIG_PACKAGE_luci-app-ksmbd=y"
} >> .config

exit 0
