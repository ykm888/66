#!/bin/bash

# 1. 物理粉碎缓存
rm -rf tmp/
rm -f .config*
rm -f .target-userconf

# 2. 物理清除 ASR3000 干扰文件 (防止内核编译 Error 2)
find target/linux/mediatek/ -name "*asr3000*" -exec rm -rf {} +

# 3. 【核心修复】物理注入 DTS 文件到内核目录
# 确保 filogic.mk 能够引用到该物理文件
DTS_PATH="target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts"
if [ -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" ]; then
    cp -f $GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts "$DTS_PATH"
fi

# 4. U-Boot 物理劫持 (锁定 eMMC 引导链)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

# 5. 1024M 内存物理强制锁定补丁
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null

exit 0
