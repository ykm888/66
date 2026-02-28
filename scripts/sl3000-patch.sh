#!/bin/bash

# 原文照抄原则：延续成功体系，执行救砖三件套补丁，物理修复 6.6 内核 40分钟熔断点
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始执行救砖系统像素级对齐补丁..."

# --- 1. 内存与签名物理修改 (您的核心要求) ---
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    sed -i 's/CONFIG_DRAM_SIZE_256M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    sed -i 's/CONFIG_DRAM_SIZE_512M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    echo "物理审计：[成功] 内存 1024MB 物理锁定。"
fi

# 移除固件校验（防止 image id 3 报错）
[ -f include/image.mk ] && sed -i 's/DEVICE_CHECK_SIGNATURE := 1/DEVICE_CHECK_SIGNATURE := 0/g' include/image.mk

# --- 2. 核心报错修复：物理熔断 40分钟 Error 2 ---
KERNEL_CONFIG="target/linux/mediatek/filogic/config-6.6"
if [ -f "$KERNEL_CONFIG" ]; then
    echo "物理审计：正在执行内核符号冲突物理修复..."
    # 物理强制：开启 PCIe (救砖核心)
    sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$KERNEL_CONFIG"
    # 物理强制：禁用 WED 和 Thermal Debug (消除 40分钟报错根源)
    sed -i 's/CONFIG_NET_MEDIATEK_SOC_WED=y/# CONFIG_NET_MEDIATEK_SOC_WED is not set/g' "$KERNEL_CONFIG"
    sed -i 's/CONFIG_MTK_LVTS_THERMAL_DEBUGFS=y/# CONFIG_MTK_LVTS_THERMAL_DEBUGFS is not set/g' "$KERNEL_CONFIG"
    # 内存寻址对齐
    echo "CONFIG_ZONE_DMA=y" >> "$KERNEL_CONFIG"
    echo "CONFIG_ZONE_DMA32=y" >> "$KERNEL_CONFIG"
fi

# --- 3. 三件套物理覆盖 (锁定您的指定路径) ---
# 设备树物理对齐 (128GB eMMC)
if [ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
fi

# Makefile 物理对齐 (filogic.mk)
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    # 救砖型号标识锁定
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue-1024M/g' target/linux/mediatek/image/filogic.mk
fi

# --- 4. 救砖核心驱动注入 (.config) ---
{
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_uboot-mediatek_mt7981=y"
    echo "CONFIG_UBOOT_VARIANT_mt7981_sl3000=y"
    echo "CONFIG_PACKAGE_luci-app-ksmbd=y"
} >> .config

exit 0
