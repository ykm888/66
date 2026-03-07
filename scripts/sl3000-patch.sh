#!/bin/bash

UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

# 1. 物理破除内核 1024M 识别限制
if [ -f "openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh" ]; then
    sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
fi

# 2. 物理彻底切除冲突驱动源码
rm -rf openwrt/package/mtk/drivers/warp
rm -rf openwrt/package/mtk/drivers/files_t7981

# 3. 物理初始化编译环境并构建 U-Boot
sudo apt-get update -qq && sudo apt-get install -y -qq gcc-aarch64-linux-gnu build-essential flex bison bc python3-dev
git clone --depth 1 -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src
export ARCH=arm
export CROSS_COMPILE=aarch64-linux-gnu-

make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mt7981_emmc_defconfig
# 物理注入 1024M 内存 Bank 识别
sed -i 's/CONFIG_NR_DRAM_BANKS=.*/CONFIG_NR_DRAM_BANKS=1/g' .config
echo "CONFIG_NR_DRAM_BANKS=1" >> .config

make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) || exit 1

# 4. 提取救砖引导
[ -f "u-boot.bin" ] && cp u-boot.bin ../sl3000-uboot.bin || cp u-boot-mtk.bin ../sl3000-uboot.bin
cd ..
