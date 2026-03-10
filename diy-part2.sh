#!/bin/bash

# 1. 物理目录复刻：创建目标架构索引目录
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/

# 2. 绝对路径物理注入：使用 $GITHUB_WORKSPACE 引用主仓库配置
# 物理同步你刚刚保存好的 filogic.mk
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f $GITHUB_WORKSPACE/custom-config/filogic.mk target/linux/mediatek/image/

# 3. 5.15 内核物理路径锁死：确保编译现场 DTS 命中（严禁偏移到 6.12）
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 4. 救砖零件仓库物理同步：切换至最新的 sl3000-uboot-base 分支
# 注意：此仓库内包含我们刚刚修复的 Makefile
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek

# 5. 修正：确保 arm-trusted-firmware-mediatek 文件夹物理存在
# 如果你的 uboot-base 分支里没包含 TFA，这里可以手动补齐路径
# rm -rf package/boot/arm-trusted-firmware-mediatek
# git clone https://github.com/ykm888/atf-link -b main package/boot/arm-trusted-firmware-mediatek
