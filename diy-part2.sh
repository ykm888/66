#!/bin/bash

# --- 1. 定义物理零件源 ---
LOCAL_888="../888"

# --- 2. 物理定位解压后的源码目录 ---
# 锁定具体的构建路径，确保 cp 命令有明确的物理目标
ATF_BUILD_DIR=$(find build_dir/target-aarch64_cortex-a53_musl -name "arm-trusted-firmware-mediatek-*" -type d | head -n 1)
UBOOT_BUILD_DIR=$(find build_dir/target-aarch64_cortex-a53_musl -name "uboot-mediatek-*" -type d | head -n 1)

echo "物理路径诊断:"
echo "ATF 源码路径: $ATF_BUILD_DIR"
echo "U-Boot 源码路径: $UBOOT_BUILD_DIR"

# --- 3. 像素级文件替换 (显式锁定文件名) ---
if [ -d "$LOCAL_888" ]; then
    # 替换 ATF 核心零件
    if [ -n "$ATF_BUILD_DIR" ]; then
        echo "正在物理替换 ATF 零件..."
        cp -v $LOCAL_888/platform_def.h "$ATF_BUILD_DIR/plat/mediatek/mt7981/include/platform_def.h"
        cp -v $LOCAL_888/bl2_dev_spi_nor.c "$ATF_BUILD_DIR/plat/mediatek/apsoc_common/drivers/spi_nand/mtk_spi_nand.c"
        cp -v $LOCAL_888/platform.mk "$ATF_BUILD_DIR/plat/mediatek/mt7981/platform.mk"
        cp -v $LOCAL_888/bl2.mk "$ATF_BUILD_DIR/plat/mediatek/apsoc_common/bl2.mk"
        cp -v $LOCAL_888/filogic.mk "$ATF_BUILD_DIR/plat/mediatek/mt7981/filogic.mk"
    fi

    # 替换 U-Boot 零件
    if [ -n "$UBOOT_BUILD_DIR" ]; then
        echo "正在物理替换 U-Boot 零件..."
        # 确保 DTS 目录物理存在
        mkdir -p "$UBOOT_BUILD_DIR/arch/arm/dts"
        cp -v $LOCAL_888/mt7981-spi2.dts "$UBOOT_BUILD_DIR/arch/arm/dts/mt7981-sl3000.dts"
    fi

    # 覆盖外层 Makefile (原子级锁定构建逻辑)
    echo "正在物理覆盖 Makefile 零件..."
    cp -v $LOCAL_888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
    cp -v $LOCAL_888/uboot-Makefile package/boot/uboot-mediatek/Makefile
fi

# --- 4. 锁定设备树名称 ---
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile
