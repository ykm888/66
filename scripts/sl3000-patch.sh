#!/bin/bash

# 原文照抄原则：物理修复 U-Boot 配置缺失报错，彻底解决内核符号冲突
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：执行【终极兼容版】救砖补丁..."

# --- 1. 内存与签名物理修改 ---
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    sed -i 's/CONFIG_DRAM_SIZE_256M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
    sed -i 's/CONFIG_DRAM_SIZE_512M=y/CONFIG_DRAM_SIZE_1024M=y/g' "$MT7981_MK"
fi
[ -f include/image.mk ] && sed -i 's/DEVICE_CHECK_SIGNATURE := 1/DEVICE_CHECK_SIGNATURE := 0/g' include/image.mk

# --- 2. 彻底修复内核符号报错 (PPE & FE & WED) ---
ETH_SOC_SRC=$(find build_dir/ -name "mtk_eth_soc.c" | grep "linux-mediatek_filogic" | head -n 1)
if [ -n "$ETH_SOC_SRC" ]; then
    echo "物理审计：执行内核源码符号注入..."
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
fi

# --- 3. 物理修复 U-Boot 缺失：重定向到标准变体 ---
# 既然 sl_3000 变体不存在，我们物理修正 .config 指向标准 emmc 变体
sed -i 's/CONFIG_UBOOT_VARIANT_mt7981_sl3000=y/CONFIG_UBOOT_VARIANT_mt7981_emmc=y/g' .config

# --- 4. 三件套物理覆盖 ---
[ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ] && cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue-1024M/g' target/linux/mediatek/image/filogic.mk
fi

# --- 5. 驱动锁定（移除报错的变体注入） ---
{
    echo "CONFIG_PACKAGE_kmod-mmc=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_uboot-mediatek_mt7981=y"
    echo "CONFIG_UBOOT_VARIANT_mt7981_emmc=y"
} >> .config

exit 0
