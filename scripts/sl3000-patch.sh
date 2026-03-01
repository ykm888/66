#!/bin/bash

# 1. 物理粉碎元数据缓存 (解决 ASR3000 阴魂不散、强制重新扫描 MK)
rm -rf tmp/
rm -f .config*
rm -f .target-userconf

# 2. 物理清除 ASR3000 残余 (最高级别彻底删除)
find target/linux/mediatek/ -name "*asr3000*" -exec rm -rf {} +

# 3. 物理路径锁定与同步 (锁定你提供的确切路径)
# 源路径：GitHub 工作区的确切位置
# 目标路径：内核 6.6 编译时的核心搜索位
DTS_NAME="mt7981b-sl-3000-emmc.dts"
DTS_SRC="$GITHUB_WORKSPACE/target/linux/mediatek/dts/$DTS_NAME"
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"

mkdir -p "$DTS_DEST"

if [ -f "$DTS_SRC" ]; then
    cp -f "$DTS_SRC" "$DTS_DEST/$DTS_NAME"
    echo "DTS Physical Found and Locked: $DTS_SRC -> SUCCESS"
else
    echo "CRITICAL ERROR: DTS NOT FOUND at $DTS_SRC"
    # 物理挽救：全盘深挖
    SEARCH_PATH=$(find $GITHUB_WORKSPACE -name "$DTS_NAME" | head -n 1)
    if [ -n "$SEARCH_PATH" ]; then
        cp -f "$SEARCH_PATH" "$DTS_DEST/$DTS_NAME"
        echo "DTS Physical Rescue from $SEARCH_PATH: SUCCESS"
    else
        exit 1
    fi
fi

# 4. U-Boot 物理劫持 (eMMC 引导链路锁定)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

# 5. 内存 1024M 物理硬锁定
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null

exit 0
