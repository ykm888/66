#!/bin/bash
# SL-3000 24.10 救砖物理拉起脚本

echo "--- 物理执行：开始注入 888 心脏零件 ---"

# 1. 进入 OpenWrt 目录执行 Prepare
cd openwrt
make package/boot/arm-trusted-firmware-mediatek/prepare V=s

# 2. 物理定位源码路径 (适配 24.10 aarch64 架构)
ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d | head -n 1)

if [ -n "$ATF_SRC" ]; then
    echo "定位 ATF 物理路径: $ATF_SRC"
    
    # 3. 物理心脏注入
    cp -v ../main-repo/888/bl2_dev_spi_nor.c $ATF_SRC/plat/mediatek/mt7981/bl2/
    cp -v ../main-repo/888/platform_def.h $ATF_SRC/plat/mediatek/mt7981/include/
    
    # 4. 物理修改偏移量 (24.10 核心修复：将 FIP 锚定在 1MB)
    sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' $ATF_SRC/plat/mediatek/mt7981/platform.mk
    echo "DRAM_USE_DDR4 := 1" >> $ATF_SRC/plat/mediatek/mt7981/platform.mk

    # 5. 【准则二】物理伪装：防止编译时重新解压覆盖补丁
    find build_dir/target-aarch64* -name ".prepared_*" -exec touch {} \;
    echo "--- ATF 救砖零件注入成功 ---"
else
    echo "物理报错：找不到 ATF 源码，请检查 Makefile"
    exit 1
fi

# 6. U-Boot 设备树物理同步
UBOOT_SRC=$(find build_dir/target-aarch64* -name "uboot-*" -type d | head -n 1)
if [ -n "$UBOOT_SRC" ]; then
    cp -v ../main-repo/888/mt7981-spi2.dts $UBOOT_SRC/arch/arm/dts/mt7981-sl3000.dts
    echo 'dtb-y += mt7981-sl3000.dtb' >> $UBOOT_SRC/arch/arm/dts/Makefile
fi

echo "--- 物理拉起全流程结束 ---"
