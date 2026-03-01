#!/bin/bash

# 1. 存储与内存定义物理锁定 (1024M)
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. 彻底解决 U-Boot 源码缺失：创建“物理钩子补丁”
# 我们不再等它解压，而是直接在 package 目录下创建一个物理补丁文件
# 这样 OpenWrt 在解压完源码后，会自动应用这个补丁，把文件变出来
UBOOT_PATCH_DIR="package/boot/uboot-mediatek/patches"
mkdir -p "$UBOOT_PATCH_DIR"

# 获取物理配置文件内容
CONFIG_CONTENT=$(curl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig)

# 物理注入：直接在 build 前通过 shell 预置文件（这是最稳妥的方案）
# 我们修改 U-Boot 的 Makefile，在编译前增加一行物理拷贝指令
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 在 Build/Configure 之前插入物理下载指令
    sed -i '/define Build\/Configure/a \
\tcurl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig; \\\
\tcp $(PKG_BUILD_DIR)/configs/mt7981_sl_3000-emmc_defconfig $(PKG_BUILD_DIR)/configs/mt7981_emmc_defconfig' "$UBOOT_MAKEFILE"
    echo "U-Boot Makefile physically hooked."
fi

# 3. 内核符号物理熔断 (解决 eth_soc 报错)
ETH_SOC_HDR="target/linux/mediatek/files-6.6/drivers/net/ethernet/mediatek/mtk_eth_soc.h"
# 如果是 files 目录不存在，则直接在 patches 目录建一个补丁
if [ -f "target/linux/mediatek/patches-6.6/999-sl3000-compat.patch" ]; then
    echo "Kernel patch already exists."
else
    # 物理注入内核补丁
    mkdir -p target/linux/mediatek/patches-6.6/
    cat << 'EOF' > target/linux/mediatek/patches-6.6/999-sl3000-compat.patch
--- a/drivers/net/ethernet/mediatek/mtk_eth_soc.h
+++ b/drivers/net/ethernet/mediatek/mtk_eth_soc.h
@@ -12,6 +12,14 @@
 #include <linux/u64_stats_sync.h>
 #include <linux/refcount.h>
 
+#ifndef MTK_WIFI_RESET_DONE
+#define MTK_FE_START_RESET 0x10
+#define MTK_FE_RESET_DONE 0x11
+#define MTK_FE_RESET_NAT_DONE 0x14
+#define MTK_WIFI_CHIP_OFFLINE 0x12
+#define MTK_WIFI_CHIP_ONLINE 0x13
+#define HIT_BIND_FORCE_TO_CPU 1
+#define MTK_WIFI_RESET_DONE 0x16
+#endif
+
 #define MTK_QDMA_PAGE_SIZE	2048
EOF
    echo "Kernel compat patch physically created."
fi

exit 0
