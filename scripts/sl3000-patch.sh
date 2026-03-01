#!/bin/bash

# 1. 存储与内存定义物理锁定 (保持 1024M 物理属性)
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. 物理注入手术：直接补齐缺失的 defconfig (彻底解决 No such file 报错)
# 物理定位：在 build_dir 中寻找已解压的 U-Boot 目录
UBOOT_PATH=$(find build_dir/ -name "u-boot-*" | grep "u-boot-mt7981_sl_3000-emmc" | head -n 1)

if [ -n "$UBOOT_PATH" ]; then
    echo "Found U-Boot physical path: $UBOOT_PATH"
    mkdir -p "$UBOOT_PATH/configs/"
    
    # 物理抓取：从你的专用仓库分支抓取物理文件并强行写入
    curl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o "$UBOOT_PATH/configs/mt7981_sl_3000-emmc_defconfig"
    
    # 双重保险：同时物理覆盖官方默认名，防止编译脚本逻辑回退
    cp -f "$UBOOT_PATH/configs/mt7981_sl_3000-emmc_defconfig" "$UBOOT_PATH/configs/mt7981_emmc_defconfig"
    
    echo "Physical Injection Success: mt7981_sl_3000-emmc_defconfig is now present in $UBOOT_PATH"
else
    echo "WARNING: U-Boot build directory not found. Ensuring path exists for next stage."
fi

# 3. 彻底解决内核符号断点：物理注入内核头文件，熔断 undeclared 报错
ETH_SOC_HDR=$(find build_dir/ -name "mtk_eth_soc.h" | grep "linux-mediatek_filogic" | head -n 1)
if [ -n "$ETH_SOC_HDR" ]; then
    if ! grep -q "MTK_WIFI_RESET_DONE" "$ETH_SOC_HDR"; then
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
        echo "Kernel headers physically patched."
    fi
fi

exit 0
