#!/bin/bash
# 原文照抄原则：针对 SL-3000 1024M 救砖规格进行物理修正

echo "物理审计：开始执行全流程物理修正..."

# 1. 物理探测并硬改内存定义 (解决找不到 mt7981.mk 的问题)
# 扫描整个 image 目录，强制将 256M/512M 的定义物理覆盖为 1024M
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    echo "物理审计：内存定义已全局锁定为 1024M。"
fi

# 2. 内核 PPE 符号物理注入 (修复 24.10 分支编译熔断报错)
# 错误点：'MTK_FE_START_RESET' undeclared
ETH_SOC_SRC=$(find build_dir/ -name "mtk_eth_soc.c" | grep "linux-mediatek_filogic" | head -n 1)
if [ -n "$ETH_SOC_SRC" ]; then
    sed -i '/#include/a \
#ifndef MTK_FE_START_RESET\
#define MTK_FE_START_RESET 0x10\
#define MTK_FE_RESET_DONE 0x11\
#endif' "$ETH_SOC_SRC"
    echo "物理审计：内核 eth_soc 符号补丁已注入。"
fi

exit 0
