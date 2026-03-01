#!/bin/bash

# 1. Physical Metadata Clean (强制清理缓存，粉碎 ASR3000 幽灵索引)
rm -rf tmp/.config-target.in
rm -rf tmp/.target-userconf
rm -rf tmp/info/.target-*

# 2. Physical DTS Path Alignment (最高优先级路径对齐)
# 目标路径：Kernel 6.6 标准搜索目录
REAL_DTS_DIR="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$REAL_DTS_DIR"

# 从仓库源物理搬运到内核标准目录，确保 DEVICE_DTS 定义能找到文件
if [ -f "target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts" ]; then
    cp -f "target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts" "$REAL_DTS_DIR/"
    echo "DTS Physical Sync: SUCCESS"
else
    # 物理挽救：如果仓库源路径不对，从 custom-config 强推
    cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-sl-3000-emmc.dts" "$REAL_DTS_DIR/" || \
    cp -f "$GITHUB_WORKSPACE/custom-config/mt7981b-3000-emmc.dts" "$REAL_DTS_DIR/mt7981b-sl-3000-emmc.dts"
    echo "DTS Physical Rescue: SUCCESS"
fi

# 3. U-Boot Physical Hijack (劫持 U-Boot 以适配 eMMC 引导)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 清理旧劫持，防止重复注入
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/cp.*sl_3000.*emmc_defconfig/d' "$UBOOT_MAKEFILE"
    
    # 注入物理劫持逻辑
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

# 4. Global Memory Size Lock (强制锁定 1024M 寻址)
IMAGE_CONF_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_CONF_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_CONF_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_CONF_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

exit 0
