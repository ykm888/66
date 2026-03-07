#!/bin/bash

UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

# 1. 物理破除内核 1024M 识别限制
sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh

# 2. 修改默认主机名为 SL3000
sed -i 's/OpenWrt/SL3000/g' openwrt/package/base-files/files/bin/config_generate

# 3. 物理构建救砖 U-Boot
echo ">>> 正在构建基于全环境分支的 1024M U-Boot..."
git clone --depth 1 -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src

# 物理对齐：指定交叉编译器 aarch64-linux-gnu-
# 只有这样编译器才能理解 armv8-a 指令集
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- mt7981_emmc_defconfig
make ARCH=arm CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc) || exit 1

if [ -f "u-boot.bin" ]; then
    cp u-boot.bin ../sl3000-uboot.bin
    echo "✅ U-Boot 救砖引导编译成功"
else
    # 针对不同源码可能的产物名检查
    [ -f "u-boot-mtk.bin" ] && cp u-boot-mtk.bin ../sl3000-uboot.bin && echo "✅ U-Boot 编译成功" || exit 1
fi
cd ..

echo "✅ 救砖全家桶第 2 版补丁执行完毕！"
