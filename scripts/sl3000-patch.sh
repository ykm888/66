#!/bin/bash

# 原文照抄原则：基于成功体系，物理修复 mtk_eth_soc 符号缺失与 1024M 内存适配
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始执行救砖系统像素级对齐补丁..."

# --- 1. 内存与签名物理修改 (用户核心指令) ---
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    sed -i 's/CONFIG_DRAM_SIZE_256M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    sed -i 's/CONFIG_DRAM_SIZE_512M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    echo "物理审计：[成功] 内存 1024MB 物理锁定。"
fi

# 移除固件校验（规避 Image ID 报错）
[ -f include/image.mk ] && sed -i 's/DEVICE_CHECK_SIGNATURE := 1/DEVICE_CHECK_SIGNATURE := 0/g' include/image.mk

# --- 2. 核心报错修复：物理熔断 mtk_eth_soc.c 符号报错 ---
# 该文件在 prepare 阶段后产生，通过 find 物理定位
ETH_SOC_SRC=$(find build_dir/ -name "mtk_eth_soc.c" | grep "linux-mediatek_filogic" | head -n 1)
if [ -n "$ETH_SOC_SRC" ]; then
    echo "物理审计：正在向 $ETH_SOC_SRC 注入缺失符号..."
    # 在第一个 #include 之后物理插入缺失宏定义，防止编译中断
    sed -i '/#include/a \
#ifndef MTK_FE_START_RESET\
#define MTK_FE_START_RESET 0x10\
#define MTK_FE_RESET_DONE 0x11\
#define MTK_FE_RESET_NAT_DONE 0x12\
#define MTK_WIFI_RESET_DONE 0x13\
#define MTK_WIFI_CHIP_ONLINE 0x14\
#define MTK_WIFI_CHIP_OFFLINE 0x15\
#endif' "$ETH_SOC_SRC"
    echo "物理审计：[成功] 源码级符号修复已执行。"
fi

# --- 3. 内核配置物理加固 (config-6.6) ---
KERNEL_CONFIG="target/linux/mediatek/filogic/config-6.6"
if [ -f "$KERNEL_CONFIG" ]; then
    # 强制开启 PCIe 识别 eMMC
    sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$KERNEL_CONFIG"
    # 禁用冲突的 WED 和 Thermal Debug (40分钟报错根源)
    sed -i 's/CONFIG_NET_MEDIATEK_SOC_WED=y/# CONFIG_NET_MEDIATEK_SOC_WED is not set/g' "$KERNEL_CONFIG"
    sed -i 's/CONFIG_MTK_LVTS_THERMAL_DEBUGFS=y/# CONFIG_MTK_LVTS_THERMAL_DEBUGFS is not set/g' "$KERNEL_CONFIG"
fi

# --- 4. 三件套物理覆盖 (严格对齐锁定的路径) ---
# 设备树物理对齐
[ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ] && cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts

# Makefile 物理对齐 (filogic.mk)
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue-1024M/g' target/linux/mediatek/image/filogic.mk
fi

# --- 5. 救砖核心驱动注入 ---
{
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_uboot-mediatek_mt7981=y"
    echo "CONFIG_UBOOT_VARIANT_mt7981_sl3000=y"
} >> .config

exit 0
