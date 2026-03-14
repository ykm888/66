#!/bin/bash

# --- 1. 定义物理零件源 ---
LOCAL_888="../888"

# --- 2. 物理定位解压后的源码目录 ---
# 搜索并锁定真实的 ATF 和 U-Boot 源码构建物理路径
ATF_BUILD_DIR=$(find build_dir/target-aarch64_cortex-a53_musl -name "arm-trusted-firmware-mediatek-*" -type d | head -n 1)
UBOOT_BUILD_DIR=$(find build_dir/target-aarch64_cortex-a53_musl -name "uboot-mediatek-*" -type d | head -n 1)

echo "物理路径诊断:"
echo "ATF 源码路径: $ATF_BUILD_DIR"
echo "U-Boot 源码路径: $UBOOT_BUILD_DIR"

# --- 3. 像素级文件替换 ---
if [ -d "$LOCAL_888" ]; then
    # 替换 ATF 底层驱动逻辑 (偏移量与 SPI NOR 驱动)
    if [ -n "$ATF_BUILD_DIR" ]; then
        cp -f $LOCAL_888/platform_def.h $ATF_BUILD_DIR/plat/mediatek/mt7981/include/
        cp -f $LOCAL_888/bl2_dev_spi_nor.c $ATF_BUILD_DIR/plat/mediatek/apsoc_common/drivers/spi_nand/
        cp -f $LOCAL_888/platform.mk $ATF_BUILD_DIR/plat/mediatek/mt7981/
        cp -f $LOCAL_888/bl2.mk $ATF_BUILD_DIR/plat/mediatek/apsoc_common/
        cp -f $LOCAL_888/filogic.mk $ATF_BUILD_DIR/plat/mediatek/mt7981/
    fi

    # 替换 U-Boot 设备树与配置
    if [ -n "$UBOOT_BUILD_DIR" ]; then
        cp -f $LOCAL_888/mt7981-spi2.dts $UBOOT_BUILD_DIR/arch/arm/dts/mt7981-sl3000.dts
    fi

    # 覆盖外层 Makefile (原子级锁定)
    cp -f $LOCAL_888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
    cp -f $LOCAL_888/uboot-Makefile package/boot/uboot-mediatek/Makefile
fi

# --- 4. 锁定设备树名称 ---
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile
