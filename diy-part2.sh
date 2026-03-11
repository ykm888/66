#!/bin/bash
#
# Copyright (c) 2023-2026 Gemini AI & User Collaboration
# Description: Ultimate Physical Fix for SL-3000 (MT7981) 1024M DDR4 + eMMC
#

# 1. 物理移除 ATF 官方补丁（双保险）
rm -rf package/boot/arm-trusted-firmware-mediatek/patches/

# 2. 彻底切断 Kconfig 递归循环 (终极手术版)
# 逻辑：除了删除源码，还要删除 tmp 缓存，并强制修改 Luci-app-easymesh 的依赖定义
echo "Physical Surgery: Breaking Kconfig recursion by force..."
# 删除冲突源码
rm -rf feeds/network/net/wpa-supplicant
# 关键：删除编译缓存索引，防止 defconfig 读取旧的依赖树
rm -rf tmp/

# 强制手术：修改 easymesh 的 Makefile，将其依赖从 wpa-supplicant 强行改为 wpad
# 这样 Kconfig 就不会再去找 wpa-supplicant 了
find feeds/luci/applications/luci-app-easymesh/ -name Makefile -exec sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' {} +

# 3. 物理修正 U-Boot 零件依赖名称
echo "Physical Fix: Aligning U-Boot dependency names..."
find package/boot/uboot-mediatek/ -name Makefile -exec sed -i 's/arm-trusted-firmware-mediatek-mt7981-nor-ddr4/trusted-firmware-a-mt7981-nor-ddr4/g' {} +

# 4. 强制锁定内核 1024M 寻址补丁
echo "Physical Fix: Locking Kernel 1024MB address space..."
echo "CONFIG_ARM64_VA_BITS_39=y" >> .config

# 5. 物理锁定无线包选择，并在 .config 中物理剔除 wpa-supplicant
sed -i '/CONFIG_PACKAGE_wpa-supplicant/d' .config
sed -i '/CONFIG_PACKAGE_wpad/d' .config
echo "CONFIG_PACKAGE_wpad-mesh-openssl=y" >> .config
echo "# CONFIG_PACKAGE_wpa-supplicant is not set" >> .config

echo "DIY-Part2: All physical fixes applied. Kconfig cache cleared."
