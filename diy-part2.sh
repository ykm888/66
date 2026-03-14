#!/bin/bash

# --- 1. 物理路径定义 ---
# 假设 888 目录位于 main-repo 内
LOCAL_888="../main-repo/888"

echo "--- 开始执行 SL-3000 物理硬化脚本 ---"

# --- 2. 强制覆盖 Makefile 规则 (最高优先级) ---
# 只有这样，系统才能识别出我们定义的 nor-ddr4 变体
if [ -d "$LOCAL_888" ]; then
    echo "正在注入物理 Makefile..."
    cp -v $LOCAL_888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
    cp -v $LOCAL_888/uboot-Makefile package/boot/uboot-mediatek/Makefile
    
    # --- 3. 动态扫描源码目录并注入心脏零件 ---
    # 这一步是为了防止某些环境下载后没触发 Makefile 的 Prepare 逻辑
    ATF_SRC=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*" -type d | head -n 1)
    if [ -n "$ATF_SRC" ]; then
        echo "发现 ATF 源码目录: $ATF_SRC"
        cp -v $LOCAL_888/platform_def.h "$ATF_SRC/plat/mediatek/mt7981/include/"
        cp -v $LOCAL_888/bl2_dev_spi_nor.c "$ATF_SRC/plat/mediatek/mt7981/bl2/"
        sed -i 's/DRAM_USE_DDR3/DRAM_USE_DDR4/g' "$ATF_SRC/plat/mediatek/mt7981/platform.mk"
    fi
fi

# --- 4. 锁定物理设备树 ---
# 确保 U-Boot 寻找的是我们在 uboot-Makefile 里注入的那个文件名
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile

echo "--- 物理链路校准完成 ---"
