#!/bin/bash

# 1. 物理复刻：创建目标索引目录
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/

# 2. 绝对路径物理注入：使用 $GITHUB_WORKSPACE 定位主仓库配置
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f $GITHUB_WORKSPACE/custom-config/filogic.mk target/linux/mediatek/image/

# 3. 5.15 内核路径锁死：物理注入 DTS 到内核源码现场（严禁 6.12）
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 4. 救砖零件仓库同步：物理替换为 sl3000-uboot-base 分支
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek
