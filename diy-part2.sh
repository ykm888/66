#!/bin/bash
echo "--- 物理执行：清创并注入心脏零件 ---"

# 1. 物理切除官方干扰
rm -rf openwrt/package/boot/arm-trusted-firmware-mediatek/patches
rm -rf openwrt/package/boot/uboot-mediatek/patches

cd openwrt

# 2. 强制拉起 Prepare，这里必须加上控制台屏蔽
# 某些 Makefile 会在 prepare 时检查终端，我们强行给它一个虚拟终端
TERM=xterm make package/boot/arm-trusted-firmware-mediatek/prepare V=s

# 3. 动态搜索 build_dir (解决路径名称带 hash 的问题)
# 修正 find 语法，确保在当前 openwrt 目录下搜索
ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d -print -quit)

if [ -n "$ATF_SRC" ]; then
    echo "定位成功，物理路径: $ATF_SRC"
    
    # 4. 零件强插
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/bl2"
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/include"
    
    cp -v ../main-repo/888/bl2_dev_spi_nor.c "$ATF_SRC/plat/mediatek/mt7981/bl2/"
    cp -v ../main-repo/888/platform_def.h "$ATF_SRC/plat/mediatek/mt7981/include/"
    
    # 5. 偏移量物理硬化
    if [ -f "$ATF_SRC/plat/mediatek/mt7981/platform.mk" ]; then
        sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
        echo "DRAM_USE_DDR4 := 1" >> "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
    fi

    # 6. 物理标记
    touch "$ATF_SRC/.prepared"*
    echo "--- 零件注入完成 ---"
else
    echo "物理报错：源码路径定位失败。可能是 make prepare 崩溃了。"
    exit 1
fi
