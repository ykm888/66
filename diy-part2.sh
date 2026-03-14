#!/bin/bash

# 1. 物理对齐 ATF (1MB 偏移锁定)
ATF_PATH="package/boot/arm-trusted-firmware-mediatek/patches"
mkdir -p $ATF_PATH

# 使用 printf 精准物理注入，补全 diff 路径头并锁定换行符
printf -- "--- a/plat/mediatek/mt7981/include/platform_def.h\n+++ b/plat/mediatek/mt7981/include/platform_def.h\n@@ -15,7 +15,8 @@\n #define MTK_FIP_BASE\t\t(0x100000)\n #define MTK_FIP_MAX_SIZE\t(0x200000)\n" > $ATF_PATH/999-sl3000-physical-lock.patch

# 2. 物理注入救砖 DTS
DTS_DIR="package/boot/uboot-mediatek/files/arch/arm/dts"
mkdir -p $DTS_DIR

# 禁用 EOF，改用字节流注入完整 DTS 定义
printf "/dts-v1/;\n#include \"mt7981.dtsi\"\n/ {\n  model = \"SL-3000 (ykm888 Hardened)\";\n  compatible = \"mediatek,mt7981-sl3000\", \"mediatek,mt7981\";\n  memory@40000000 {\n    device_type = \"memory\";\n    reg = <0x40000000 0x20000000>;\n  };\n  chosen { stdout-path = &uart0; };\n};\n&uart0 { status = \"okay\"; };\n&mmc0 { status = \"okay\"; bus-width = <8>; cap-mmc-highspeed; non-removable; };\n&spi0 { status = \"okay\"; };\n" > $DTS_DIR/mt7981-sl3000.dts

# 3. 物理锁定设备树 (准则 1 原文照抄)
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile
