#!/bin/bash

# 1. 物理目录复刻：构建目标架构索引环境（原文逻辑延续）
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 2. 物理注入配置：同步 DTS 和已经修复语法错误（Tab 缩进对齐）的 filogic.mk
# 确保 $GITHUB_WORKSPACE 路径下的 custom-config 文件夹内已有这两个文件
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f $GITHUB_WORKSPACE/custom-config/filogic.mk target/linux/mediatek/image/
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 3. 救砖零件仓库物理同步：延续上一版逻辑，强制使用 sl3000-uboot-base 分支
# 这是为了确保 Makefile 能物理产出 filogic.mk 需要的 fip.bin
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek

# 4. (可选) 物理修正：如果 ATF 仓库不在默认列表，可在此手动补齐
# rm -rf package/boot/arm-trusted-firmware-mediatek
# git clone https://github.com/ykm888/66 -b sl3000-atf-base package/boot/arm-trusted-firmware-mediatek
