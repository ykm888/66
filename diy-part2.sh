#!/bin/bash
# SL-3000 DDR4 救砖物理心脏强灌脚本

echo "--- 1. 物理清创：移除官方 Patch 干扰 ---"
# 必须先删除 patches，否则你的 clean-source 分支会因为冲突而解压失败
rm -rf openwrt/package/boot/arm-trusted-firmware-mediatek/patches
rm -rf openwrt/package/boot/uboot-mediatek/patches

cd openwrt

echo "--- 2. 物理拉起：解压 ATF 源码 ---"
# 这里只执行 prepare，目的是生成 build_dir 路径
make package/boot/arm-trusted-firmware-mediatek/prepare V=s

# 3. 动态捕捉源码物理路径 (适配 23.05 的路径深度)
ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d | head -n 1)

if [ -n "$ATF_SRC" ]; then
    echo "物理命中路径: $ATF_SRC"
    
    # 4. 强制建立物理架构
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/bl2"
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/include"
    
    # 5. 注入 888 核心零件
    # 注意：这里的路径是指向相对于 openwrt 目录的外部 main-repo/888
    cp -v ../main-repo/888/bl2_dev_spi_nor.c "$ATF_SRC/plat/mediatek/mt7981/bl2/"
    cp -v ../main-repo/888/platform_def.h "$ATF_SRC/plat/mediatek/mt7981/include/"
    
    # 6. 物理锁定 1MB 偏移量 (针对 NOR Flash)
    if [ -f "$ATF_SRC/plat/mediatek/mt7981/platform.mk" ]; then
        sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
        echo "DRAM_USE_DDR4 := 1" >> "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
        echo "Makefile 偏移量物理锁定为 0x100000"
    fi

    # 7. 物理打桩：防止后续步骤重新解压覆盖了我们的零件
    touch "$ATF_SRC/.prepared"*
    echo "--- 零件强灌完成 ---"
else
    echo "物理报错：源码路径捕捉失败，请检查 make prepare 日志！"
    exit 1
fi
