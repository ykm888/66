#!/bin/bash

# =========================================================
# 司络 SL-3000 (MT7981B) 物理加固脚本 - 终极修复版
# =========================================================

echo "Starting Physical Injection for SL-3000..."

# --- 1. 物理清场：防止 feeds 软链接干扰 ---
rm -rf package/boot/arm-trusted-firmware-mediatek
rm -rf package/feeds/devices/arm-trusted-firmware-mediatek
mkdir -p package/boot/arm-trusted-firmware-mediatek

# --- 2. 物理注入：Makefile 与 驱动补丁 ---
[ -f "888/atf-Makefile" ] && cp -f 888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
[ -f "888/uboot-Makefile" ] && cp -f 888/uboot-Makefile package/boot/uboot-mediatek/Makefile

# 注入 bl2 物理驱动补丁
ATF_SRC_DIR="package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/bl2"
if [ -f "888/bl2_dev_spi_nor.c" ]; then
    mkdir -p $ATF_SRC_DIR
    cp -f 888/bl2_dev_spi_nor.c $ATF_SRC_DIR/bl2_dev_spi_nor.c
fi

# --- 3. 物理注入：打包逻辑与设备树 ---
[ -f "888/filogic.mk" ] && cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk
cp -f 888/*.dts target/linux/mediatek/dts/

# --- 4. 物理强推：配置锁定 (防止 defconfig 熔断) ---
[ -f "888/sl3000.config" ] && cp -f 888/sl3000.config .config
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000_nor=y" >> .config

# --- 5. 偏移校准：1024k (1MB) 强制对齐 ---
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/pad-to 512k/pad-to 1024k/g' {} +
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/seek=512/seek=1024/g' {} +

echo "Physical Injection Complete. Ready to make."
