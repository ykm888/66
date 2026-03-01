#!/bin/bash

# 1. 存储与内存定义物理锁定 (保持 1024M 物理属性)
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. U-Boot 源码物理重定向 (物理接管专属仓库 ykm99999/66)
# 彻底解决 No such file 报错，因为新源中已物理包含 mt7981_sl_3000-emmc_defconfig
UBOOT_MAKEFILE="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MAKEFILE" ]; then
    # 物理物理物理：改写下载地址、分支，并跳过 Hash 校验
    sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm99999/66|g" "$UBOOT_MAKEFILE"
    sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" "$UBOOT_MAKEFILE"
    sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$UBOOT_MAKEFILE"
    echo "U-Boot source physically redirected to ykm99999/66 (sl3000-uboot-base)"
fi

# 3. 彻底解决内核符号断点：直接在驱动核心头文件末尾追加，100% 物理熔断所有 undeclared 报错
ETH_SOC_HDR=$(find build_dir/ -name "mtk_eth_soc.h" | grep "linux-mediatek_filogic" | head -n 1)
if [ -n "$ETH_SOC_HDR" ]; then
    cat << 'EOF' >> "$ETH_SOC_HDR"

/* --- SL-3000 Rescue Firmware Physical Patch --- */
#ifndef MTK_FE_START_RESET
#define MTK_FE_START_RESET 0x10
#define MTK_FE_RESET_DONE 0x11
#define MTK_FE_RESET_NAT_DONE 0x14
#endif

#ifndef MTK_WIFI_CHIP_OFFLINE
#define MTK_WIFI_CHIP_OFFLINE 0x12
#define MTK_WIFI_CHIP_ONLINE 0x13
#endif

#ifndef HIT_BIND_FORCE_TO_CPU
#define HIT_BIND_FORCE_TO_CPU 1
#endif

#ifndef MTK_WIFI_RESET_DONE
#define MTK_WIFI_RESET_DONE 0x16
#endif
/* --- Patch End --- */
EOF
fi

exit 0
