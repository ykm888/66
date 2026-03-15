#!/bin/bash
echo "--- 执行全链路诊断注入 ---"

# 1. 物理清创
rm -rf openwrt/package/boot/arm-trusted-firmware-mediatek/patches
rm -rf openwrt/package/boot/uboot-mediatek/patches

cd openwrt

# 2. 静默物理拉起源码 (必须在 defconfig 之后执行)
make package/boot/arm-trusted-firmware-mediatek/prepare V=s
make package/boot/uboot-mediatek/prepare V=s

# 3. 溯源定位 ATF 源码
ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d | head -n 1)

if [ -n "$ATF_SRC" ]; then
    echo "物理命中: $ATF_SRC"
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/bl2"
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/include"
    
    # 物理强灌零件
    cp -v ../main-repo/888/bl2_dev_spi_nor.c "$ATF_SRC/plat/mediatek/mt7981/bl2/"
    cp -v ../main-repo/888/platform_def.h "$ATF_SRC/plat/mediatek/mt7981/include/"
    
    # 锁定物理偏移：1MB 对齐
    sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
    echo "DRAM_USE_DDR4 := 1" >> "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
    
    touch "$ATF_SRC/.prepared"*
else
    echo "全链路诊断：ATF 源码目录物理缺失，检查上一步 defconfig"
    exit 1
fi

# 4. 溯源定位 U-Boot 并注入 DTS
UBOOT_SRC=$(find build_dir/target-aarch64* -name "u-boot-*" -type d | head -n 1)
if [ -n "$UBOOT_SRC" ]; then
    cp -v ../main-repo/888/mt7981_sl3000_defconfig "$UBOOT_SRC/configs/"
    [ -f "../main-repo/888/mt7981-sl3000.dts" ] && cp -v ../main-repo/888/mt7981-sl3000.dts "$UBOOT_SRC/arch/arm/dts/"
    touch "$UBOOT_SRC/.prepared"*
fi
