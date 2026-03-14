#!/bin/bash

# --- 1. 物理修改 ATF (1MB 偏移锁定) ---
# 目标文件路径
ATF_FILE="package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/include/platform_def.h"

# 溯源：如果文件存在，则直接用 sed 物理替换地址定义
if [ -f "$ATF_FILE" ]; then
    sed -i 's/#define MTK_FIP_BASE.*/#define MTK_FIP_BASE (0x100000)/' "$ATF_FILE"
    sed -i 's/#define MTK_FIP_MAX_SIZE.*/#define MTK_FIP_MAX_SIZE (0x200000)/' "$ATF_FILE"
fi

# --- 2. 物理注入救砖 DTS ---
DTS_DIR="package/boot/uboot-mediatek/files/arch/arm/dts"
mkdir -p $DTS_DIR

# 使用 cat 配合转义，物理写入 DTS 内容
cat << 'EOF' > $DTS_DIR/mt7981-sl3000.dts
/dts-v1/;
#include "mt7981.dtsi"
/ {
  model = "SL-3000 (ykm888 Hardened)";
  compatible = "mediatek,mt7981-sl3000", "mediatek,mt7981";
  memory@40000000 {
    device_type = "memory";
    reg = <0x40000000 0x20000000>;
  };
  chosen { stdout-path = &uart0; };
};
&uart0 { status = "okay"; };
&mmc0 { status = "okay"; bus-width = <8>; cap-mmc-highspeed; non-removable; };
&spi0 { status = "okay"; };
EOF

# --- 3. 物理锁定设备树 (准则 1 原文照抄) ---
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile
