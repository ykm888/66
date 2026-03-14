#!/bin/bash

# =========================================================
# 司络 SL-3000 (MT7981B) 物理加固脚本 - ykm888 最终修正版
# 物理执行准则：强制清场 feeds 干扰，确保 1MB 偏移补丁注入
# =========================================================

echo "Starting Physical Injection for SL-3000..."

# --- 1. 物理清场：防止 feeds 软链接导致新 Makefile 失效 ---
# 必须删除旧路径，否则 git-feed 拉取的旧包会覆盖你的 888 零件
rm -rf package/boot/arm-trusted-firmware-mediatek
rm -rf package/feeds/devices/arm-trusted-firmware-mediatek
mkdir -p package/boot/arm-trusted-firmware-mediatek

# --- 2. 物理心脏：注入救砖驱动 (锁定 1MB 偏移量) ---
# 路径精准对齐源码中的 bl2 子目录
ATF_HEART="package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/bl2"
mkdir -p $ATF_HEART
if [ -f "888/bl2_dev_spi_nor.c" ]; then
    echo "Injecting: bl2_dev_spi_nor.c -> $ATF_HEART"
    cp -f 888/bl2_dev_spi_nor.c $ATF_HEART/bl2_dev_spi_nor.c
fi

# --- 3. 物理框架：覆盖引导零件 Makefile ---
# 确保使用修复后的 atf-Makefile (包含 BuildTrustedFirmwareA 宏调用)
echo "Injecting: Bootloader Makefiles"
[ -f "888/atf-Makefile" ] && cp -f 888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
[ -f "888/uboot-Makefile" ] && cp -f 888/uboot-Makefile package/boot/uboot-mediatek/Makefile

# --- 4. 物理地图：覆盖镜像打包逻辑 (解决 Error 1) ---
echo "Injecting: Image Building Logic (filogic.mk)"
[ -f "888/filogic.mk" ] && cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk

# --- 5. 物理零件：覆盖设备树 (DTS) ---
echo "Injecting: Device Tree Files"
cp -f 888/*.dts target/linux/mediatek/dts/

# --- 6. 物理控制：同步总控配置 (.config) ---
if [ -f "888/sl3000.config" ]; then
    echo "Deploying: sl3000.config -> .config"
    cp -f 888/sl3000.config .config
fi

# --- 7. 全局物理校准 (二次对齐 1MB 坐标) ---
# 强制将所有 mediatek 镜像生成的偏移量从 512k 修正为 1024k
echo "Patching: Global Offset Alignment to 1024k"
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/pad-to 512k/pad-to 1024k/g' {} +
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/seek=512/seek=1024/g' {} +

echo "Physical Injection Complete. All parts from 888 folder are deployed."
