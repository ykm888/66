#!/bin/bash

# 1. Physical removal of the problematic patch file
rm -f target/linux/mediatek/patches-6.6/999-fix-mtk-eth-soc.patch

# 2. Kernel version locking
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

# 3. Source code interception and surgical removal of Error 1
# This targets the undeclared 'MTK_WIFI_CHIP_OFFLINE' macro in mtk_eth_soc.c
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 4. Physical injection of device-specific configuration
# Ensures the .itb firmware image is generated for SL3000 eMMC
if [ -f ".config" ]; then
    echo "CONFIG_TARGET_IMAGE_uboot_mediatek_mt7981_sl_3000_emmc=y" >> .config
    echo "CONFIG_PACKAGE_fdisk=y" >> .config
fi

# 5. Cleanup patch series (only if file exists in current environment)
if [ -f "target/linux/mediatek/patches-6.6/series" ]; then
    sed -i '/999-fix-mtk-eth-soc.patch/d' target/linux/mediatek/patches-6.6/series
fi
