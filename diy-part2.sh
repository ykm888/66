#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理投递脚本 (23.05 专用)
# =========================================================

echo "--- [物理溯源]：正在投递 11 个零件至 OpenWrt 预埋区 ---"

# 定义物理路径
ATF_FILES_PATH="openwrt/package/boot/arm-trusted-firmware-mediatek/files"
UBOOT_FILES_PATH="openwrt/package/boot/uboot-mediatek/files"

# 1. 物理目录初始化 (彻底清理旧残留)
rm -rf $ATF_FILES_PATH $UBOOT_FILES_PATH
mkdir -p $ATF_FILES_PATH $UBOOT_FILES_PATH

# 2. 劫持 Makefile (从 888 目录复制你修复好的完整版)
cp -f 888/atf-Makefile openwrt/package/boot/arm-trusted-firmware-mediatek/Makefile
cp -f 888/uboot-Makefile openwrt/package/boot/uboot-mediatek/Makefile

# 3. 投递 ATF 核心零件 (物理偏移补丁)
cp -f 888/bl2_dev_spi_nor.c $ATF_FILES_PATH/
cp -f 888/platform_def.h $ATF_FILES_PATH/
cp -f 888/platform.mk $ATF_FILES_PATH/
cp -f 888/bl2.mk $ATF_FILES_PATH/
cp -f 888/mt7981-spi2.dts $ATF_FILES_PATH/

# 4. 投递 U-Boot 核心零件 (设备树与分区配置)
cp -f 888/mt7981_sl3000_defconfig $UBOOT_FILES_PATH/
cp -f 888/mt7981-sl3000.dts $UBOOT_FILES_PATH/

# 5. 注入 23.05 物理编译锚点 (如果 .config 不存在则硬写)
if [ ! -f 888/sl3000.config ]; then
cat >> openwrt/.config <<EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y
CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y
CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-sl3000-nor=y
EOF
fi

echo "--- [物理溯源]：11 个零件已全部就位，准备筑基 ---"
