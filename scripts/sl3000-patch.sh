#!/bin/bash

# 1. 存储与内存定义物理锁定
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. 内核 mtk_eth_soc.c 物理补丁 (精准打击 MTK_WIFI_CHIP_OFFLINE 报错)
ETH_SOC_SRC=$(find build_dir/ -name "mtk_eth_soc.c" | grep "linux-mediatek_filogic" | head -n 1)
if [ -n "$ETH_SOC_SRC" ]; then
    # 物理注入：在 #include 行后插入缺失的宏定义，确保内核驱动顺利编译
    sed -i '/#include/a \
#ifndef MTK_FE_START_RESET\
#define MTK_FE_START_RESET 0x10\
#define MTK_FE_RESET_DONE 0x11\
#endif\
#ifndef MTK_WIFI_CHIP_OFFLINE\
#define MTK_WIFI_CHIP_OFFLINE 0x12\
#define MTK_WIFI_CHIP_ONLINE 0x13\
#endif' "$ETH_SOC_SRC"
fi

exit 0
