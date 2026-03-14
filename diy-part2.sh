#!/bin/bash

# --- 1. 定义物理源路径 ---
# 假设 888 目录位于与 openwrt 目录同级的 main-repo 中
LOCAL_888="../main-repo/888"

# --- 2. 动态定位源码物理位置 ---
ATF_PATH=$(find build_dir/target-aarch64* -name "arm-trusted-firmware-*-ddr4" -type d | head -n 1)
UBOOT_PATH=$(find build_dir/target-aarch64* -name "uboot-*-ddr4" -type d | head -n 1)

echo "--- 物理链路诊断 ---"
echo "ATF 源码路径: $ATF_PATH"
echo "U-Boot 源码路径: $UBOOT_PATH"

# --- 3. 零件物理投送与硬化 ---
if [ -d "$LOCAL_888" ]; then
    # 覆盖外层 Makefile（确保 Actions 规则生效）
    cp -v $LOCAL_888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
    cp -v $LOCAL_888/uboot-Makefile package/boot/uboot-mediatek/Makefile

    # ATF 源码级加固
    if [ -n "$ATF_PATH" ]; then
        echo "正在注入 1MB 偏移逻辑与 DDR4 参数..."
        cp -v $LOCAL_888/platform_def.h "$ATF_PATH/plat/mediatek/mt7981/include/"
        cp -v $LOCAL_888/bl2_dev_spi_nor.c "$ATF_DIR/plat/mediatek/mt7981/bl2/" 2>/dev/null || \
        cp -v $LOCAL_888/bl2_dev_spi_nor.c "$ATF_PATH/plat/mediatek/mt7981/bl2/bl2_dev_spi_nor.c"
        
        # 强制删除 DDR3 编译宏，锁定 DDR4 物理电平
        sed -i 's/DRAM_USE_DDR3/DRAM_USE_DDR4/g' "$ATF_PATH/plat/mediatek/mt7981/platform.mk"
        echo "DRAM_USE_DDR4 := 1" >> "$ATF_PATH/plat/mediatek/mt7981/platform.mk"
    fi

    # U-Boot DTS 投送
    if [ -n "$UBOOT_PATH" ]; then
        mkdir -p "$UBOOT_PATH/arch/arm/dts/"
        cp -v $LOCAL_888/mt7981-spi2.dts "$UBOOT_PATH/arch/arm/dts/mt7981-sl3000.dts"
    fi
fi

# --- 4. 锁定 U-Boot 配置闭环 ---
# 确保 U-Boot 寻找的是你刚考进去的 mt7981-sl3000.dts
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile
