#!/bin/bash

# 1. Global Memory Size Lock (Ensure 1024M is selected in all device definitions)
IMAGE_CONF_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_CONF_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_CONF_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_CONF_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. U-Boot Physical Hijack (Critical for eMMC support)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/cp.*sl_3000.*emmc_defconfig/d' "$UBOOT_MAKEFILE"
    
    # Injecting the manual config overwrite into the U-Boot build process
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

# 3. Kernel Source Symbol Fix (Fixing potential compile errors in 6.6)
TARGET_H="target/linux/mediatek/files-6.6/drivers/net/ethernet/mediatek/mtk_eth_soc.h"
if [ -f "$TARGET_H" ] && ! grep -q "MTK_WIFI_RESET_DONE" "$TARGET_H"; then
    sed -i '15i #ifndef MTK_WIFI_RESET_DONE\n#define MTK_FE_START_RESET 0x10\n#define MTK_FE_RESET_DONE 0x11\n#define MTK_FE_RESET_NAT_DONE 0x14\n#define MTK_WIFI_CHIP_OFFLINE 0x12\n#define MTK_WIFI_CHIP_ONLINE 0x13\n#define HIT_BIND_FORCE_TO_CPU 1\n#define MTK_WIFI_RESET_DONE 0x16\n#endif\n' "$TARGET_H"
fi

exit 0
