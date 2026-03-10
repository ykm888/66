#!/bin/bash

# 物理复刻：创建索引目录
mkdir -p target/linux/mediatek/dts/
mkdir -p target/linux/mediatek/image/

# 物理复刻：注入DTS与合成配置文件
cp -f ../custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/dts/
cp -f ../custom-config/filogic.mk target/linux/mediatek/image/

# 最小物理修补：对齐日志报错路径 (Linux 6.12.74)
mkdir -p target/linux/mediatek/files-6.12/arch/arm64/boot/dts/mediatek/
cp -f ../custom-config/mt7981-sl-3000-emmc.dts target/linux/mediatek/files-6.12/arch/arm64/boot/dts/mediatek/

# 物理复刻：清理原有uboot零件路径
rm -rf package/boot/uboot-mediatek
cp -rf ../custom-config/uboot-mediatek package/boot/
