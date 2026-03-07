#!/bin/bash

UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

# 1. 物理破除内核 1024M 识别限制
sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh

# 2. 修改默认主机名为 SL3000
sed -i 's/OpenWrt/SL3000/g' openwrt/package/base-files/files/bin/config_generate

# 3. 彻底解决：物理强制安装交叉编译工具链
echo ">>> 正在执行物理环境强插 (解决 aarch64-linux-gnu-gcc not found)..."
sudo apt-get update -qq
sudo apt-get install -y -qq gcc-aarch64-linux-gnu build-essential flex bison

# 4. 物理构建救砖 U-Boot
echo ">>> 正在构建基于全环境分支的 1024M U-Boot..."
git clone --depth 1 -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src

# 显式指定编译器路径并启动物理编译
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm

echo ">>> 开始物理解析 Kconfig 并生成配置..."
make $CROSS_COMPILE $ARCH mt7981_emmc_defconfig || exit 1

echo ">>> 物理启动多核编译 (这一步耗时约 1-3 分钟)..."
make $CROSS_COMPILE $ARCH -j$(nproc) || exit 1

if [ -f "u-boot.bin" ]; then
    cp u-boot.bin ../sl3000-uboot.bin
    echo "✅ U-Boot 救砖引导编译成功 (u-boot.bin)"
elif [ -f "u-boot-mtk.bin" ]; then
    cp u-boot-mtk.bin ../sl3000-uboot.bin
    echo "✅ U-Boot 救砖引导编译成功 (u-boot-mtk.bin)"
else
    echo "❌ 错误：未找到编译产物"
    exit 1
fi

cd ..
echo "✅ 救砖全家桶第 4 版物理补丁全部执行完毕！"
