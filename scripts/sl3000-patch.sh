#!/bin/bash

# 1. 物理环境初始化
rm -rf tmp/
rm -f .config*

# 2. 移除可能导致冲突的冗余文件
find target/linux/mediatek/ -name "*asr3000*" -exec rm -rf {} +

# 3. 🛡️ 核心修复：源头物理修正 (Error 1 终结者)
echo "Executing physical source-level fix while KEEPING Ethernet Driver enabled..."

# 第一步：物理移除导致 Hunk FAILED 的畸形补丁
rm -f target/linux/mediatek/patches-6.6/999-fix-mtk-eth-soc.patch

# 第二步：直接在源码中切除报错宏，确保 CONFIG_NET_MEDIATEK_SOC=y 能正常编译
# 我们直接针对内核源码目录进行物理修改
# 这里的逻辑是：在内核解压后，编译开始前，物理抹除掉那几行代码
find target/linux/mediatek/ -type f -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} +

# 4. 强制内核版本锁定为 6.6
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

# 5. U-Boot 物理劫持 (延续上一版原文照抄)
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_REGMAP=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig; \\\
\techo "CONFIG_SYSCON=y" >> $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig;' "$UBOOT_MAKEFILE"
fi

# 6. DRAM 内存锁定 (原文照抄，确保 1024M 物理生效)
echo "Locking DRAM size to 1024M..."
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
grep -rl "DRAM_SIZE_" target/linux/mediatek/image/ | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null

exit 0
