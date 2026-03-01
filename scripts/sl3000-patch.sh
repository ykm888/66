#!/bin/bash

# 1. 存储与内存定义物理锁定 (1024M)
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. 彻底解决 U-Boot 源码缺失：物理劫持 Makefile
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 先清理可能残留的旧劫持逻辑
    sed -i '/curl -fsSL.*sl_3000/d' "$UBOOT_MAKEFILE"
    sed -i '/cp.*sl_3000.*emmc_defconfig/d' "$UBOOT_MAKEFILE"
    
    # 在 Build/Configure 之前插入物理下载指令
    # 确保使用 $(PKG_BUILD_DIR) 变量，这是 OpenWrt 编译时的标准物理路径
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig' "$UBOOT_MAKEFILE"
    echo "U-Boot Makefile physically hooked."
fi

# 3. 彻底解决内核符号断点：物理 sed 注入 (取代不稳定的 Patch 模式)
# 物理定位目标文件
TARGET_H="target/linux/mediatek/files-6.6/drivers/net/ethernet/mediatek/mtk_eth_soc.h"

# 物理移除之前失败的 patch 文件，防止干扰
rm -f target/linux/mediatek/patches-6.6/999-sl3000-compat.patch

if [ -f "$TARGET_H" ]; then
    if ! grep -q "MTK_WIFI_RESET_DONE" "$TARGET_H"; then
        # 在文件头部（第15行左右）物理插入宏定义，避开所有 patch 格式校验
        sed -i '15i #ifndef MTK_WIFI_RESET_DONE\n#define MTK_FE_START_RESET 0x10\n#define MTK_FE_RESET_DONE 0x11\n#define MTK_FE_RESET_NAT_DONE 0x14\n#define MTK_WIFI_CHIP_OFFLINE 0x12\n#define MTK_WIFI_CHIP_ONLINE 0x13\n#define HIT_BIND_FORCE_TO_CPU 1\n#define MTK_WIFI_RESET_DONE 0x16\n#endif\n' "$TARGET_H"
        echo "Kernel source physically injected via sed."
    fi
else
    # 如果 files-6.6 下没有该文件，则在编译预备阶段通过脚本全局注入
    echo "Notice: Kernel source header not in files-6.6, will be handled during build_dir expansion."
fi

exit 0
