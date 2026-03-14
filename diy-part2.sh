#!/bin/bash
# =========================================================
# 司络 SL-3000 (MT7981B) 物理加固脚本 - 路径校准修复版
# =========================================================

echo "Starting Physical Injection for SL-3000..."

# --- 1. 物理清场 ---
# 彻底清理旧的 ATF 包，确保使用 888 目录下的修复版 Makefile
rm -rf package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/arm-trusted-firmware-mediatek

# --- 2. 物理注入核心 Makefile ---
# 原文照抄准则：必须确保 888 目录下的文件名准确无误
[ -f "888/atf-Makefile" ] && cp -f 888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
[ -f "888/uboot-Makefile" ] && cp -f 888/uboot-Makefile package/boot/uboot-mediatek/Makefile

# --- 3. 物理零件强制对齐 ---
# 注入物理地图 (C 源码)，Makefile 会将其物理覆盖到源码树中
# 注意：bl2_dev_spi_nor.c 必须保留在 888 目录，以便 Build/Prepare 阶段调用 $(TOPDIR)/888/
[ -f "888/filogic.mk" ] && cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk
[ -f "888/mt7981-sl-3000-emmc.dts" ] && cp -f 888/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts

# --- 4. 配置硬核锁定 ---
[ -f "888/sl3000.config" ] && cp -f 888/sl3000.config .config
# 物理补强：强制启用修复后的包名，确保不被 .config 自动剔除
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-nor-ddr4=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000_nor=y" >> .config

echo "Physical Injection Complete. All paths aligned."
