#!/bin/bash

rm -rf tmp/
rm -f .config*

find target/linux/mediatek/ -name "*asr3000*" -exec rm -rf {} +

# 🛠️ Physical Fix: Fix MTK_WIFI_CHIP_OFFLINE compilation error in kernel 6.6
# This removes the offending case block that causes Error 1 in mtk_eth_soc.c
ETH_SOC_FILE="build_dir/target-aarch64_cortex-a53_musl/linux-mediatek_filogic/linux-6.6.95/drivers/net/ethernet/mediatek/mtk_eth_soc.c"
# We apply the fix via a generic find/sed to ensure it hits the right spot during build
find build_dir/ -name mtk_eth_soc.c -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/d' {} + 2>/dev/null

# Force kernel version to 6.6
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null

exit 0
