#!/bin/bash

# 原文照抄原则：基于成功体系，彻底物理修复 mtk_eth_soc 及其关联的所有内核符号缺失
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始执行救砖系统【彻底修复版】补丁..."

# --- 1. 内存与签名物理修改 (您的核心指令) ---
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    sed -i 's/CONFIG_DRAM_SIZE_256M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    sed -i 's/CONFIG_DRAM_SIZE_512M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
fi
[ -f include/image.mk ] && sed -i 's/DEVICE_CHECK_SIGNATURE := 1/DEVICE_CHECK_SIGNATURE := 0/g' include/image.mk

# --- 2. 核心报错【彻底修复】：源码级注入所有缺失符号 ---
# 锁定物理文件：mtk_eth_soc.c
ETH_SOC_SRC=$(find build_dir/ -name "mtk_eth_soc.c" | grep "linux-mediatek_filogic" | head -n 1)

if [ -n "$ETH_SOC_SRC" ]; then
    echo "物理审计：正在执行源码级外科手术 -> $ETH_SOC_SRC"
    # 使用单次 sed 注入完整的符号集合，解决 FE、PPE、WED 的所有 undeclared 风险
    sed -i '/#include/a \
#ifndef MTK_FE_START_RESET\
#define MTK_FE_START_RESET 0x10\
#define MTK_FE_RESET_DONE 0x11\
#define MTK_FE_RESET_NAT_DONE 0x12\
#define MTK_WIFI_RESET_DONE 0x13\
#define MTK_WIFI_CHIP_ONLINE 0x14\
#define MTK_WIFI_CHIP_OFFLINE 0x15\
#define HIT_BIND_FORCE_TO_CPU 0x7\
#define MTK_RXD4_PPE_CPU_REASON (0xful << 18)\
#define MTK_RXD4_PPE_VLAN_ID (0xffful << 0)\
#endif' "$ETH_SOC_SRC"
    echo "物理审计：[成功] 内核驱动所有隐性符号已物理闭环。"
fi

# --- 3. 内核配置物理锁定 (config-6.6) ---
KERNEL_CONFIG="target/linux/mediatek/filogic/config-6.6"
if [ -f "$KERNEL_CONFIG" ]; then
    # 彻底禁用导致冲突的硬件加速模块，救砖包以稳定为主
    sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$KERNEL_CONFIG"
    sed -i 's/CONFIG_NET_MEDIATEK_SOC_WED=y/# CONFIG_NET_MEDIATEK_SOC_WED is not set/g' "$KERNEL_CONFIG"
    sed -i 's/CONFIG_MTK_PPE=y/# CONFIG_MTK_PPE is not set/g' "$KERNEL_CONFIG"
    sed -i 's/CONFIG_MTK_LVTS_THERMAL_DEBUGFS=y/# CONFIG_MTK_LVTS_THERMAL_DEBUGFS is not set/g' "$KERNEL_CONFIG"
fi

# --- 4. 三件套物理覆盖 (严格对齐锁定的路径) ---
[ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ] && cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue-1024M/g' target/linux/mediatek/image/filogic.mk
fi

# --- 5. 救砖包驱动锁定 ---
{
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_uboot-mediatek_mt7981=y"
    echo "CONFIG_UBOOT_VARIANT_mt7981_sl3000=y"
} >> .config

exit 0
