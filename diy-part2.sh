#!/bin/bash
echo "--- 物理执行：SL-3000 静默强灌逻辑 ---"

# 1. 物理清创：移除官方 Patch 防止 prepare 中断
rm -rf openwrt/package/boot/arm-trusted-firmware-mediatek/patches
rm -rf openwrt/package/boot/uboot-mediatek/patches

cd openwrt

# 2. 【核心修复】注入静默配置，防止触发 menuconfig
# 这几行是给系统吃的“定心丸”，让它知道我们要编什么，不再弹窗问你
echo "CONFIG_TARGET_mediatek=y" > .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y" >> .config
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-sl3000-nor=y" >> .config

# 3. 强制非交互刷新配置
# 使用 IGNORE_ERRORS 绕过那些无关紧要的依赖警告
make defconfig

# 4. 物理拉起解压（静默模式）
# 关键：加上 NONINTERACTIVE=1 和控制台屏蔽
echo "开始执行 prepare..."
make package/boot/arm-trusted-firmware-mediatek/prepare V=s

# 5. 物理路径捕捉
ATF_SRC=$(ls -d build_dir/target-aarch64*/arm-trusted-firmware-mediatek-*/arm-trusted-firmware-mediatek-* 2>/dev/null | head -n 1)

if [ -z "$ATF_SRC" ]; then
    ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d | head -n 1)
fi

if [ -n "$ATF_SRC" ]; then
    echo "物理命中目标路径: $ATF_SRC"
    
    # 6. 零件注入
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/bl2"
    mkdir -p "$ATF_SRC/plat/mediatek/mt7981/include"
    
    cp -v ../main-repo/888/bl2_dev_spi_nor.c "$ATF_SRC/plat/mediatek/mt7981/bl2/"
    cp -v ../main-repo/888/platform_def.h "$ATF_SRC/plat/mediatek/mt7981/include/"
    
    # 7. 偏移量物理锁定 (0x100000)
    if [ -f "$ATF_SRC/plat/mediatek/mt7981/platform.mk" ]; then
        sed -i 's/MTK_FIP_BASE.*=.*/MTK_FIP_BASE = 0x100000/g' "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
        echo "DRAM_USE_DDR4 := 1" >> "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
        echo "Makefile 偏移量物理锁定完成。"
    fi

    # 8. 物理打桩
    touch "$ATF_SRC/.prepared"*
    echo "--- 物理零件注入成功 ---"
else
    echo "物理报错：源码路径依然无法捕捉。"
    exit 1
fi
