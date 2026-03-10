#!/bin/bash

# 1. 物理复刻：创建索引目录
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/

# 2. 物理复刻：按照指定路径注入DTS与合成配置文件
cp -f ../custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/

# 3. 最小物理修补：对齐日志报错路径 (Linux 6.12.74)
mkdir -p target/linux/mediatek/files-6.12/arch/arm64/boot/dts/mediatek/
cp -f ../custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-6.12/arch/arm64/boot/dts/mediatek/

# 4. 物理锁死：U-Boot 救砖零件分支对齐
# 切除原有目录，物理拉取指定的 sl3000-uboot-base 分支
rm -rf package/boot/uboot-mediatek
git clone https://github.com/ykm888/66 -b sl3000-uboot-base package/boot/uboot-mediatek
