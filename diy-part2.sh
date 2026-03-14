#!/bin/bash
# ==========================================
# SL-3000 救砖零件物理注入脚本
# ==========================================#!/bin/bash
# ==========================================
# SL-3000 救砖零件物理注入脚本
# ==========================================

# 1. 物理对齐 ATF (1MB 偏移锁定)
# 确保生成的 BL2 能够物理跳转到 1MB 处的 FIP
ATF_PATH="package/boot/arm-trusted-firmware-mediatek/patches"
mkdir -p $ATF_PATH
cat <<EOF > $ATF_PATH/999-sl3000-physical-lock.patch
--- a/plat/mediatek/mt7981/include/platform_def.h
+++ b/plat/mediatek/mt7981/include/platform_def.h
@@ -15,7 +15,8 @@
 #define MTK_FIP_BASE		(0x100000)
 #define MTK_FIP_MAX_SIZE	(0x200000)
EOF
name: SL-3000 Build Unbrick Full-Kit

on:
  workflow_dispatch:

env:
  REPO_URL: https://github.com/immortalwrt/immortalwrt
  REPO_BRANCH: openwrt-23.05
  FEEDS_CONF: feeds.conf.default
  CONFIG_FILE: .config
  DIY_P2_SH: diy-part2.sh

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout
      uses: actions/checkout@v4

    - name: Initialization Environment
      run: |
        sudo apt-get update
        sudo apt-get install -y build-essential libncurses5-dev gawk git gettext libssl-dev xsltproc wget unzip qemu-utils
        sudo timedatectl set-timezone "Asia/Shanghai"

    - name: Clone Source & Load DIY
      run: |
        git clone --depth 1 $REPO_URL -b $REPO_BRANCH openwrt
        cp $DIY_P2_SH openwrt/

    - name: Update & Install Feeds
      working-directory: ./openwrt
      run: |
        ./scripts/feeds update -a
        ./scripts/feeds install -a

    - name: Physical Hardening (Injection)
      working-directory: ./openwrt
      run: |
        # 强制注入救砖 .config 核心项
        echo "CONFIG_TARGET_mediatek=y" > .config
        echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
        echo "CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y" >> .config
        echo "CONFIG_PACKAGE_kmod-mt7981-firmware=y" >> .config
        
        chmod +x $DIY_P2_SH
        ./$DIY_P2_SH
        make defconfig

    - name: Compile Unbrick Kit
      working-directory: ./openwrt
      run: |
        # 优先编译救砖核心：ATF 与 U-Boot
        make package/boot/arm-trusted-firmware-mediatek/compile V=s -j$(nproc)
        make package/boot/uboot-mediatek/compile V=s -j$(nproc)
        # 编译完整镜像
        make -j$(nproc) || make -j1 V=s

    - name: Upload Unbrick Kit
      uses: actions/upload-artifact@v4
      with:
        name: SL3000-Unbrick-Full-Kit
        path: |
          openwrt/bin/targets/mediatek/filogic/*nor-programmer-dump.bin
          openwrt/bin/targets/mediatek/filogic/*.fip
          openwrt/bin/targets/mediatek/filogic/*.bin

# 2. 物理注入救砖 DTS
# 强制覆盖官方目录，确保 U-Boot 编译时使用 512MB 定义
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

# 3. 修改编译配置文件，锁定默认设备树
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile

# 1. 物理对齐 ATF (1MB 偏移锁定)
# 确保生成的 BL2 能够物理跳转到 1MB 处的 FIP
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
# 强制覆盖官方目录，确保 U-Boot 编译时使用 512MB 定义
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

# 3. 修改编译配置文件，锁定默认设备树
sed -i 's/CONFIG_DEFAULT_DEVICE_TREE=.*/CONFIG_DEFAULT_DEVICE_TREE="mt7981-sl3000"/' package/boot/uboot-mediatek/Makefile
