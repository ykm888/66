#!/bin/bash

# =========================================================
# 司络 SL-3000 (MT7981B) 物理加固脚本 - 路径对齐修正版
# =========================================================

echo "Starting Physical Injection for SL-3000..."

# --- 1. 物理清场 ---
rm -rf package/boot/arm-trusted-firmware-mediatek
rm -rf package/feeds/devices/arm-trusted-firmware-mediatek
mkdir -p package/boot/arm-trusted-firmware-mediatek

# --- 2. 物理注入 ---
# 注入 Makefile
[ -f "888/atf-Makefile" ] && cp -f 888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
[ -f "888/uboot-Makefile" ] && cp -f 888/uboot-Makefile package/boot/uboot-mediatek/Makefile

# 物理加固：确保 888 零件仓库在根目录可见，供 Makefile 内部 Build/Prepare 调用
mkdir -p 888
[ -f "888/bl2_dev_spi_nor.c" ] || echo "Warning: bl2_dev_spi_nor.c missing in 888/"

# 注入其他零件到内核
[ -f "888/filogic.mk" ] && cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk
cp -f 888/*.dts target/linux/mediatek/dts/

# --- 3. 物理强推：使用真正的内核包名 ---
[ -f "888/sl3000.config" ] && cp -f 888/sl3000.config .config
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-nor-ddr4=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000_nor=y" >> .config

# --- 4. 偏移校准 ---
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/pad-to 512k/pad-to 1024k/g' {} +
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/seek=512/seek=1024/g' {} +

echo "Physical Injection Complete."
