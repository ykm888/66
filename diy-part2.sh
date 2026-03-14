#!/bin/bash

# --- 1. 物理定位 888 目录 ---
# GitHub Actions 运行空间通常在 ../888
LOCAL_888="../888"

# --- 2. 物理替换 ATF (底层启动零件) ---
# 自动寻找 ATF 源码路径
ATF_SRC="package/boot/arm-trusted-firmware-mediatek/src"

if [ -d "$LOCAL_888" ]; then
    # 替换平台定义头文件
    find $ATF_SRC -name "platform_def.h" | grep "mt7981" | xargs -I {} cp -f $LOCAL_888/platform_def.h {}
    # 替换 BL2 核心逻辑 (1MB 偏移的关键)
    find $ATF_SRC -name "bl2_dev_spi_nor.c" | xargs -I {} cp -f $LOCAL_888/bl2_dev_spi_nor.c {}
    # 替换 Makefile 零件
    find $ATF_SRC -name "platform.mk" | grep "mt7981" | xargs -I {} cp -f $LOCAL_888/platform.mk {}
fi

# --- 3. 物理注入救砖 DTS ---
DTS_DIR="package/boot/uboot-mediatek/files/arch/arm/dts"
mkdir -p $DTS_DIR
if [ -f "$LOCAL_888/mt7981-spi2.dts" ]; then
    cp -f $LOCAL_888/mt7981-spi2.dts $DTS_DIR/mt7981-sl3000.dts
fi

# --- 4. 物理锁定设备树 ---
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile
