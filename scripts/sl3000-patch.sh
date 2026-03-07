#!/bin/bash

UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

echo ">>> [物理启动] SL-3000 1024M 补丁执行中..."

# 1. 物理破除 OpenWrt 内核 1024M 识别限制
if [ -f "openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh" ]; then
    sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
    echo "✅ 内核 1024M 补丁注入成功"
fi

# 2. 物理彻底切除冲突驱动源码 (防扫描报错)
# 即使 Config 禁用了，删除文件夹能防止 Makefile 扫描时的幽灵依赖报错
echo ">>> 正在执行物理手术：剔除不兼容驱动源码..."
rm -rf openwrt/package/mtk/drivers/warp
rm -rf openwrt/package/mtk/drivers/files_t7981

# 3. 物理初始化编译环境
echo ">>> 正在安装交叉工具链..."
sudo apt-get update -qq && sudo apt-get install -y -qq gcc-aarch64-linux-gnu build-essential flex bison bc python3-dev

# 4. 物理构建救砖 U-Boot
echo ">>> 正在构建 1024M U-Boot, 分支: $UBOOT_BRANCH"
rm -rf uboot-src
git clone --depth 1 -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src

export ARCH=arm
export CROSS_COMPILE=aarch64-linux-gnu-

make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mt7981_emmc_defconfig
# 物理锁定 U-Boot 的 1024M 内存 Bank
sed -i 's/CONFIG_NR_DRAM_BANKS=.*/CONFIG_NR_DRAM_BANKS=1/g' .config
echo "CONFIG_NR_DRAM_BANKS=1" >> .config

make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) || exit 1

# 5. 产物提取
if [ -f "u-boot.bin" ]; then
    cp u-boot.bin ../sl3000-uboot.bin
elif [ -f "u-boot-mtk.bin" ]; then
    cp u-boot-mtk.bin ../sl3000-uboot.bin
fi
cd ..

echo "✅ 补丁脚本物理执行完毕！"
