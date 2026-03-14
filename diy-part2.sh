#!/bin/bash
# SL-3000 物理拉起脚本

echo "--- 物理心脏注入开始 ---"

cd openwrt

# 1. 触发下载分支源码
make package/boot/arm-trusted-firmware-mediatek/prepare V=s

# 2. 定位物理路径
ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d | head -n 1)

if [ -n "$ATF_SRC" ]; then
    echo "物理注入目标: $ATF_SRC"
    
    # 3. 强插 888 零件 (假设 888 目录在主仓库内)
    cp -v ../main-repo/888/bl2_dev_spi_nor.c $ATF_SRC/plat/mediatek/mt7981/bl2/
    cp -v ../main-repo/888/platform_def.h $ATF_SRC/plat/mediatek/mt7981/include/
    
    # 4. 物理强制锁定 1MB 偏移与 DDR4
    sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' $ATF_SRC/plat/mediatek/mt7981/platform.mk
    echo "DRAM_USE_DDR4 := 1" >> $ATF_SRC/plat/mediatek/mt7981/platform.mk

    # 5. 状态打桩
    find build_dir/target-aarch64* -name ".prepared_*" -exec touch {} \;
    echo "--- 心脏注入成功 ---"
else
    echo "物理报错：找不到 ATF 源码"
    exit 1
fi
