#!/bin/bash

# --- 1. 物理置顶：Makefile 缝合 ---
# 将 888 里的 Makefile 强制推送到官方构建路径，启动你的 sl3000-clean-source 源码抓取
[ -f "888/atf-Makefile" ] && cp -f 888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
[ -f "888/uboot-Makefile" ] && cp -f 888/uboot-Makefile package/boot/uboot-mediatek/Makefile

# --- 2. 物理移植：救砖驱动注入 ---
# 无论源码何时拉取，强行将救砖驱动注入到 ATF 的物理心脏位置
ATF_SRC="package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981"
mkdir -p $ATF_SRC
[ -f "888/bl2_dev_spi_nor.c" ] && cp -f 888/bl2_dev_spi_nor.c $ATF_SRC/bl2_dev_spi_nor.c

# --- 3. 物理地图：镜像偏移补丁 ---
# 直接使用你 888 里的 filogic.mk 覆盖官方，确保 1MB (1024k) 物理坐标生效
[ -f "888/filogic.mk" ] && cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk

# --- 4. 物理零件：设备树与配置同步 ---
# 拉起所有 .dts 硬件定义
cp -f 888/*.dts target/linux/mediatek/dts/

# 拉起 sl3000.config 作为编译总控
[ -f "888/sl3000.config" ] && cp -f 888/sl3000.config .config

# --- 5. 物理校验 (可选) ---
echo "Physical Injection Complete: All parts from 888 folder have been deployed."
