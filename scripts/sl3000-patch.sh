#!/bin/bash

# 1. 物理粉碎元数据缓存 (解决 ASR3000 阴魂不散)
rm -rf tmp/
rm -f .config*
rm -f .target-userconf

# 2. 物理清除 ASR3000 残余 (最高级别彻底删除)
find target/linux/mediatek/ -name "*asr3000*" -exec rm -rf {} +

# 3. 物理路径锁定 (自动处理 66/66 路径问题)
DTS_NAME="mt7981b-sl-3000-emmc.dts"
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DEST"

# 向上级目录搜寻，确保能抓到仓库根目录下的 Target 或 target
# 这里的逻辑是：不管你在哪个 66 目录下，只要能找到 DTS 就物理同步
SEARCH_PATH=$(find ../ -iname "$DTS_NAME" | head -n 1)

if [ -n "$SEARCH_PATH" ] && [ -f "$SEARCH_PATH" ]; then
    cp -f "$SEARCH_PATH" "$DTS_DEST/$DTS_NAME"
    echo "DTS Physical Found at: $SEARCH_PATH -> SUCCESS"
else
    # 最后的保底尝试：直接查找整个 runner 环境
    SEARCH_GLOBAL=$(find /home/runner/work/ -iname "$DTS_NAME" | head -n 1)
    if [ -n "$SEARCH_GLOBAL" ]; then
        cp -f "$SEARCH_GLOBAL" "$DTS_DEST/$DTS_NAME"
        echo "DTS Global Found at: $SEARCH_GLOBAL -> SUCCESS"
    else
        echo "CRITICAL ERROR: $DTS_NAME NOT FOUND!"
        exit 1
    fi
fi

# 4. U-Boot 物理劫持 (锁定 eMMC 引导链路)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

# 5. 内存 1024M 物理强制锁定
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null

exit 0
