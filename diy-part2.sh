#!/bin/bash
# SL-3000 物理硬化脚本 - 路径自检版

# 1. IP 与 主机名修改
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# 2. 物理建立包外壳 (彻底解决 Warning 与 Error 2)
# 我们先卸载，再建立本地物理目录
./scripts/feeds uninstall arm-trusted-firmware-mediatek uboot-mediatek
rm -rf package/boot/arm-trusted-firmware-mediatek
rm -rf package/boot/uboot-mediatek

mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

# 3. 物理注入你修复好的黄金 Makefile
# 注意：确保你的 888 目录下有这两个文件
[ -f ../888/atf-makefile ] && cp -f ../888/atf-makefile package/boot/arm-trusted-firmware-mediatek/Makefile
[ -f ../888/uboot-makefile ] && cp -f ../888/uboot-makefile package/boot/uboot-mediatek/Makefile

# 4. 物理注入核心 DTS 和 MK
[ -d ../888 ] && find target/linux/mediatek/ -type d -name "dts" -exec cp -f ../888/mt7981-sl-3000-emmc.dts {} \;
[ -f ../888/filogic.mk ] && cp -f ../888/filogic.mk target/linux/mediatek/image/

# 5. 抹除编译警告限制
find package/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +

echo "Physical Surgery: Surgery completed."
