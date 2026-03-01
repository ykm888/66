#!/bin/bash

# 1. 存储与内存定义物理锁定 (1024M)
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. U-Boot 2024.10 物理劫持 (解决链接报错与源码缺失)
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
    echo "U-Boot dependencies physically injected."
fi

# 3. DTS 物理路径与新文件名对齐 (核心修复)
# 使用你重命名后的新文件名：mt7981b-sl-3000-emmc.dts
SOURCE_DTS="custom-config/mt7981b-sl-3000-emmc.dts"

if [ -f "$SOURCE_DTS" ]; then
    # 针对 24.10/6.6 嵌套架构物理创建目录 (匹配 mk 文件的搜索路径)
    NESTED_DTS_PATH="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek/mediatek"
    mkdir -p "$NESTED_DTS_PATH"
    
    # 物理注入到系统覆盖目录
    cp -f "$SOURCE_DTS" "$NESTED_DTS_PATH/"
    
    # 物理暴力扫描 build_dir，确保编译中途解压的内核源码也被实时覆盖
    find build_dir/ -type d -path "*/arch/arm64/boot/dts/mediatek/mediatek" 2>/dev/null | xargs -I {} cp -f "$SOURCE_DTS" "{}/"
    echo "DTS $SOURCE_DTS physically synced to nested architecture."
fi

# 4. 镜像定义 filogic.mk 物理同步
if [ -f "custom-config/filogic.mk" ]; then
    cp -f "custom-config/filogic.mk" "target/linux/mediatek/image/filogic.mk"
    echo "filogic.mk physically updated."
fi

# 5. 内核符号物理修复 (sed 模式)
TARGET_H="target/linux/mediatek/files-6.6/drivers/net/ethernet/mediatek/mtk_eth_soc.h"
rm -f target/linux/mediatek/patches-6.6/999-sl3000-compat.patch

if [ -f "$TARGET_H" ]; then
    if ! grep -q "MTK_WIFI_RESET_DONE" "$TARGET_H"; then
        sed -i '15i #ifndef MTK_WIFI_RESET_DONE\n#define MTK_FE_START_RESET 0x10\n#define MTK_FE_RESET_DONE 0x11\n#define MTK_FE_RESET_NAT_DONE 0x14\n#define MTK_WIFI_CHIP_OFFLINE 0x12\n#define MTK_WIFI_CHIP_ONLINE 0x13\n#define HIT_BIND_FORCE_TO_CPU 1\n#define MTK_WIFI_RESET_DONE 0x16\n#endif\n' "$TARGET_H"
        echo "Kernel header symbols physically injected."
    fi
fi

exit 0
