#!/bin/bash

# 1. 物理粉碎元数据缓存 (解决 ASR3000 阴魂不散的终极手段)
rm -rf tmp/
rm -f .config*
rm -f .target-userconf

# 2. 物理清除 ASR3000 (最高级别彻底删除)
# 在源码的所有路径中，强制切除 ASR3000 的痕迹
find target/linux/mediatek/ -name "*asr3000*" -exec rm -rf {} +

# 3. 强制路径映射 (锁定你的源路径)
# 源路径: target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
# 目标路径: 内核 6.6 核心搜索位
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DEST"

if [ -f "target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts" ]; then
    cp -f "target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts" "$DTS_DEST/mt7981b-sl-3000-emmc.dts"
    echo "DTS Physical Lock: SUCCESS"
else
    echo "ERROR: Source DTS not found at target/linux/mediatek/dts/"
    exit 1
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

# 5. 内存 1024M 物理强制锁定
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null

exit 0
