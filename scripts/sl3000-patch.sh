#!/bin/bash

# 1. 物理粉碎元数据缓存 (最高级别清理)
# 彻底删除所有缓存的设备树索引和配置摘要
rm -rf tmp/
rm -rf .config*
rm -f .target-userconf

# 2. 物理清除 ASR3000 残余 (防复活逻辑)
# 在源码的所有可能路径中，彻底物理删除 ASR3000 相关 DTS
find target/linux/mediatek/ -name "*asr3000*" -exec rm -f {} +

# 3. 物理路径对齐 (确保你的 SL-3000 占据核心位置)
# 既然你仓库里有，我们通过脚本再次确认它在内核最高优先级搜索目录
REAL_DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$REAL_DTS_DIR"
if [ -f "target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts" ]; then
    cp -f "target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts" "$REAL_DTS_DIR/"
fi

# 4. U-Boot 物理劫持 (核心 eMMC 引导链路)
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
