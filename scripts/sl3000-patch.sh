#!/bin/bash

UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

# 1. 物理破除内核 1024M 识别限制
sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh

# 2. 修改默认主机名
sed -i 's/OpenWrt/SL3000/g' openwrt/package/base-files/files/bin/config_generate

# 3. 物理构建救砖 U-Boot (原文照抄你的源)
git clone --depth 1 --single-branch -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src
make mt7981_sl3000_defconfig
make -j$(nproc)

if [ -f "u-boot.bin" ]; then
    cp u-boot.bin ../sl3000-uboot.bin
    echo "✅ U-Boot 救砖引导编译成功"
fi
cd ..

echo "✅ 救砖全家桶补丁应用成功！"
