#!/bin/bash

# 1. 存储与内存定义物理锁定 (1024M)
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. U-Boot 2024.10 物理依赖修复
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/cp.*sl_3000.*emmc_defconfig/d' "$UBOOT_MAKEFILE"
    sed -i '/echo.*CONFIG_REGMAP/d' "$UBOOT_MAKEFILE"
    sed -i '/echo.*CONFIG_SYSCON/d' "$UBOOT_MAKEFILE"
    
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

# 3. DTS 物理路径对齐 (修正为单层嵌套)
SOURCE_DTS="custom-config/mt7981b-sl-3000-emmc.dts"
if [ -f "$SOURCE_DTS" ]; then
    # 物理路径锁定：匹配修正后的 mk 文件路径
    for TARGET_PATH in "files" "files-6.6"; do
        DTS_DEST="target/linux/mediatek/$TARGET_PATH/arch/arm64/boot/dts/mediatek"
        mkdir -p "$DTS_DEST"
        cp -f "$SOURCE_DTS" "$DTS_DEST/"
    done
    
    # 物理暴力扫描 build_dir
    find build_dir/ -type d -path "*/arch/arm64/boot/dts/mediatek" 2>/dev/null | xargs -I {} cp -f "$SOURCE_DTS" "{}/"
    echo "DTS physically synced to standard path."
fi

# 4. 镜像配置物理覆盖
if [ -f "custom-config/filogic.mk" ]; then
    cp -f "custom-config/filogic.mk" "target/linux/mediatek/image/filogic.mk"
fi

# 5. 内核符号物理修复
TARGET_H="target/linux/mediatek/files-6.6/drivers/net/ethernet/mediatek/mtk_eth_soc.h"
rm -f target/linux/mediatek/patches-6.6/999-sl3000-compat.patch
if [ -f "$TARGET_H" ]; then
    if ! grep -q "MTK_WIFI_RESET_DONE" "$TARGET_H"; then
        sed -i '15i #ifndef MTK_WIFI_RESET_DONE\n#define MTK_FE_START_RESET 0x10\n#define MTK_FE_RESET_DONE 0x11\n#define MTK_FE_RESET_NAT_DONE 0x14\n#define MTK_WIFI_CHIP_OFFLINE 0x12\n#define MTK_WIFI_CHIP_ONLINE 0x13\n#define HIT_BIND_FORCE_TO_CPU 1\n#define MTK_WIFI_RESET_DONE 0x16\n#endif\n' "$TARGET_H"
    fi
fi

exit 0
