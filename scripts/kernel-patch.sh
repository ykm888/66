#!/bin/bash

# 物理审计：修复 mtk_eth_soc.c 编译报错，补全缺失的宏定义
# 适用内核：6.6.95

# 定位目标头文件（在 OpenWrt 编译目录中）
TARGET_H="build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/linux-6.6.95/drivers/net/ethernet/mediatek/mtk_eth_soc.h"

if [ -f "$TARGET_H" ]; then
    echo "物理注入：补全 mtk_eth_soc.h 缺失的宏定义..."
    
    # 1. 注入 PPE 相关定义 (HIT_BIND_FORCE_TO_CPU)
    if ! grep -q "HIT_BIND_FORCE_TO_CPU" "$TARGET_H"; then
        sed -i '/define MTK_RXD4_PPE_CPU_REASON/a #define HIT_BIND_FORCE_TO_CPU\t0x0b' "$TARGET_H"
    fi

    # 2. 注入 FE/WIFI 重置相关定义
    if ! grep -q "MTK_FE_START_RESET" "$TARGET_H"; then
        printf "\n/* Added by SL3000 Physical Patch */\n" >> "$TARGET_H"
        printf "#define MTK_FE_START_RESET\t\t0x01\n" >> "$TARGET_H"
        printf "#define MTK_FE_RESET_DONE\t\t0x02\n" >> "$TARGET_H"
        printf "#define MTK_FE_RESET_NAT_DONE\t0x03\n" >> "$TARGET_H"
        printf "#define MTK_WIFI_RESET_DONE\t\t0x04\n" >> "$TARGET_H"
        printf "#define MTK_WIFI_CHIP_ONLINE\t0x05\n" >> "$TARGET_H"
        printf "#define MTK_WIFI_CHIP_OFFLINE\t0x06\n" >> "$TARGET_H"
    fi
    echo "物理注入完成。"
else
    echo "警告：未找到目标头文件，可能尚未执行 make target/linux/prepare"
fi
