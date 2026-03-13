#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修复 7 版：定义水源，确保依赖修正逻辑延迟触发
#

# --- 1. 物理环境强力清场 ---
# 移除 bootstrap 分支中过时或冲突的引导包路径，确保物理路径唯一性
rm -rf package/boot/arm-trusted-firmware-mediatek
rm -rf package/boot/uboot-mediatek

# --- 2. 物理跨分支搬运 (从军火库 sl3000-clean-source 提取图纸) ---
# 克隆源码分支到临时目录。这一步彻底解决 Error 2，因为它提供了 Rule/Makefile
git clone -b sl3000-clean-source https://github.com/ykm888/66.git /tmp/source_repo

# 物理就位：创建路径并将零件平铺到 OpenWrt 构建目录
mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

cp -fR /tmp/source_repo/atf/* package/boot/arm-trusted-firmware-mediatek/
cp -fR /tmp/source_repo/u-boot/* package/boot/uboot-mediatek/

# --- 3. 物理心脏移植 (从 main/888 注入硬化驱动) ---
# 强制覆盖军火库的基础源码，确保 1MB (0x100000) 偏移逻辑生效
if [ -f "888/bl2_dev_spi_nor.c" ]; then
    # 路径对齐：将其放入 ATF 的硬件抽象层目录
    cp -f 888/bl2_dev_spi_nor.c package/boot/arm-trusted-firmware-mediatek/src/plat/mediatek/mt7981/bl2_dev_spi_nor.c
fi

# --- 4. 物理地图与合成宏覆盖 (从 main/888) ---
# 覆盖设备树：锁定 eMMC 45 组引脚与分区表
cp -f 888/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
# 覆盖生成脚本：决定最终 bin 文件的缝合逻辑
cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk

# --- 5. 1MB 物理边界强制校准 ---
# 像素级修正 filogic.mk 里的物理偏移参数，双重保险
sed -i 's/pad-to 512k/pad-to 1024k/g' target/linux/mediatek/image/filogic.mk
sed -i 's/seek=512/seek=1024/g' target/linux/mediatek/image/filogic.mk

# --- 6. 激活物理索引并清理 ---
rm -rf /tmp/source_repo
./scripts/feeds update -i
./scripts/feeds install -a
