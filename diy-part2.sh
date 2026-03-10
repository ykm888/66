#!/bin/bash

# 1. 物理复刻：创建索引目录
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/

# 2. 物理复刻：注入DTS与合成配置文件
cp -f ../custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/

# 3. 最小物理修补：锁死 5.15 内核路径（严禁 6.12）
mkdir -p target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/
cp -f ../custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-5.15/arch/arm64/boot/dts/mediatek/

# 4. 物理锁死：零件仓库替换逻辑
# 零件仓库地址：https://github.com/ykm888/66 分支：sl3000-uboot-base
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek
