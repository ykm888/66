#!/bin/bash

# 1. 物理复刻：创建索引目录
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/

# 2. 最小物理修补：使用环境变量准确定位配置文件路径
# 确保无论在哪个目录下运行，都能物理命中主仓库中的文件
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f $GITHUB_WORKSPACE/custom-config/filogic.mk target/linux/mediatek/image/

# 3. 物理锁死：5.15 内核路径对齐
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/
cp -f $GITHUB_WORKSPACE/custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 4. 物理锁死：救砖全家桶零件源对齐
# 零件仓库地址：https://github.com/ykm888/66 分支：sl3000-uboot-base
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek
