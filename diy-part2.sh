#!/bin/bash
# SL-3000 救砖物理拉起脚本 - 最终清创版

echo "--- 物理执行：开始清创并注入心脏零件 ---"

# 1. 【核心修复】删除官方补丁目录，防止 Patch Failed 错误
# 因为你使用的是自己的分支，官方补丁会导致冲突
rm -rf openwrt/package/boot/arm-trusted-firmware-mediatek/patches
rm -rf openwrt/package/boot/uboot-mediatek/patches

cd openwrt

# 2. 强制拉起解压源码
# 没有补丁干扰，这一步一定会成功生成 build_dir 路径
make package/boot/arm-trusted-firmware-mediatek/prepare V=s

# 3. 精准定位源码物理路径
ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d | head -n 1)

if [ -n "$ATF_SRC" ]; then
    echo "定位成功，物理路径: $ATF_SRC"
    
    # 4. 强制创建目录架构（防止 cp 报错）
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/bl2"
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/include"
    
    # 5. 注入 888 核心零件
    cp -v ../main-repo/888/bl2_dev_spi_nor.c "$ATF_SRC/plat/mediatek/mt7981/bl2/"
    cp -v ../main-repo/888/platform_def.h "$ATF_SRC/plat/mediatek/mt7981/include/"
    
    # 6. 物理修改偏移量定义 (锁定 1MB 偏移)
    if [ -f "$ATF_SRC/plat/mediatek/mt7981/platform.mk" ]; then
        sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
        echo "DRAM_USE_DDR4 := 1" >> "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
        echo "Makefile 偏移量已物理锁定为 0x100000"
    fi

    # 7. 打桩，防止编译阶段二次解压
    find build_dir/target-aarch64* -name ".prepared*" -exec touch {} \;
    echo "--- 物理心脏注入完成 ---"
else
    echo "物理报错：源码路径定位失败，请检查编译环境"
    exit 1
fi
