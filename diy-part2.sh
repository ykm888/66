#!/bin/bash

# 1. 物理对齐 ATF (1MB 偏移锁定)
ATF_PATH="package/boot/arm-trusted-firmware-mediatek/patches"
mkdir -p $ATF_PATH
cat <<EOF > $ATF_PATH/999-sl3000-physical-lock.patch
--- a/plat/mediatek/mt7981/include/platform_def.h
+++ b/plat/mediatek/mt7981/include/platform_def.h
@@ -15,7 +15,8 @@
 #define MTK_FIP_BASE		(0x100000)
 #define MTK_FIP_MAX_SIZE	(0x200000)
EOF

# 2. 物理注入救砖 DTS
DTS_DIR="package/boot/uboot-mediatek/files/arch/arm/dts"
mkdir -p $DTS_DIR
cat <<EOF > $DTS_DIR/mt7981-sl3000.dts
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

# 3. 修改编译配置文件
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile
