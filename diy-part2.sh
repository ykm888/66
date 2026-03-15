#!/bin/bash
echo "--- 物理执行：心脏零件注入 (SL-3000 DDR4) ---"

# 1. 物理清创：移除干扰补丁
rm -rf openwrt/package/boot/arm-trusted-firmware-mediatek/patches
rm -rf openwrt/package/boot/uboot-mediatek/patches

cd openwrt

# 2. 物理拉起：解压源码生成 build_dir
make package/boot/arm-trusted-firmware-mediatek/prepare V=s
make package/boot/uboot-mediatek/prepare V=s

# 3. 动态定位 ATF 源码路径
ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d | head -n 1)

if [ -n "$ATF_SRC" ]; then
    echo "物理命中 ATF: $ATF_SRC"
    # 创建补丁目录
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/bl2"
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/include"
    
    # 注入 888 零件 (偏移对齐 + DDR4 代码)
    cp -v ../main-repo/888/bl2_dev_spi_nor.c "$ATF_SRC/plat/mediatek/mt7981/bl2/"
    cp -v ../main-repo/888/platform_def.h "$ATF_SRC/plat/mediatek/mt7981/include/"
    
    # 准则：物理锁定 Makefile 中的 1MB 偏移逻辑
    # 强制将 FIP 基地址修改为 0x100000 (1MB)
    sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
    # 强制开启 DDR4 硬件定义
    echo "DRAM_USE_DDR4 := 1" >> "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
    
    # 物理锁定防覆盖
    touch "$ATF_SRC/.prepared"*
    echo "--- ATF 补丁强灌完成 ---"
else
    echo "物理报错：ATF 源码路径定位失败！"
    exit 1
fi

# 4. 定位 U-Boot 源码路径并注入你的 defconfig
UBOOT_SRC=$(find build_dir/target-aarch64* -name "u-boot-*" -type d | head -n 1)
if [ -n "$UBOOT_SRC" ]; then
    echo "物理命中 U-Boot: $UBOOT_SRC"
    cp -v ../main-repo/888/mt7981_sl3000_defconfig "$UBOOT_SRC/configs/"
    echo "--- U-Boot 配置注入完成 ---"
fi
