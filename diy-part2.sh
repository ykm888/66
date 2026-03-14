#!/bin/bash

# =========================================================
# 司络 SL-3000 (MT7981B) 物理加固脚本 - ykm888 专用版
# 规格：512M(限流)/1G RAM + 32MB SPI-NOR + 128GB eMMC
# =========================================================

echo "Starting Physical Injection for SL-3000..."

# --- 1. 物理心脏：注入救砖驱动 (锁定 1MB 偏移量) ---
# 必须精准对齐源码中的 bl2 子目录，否则偏移量修改无效
ATF_HEART="package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/bl2"
mkdir -p $ATF_HEART
if [ -f "888/bl2_dev_spi_nor.c" ]; then
    echo "Injecting: bl2_dev_spi_nor.c -> $ATF_HEART"
    cp -f 888/bl2_dev_spi_nor.c $ATF_HEART/bl2_dev_spi_nor.c
fi

# --- 2. 物理框架：覆盖引导零件 Makefile ---
# 确保编译器拉取你指定的 sl3000-clean-source 分支
echo "Injecting: Bootloader Makefiles"
[ -f "888/atf-Makefile" ] && cp -f 888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
[ -f "888/uboot-Makefile" ] && cp -f 888/uboot-Makefile package/boot/uboot-mediatek/Makefile

# --- 3. 物理地图：覆盖镜像打包逻辑 (解决 Error 1) ---
# 这里的 mk 文件包含了智能零件搜寻逻辑和 32MB 空间锁定
echo "Injecting: Image Building Logic (filogic.mk)"
[ -f "888/filogic.mk" ] && cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk

# --- 4. 物理零件：覆盖设备树 (DTS) ---
# 包含 512MB 内存限流、2.5G 网口、128GB eMMC 定义
echo "Injecting: Device Tree Files"
cp -f 888/*.dts target/linux/mediatek/dts/

# --- 5. 物理控制：同步总控配置 (.config) ---
# 锁定 PARTSIZE=24，防止 32MB 闪存溢出
if [ -f "888/sl3000.config" ]; then
    echo "Deploying: sl3000.config -> .config"
    cp -f 888/sl3000.config .config
fi

# --- 6. 物理校准补丁 (强制性二次对齐) ---
# 防止源码目录中其他隐藏的 mk 文件干扰 1MB (1024k) 偏移量
echo "Patching: Global Offset Alignment"
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/pad-to 512k/pad-to 1024k/g' {} +
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/seek=512/seek=1024/g' {} +

echo "Physical Injection Complete. Ready for make."
