#!/bin/bash

# 1. 物理环境清理
rm -rf tmp/
rm -f .config*

# 2. 物理移除冲突的 ASR3000 配置
find target/linux/mediatek/ -name "*asr3000*" -exec rm -rf {} +

# 3. 🛡️ 源头彻底解决：物理切除内核驱动中的未定义宏报错 (Error 1)
# 直接修改 target 目录下的 patch 源码或原始驱动文件，确保编译前代码已干净
echo "Applying physical fix for MTK_WIFI_CHIP_OFFLINE..."
find target/linux/mediatek/ -type f -name "*.c" -o -name "*.h" -o -name "*.patch" | xargs sed -i '/MTK_WIFI_CHIP_OFFLINE/d' 2>/dev/null

# 4. 强制内核版本锁定为 6.6
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

# 5. U-Boot 物理劫持逻辑 (针对 SL3000 eMMC)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 物理清理旧行，防止重复注入
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    # 物理注入 eMMC 引导配置
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

# 6. DRAM 物理内存锁定 (强制 1024M)
echo "Locking DRAM size to 1024M..."
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null

# 7. 物理确保脚本执行权限并退出
exit 0
