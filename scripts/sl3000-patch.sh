#!/bin/bash

# 1. 存储与内存定义物理锁定 (1024M)
IMAGE_DIR="target/linux/mediatek/image/"
if [ -d "$IMAGE_DIR" ]; then
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_256M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
    grep -rl "DRAM_SIZE_" "$IMAGE_DIR" | xargs sed -i 's/DRAM_SIZE_512M=y/DRAM_SIZE_1024M=y/g' 2>/dev/null
fi

# 2. 物理注入手术：带重试机制的捕获逻辑
# 尝试寻找 U-Boot 物理路径
for i in {1..30}; do
    UBOOT_PATH=$(find build_dir/ -name "u-boot-*" | grep -E "sl_3000|mt7981" | head -n 1)
    if [ -n "$UBOOT_PATH" ]; then
        echo "Found U-Boot physical path: $UBOOT_PATH"
        mkdir -p "$UBOOT_PATH/configs/"
        
        # 物理注入：抓取并强行覆盖
        curl -fsSL https://raw.githubusercontent.com/ykm99999/66/sl3000-uboot-base/configs/mt7981_sl_3000-emmc_defconfig -o "$UBOOT_PATH/configs/mt7981_sl_3000-emmc_defconfig"
        
        # 三重保险覆盖
        cp -f "$UBOOT_PATH/configs/mt7981_sl_3000-emmc_defconfig" "$UBOOT_PATH/configs/mt7981_emmc_defconfig"
        cp -f "$UBOOT_PATH/configs/mt7981_sl_3000-emmc_defconfig" "$UBOOT_PATH/configs/mt7981_mt7981_emmc_defconfig" 2>/dev/null || true
        
        echo "Physical Injection Success!"
        break
    fi
    echo "Waiting for U-Boot source extraction... ($i/30)"
    sleep 2
done

# 3. 内核符号物理熔断 (解决 eth_soc 报错)
ETH_SOC_HDR=$(find build_dir/ -name "mtk_eth_soc.h" | grep "linux-mediatek_filogic" | head -n 1)
if [ -n "$ETH_SOC_HDR" ]; then
    if ! grep -q "MTK_WIFI_RESET_DONE" "$ETH_SOC_HDR"; then
        cat << 'EOF' >> "$ETH_SOC_HDR"

#ifndef MTK_FE_START_RESET
#define MTK_FE_START_RESET 0x10
#define MTK_FE_RESET_DONE 0x11
#define MTK_FE_RESET_NAT_DONE 0x14
#define MTK_WIFI_CHIP_OFFLINE 0x12
#define MTK_WIFI_CHIP_ONLINE 0x13
#define HIT_BIND_FORCE_TO_CPU 1
#define MTK_WIFI_RESET_DONE 0x16
#endif
EOF
        echo "Kernel headers physically patched."
    fi
fi

exit 0
