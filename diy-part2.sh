#!/bin/bash
#
# Copyright (c) 2023-2026 Gemini AI & User Collaboration
# Description: Physical Fixes for SL-3000 (MT7981) 1024M DDR4 + eMMC Edition
#

# 1. 物理移除 ATF 官方补丁（双保险，防止编译系统从其他缓存中恢复补丁）
# 注意：你已在源头删除，此处作为编译环境的最后一道防线
rm -rf package/boot/arm-trusted-firmware-mediatek/patches/

# 2. 深度手术：彻底切断 Kconfig 递归依赖死循环 (Recursive Dependency)
# 现象：luci-app-easymesh 强制关联 wpa-supplicant 导致与 wpad 冲突
# 修复：直接从 feeds 中物理删除 wpa-supplicant 源码，迫使系统使用 wpad
echo "Physical Surgery: Breaking Kconfig recursion by removing wpa-supplicant..."
rm -rf feeds/network/net/wpa-supplicant

# 3. 物理修正 U-Boot 零件依赖名称 (解决 "which does not exist" 报错)
# 现象：U-Boot Makefile 寻找的 ATF 零件旧名与当前仓库实际包名不符
# 修复：将 Makefile 中的旧名字强制替换为当前系统识别的新名字
echo "Physical Fix: Aligning U-Boot dependency names..."
find package/boot/uboot-mediatek/ -name Makefile -exec sed -i 's/arm-trusted-firmware-mediatek-mt7981-nor-ddr4/trusted-firmware-a-mt7981-nor-ddr4/g' {} +

# 4. 强制锁定内核 1024M 寻址补丁
# 现象：默认内核配置可能只支持 512M，导致 1G 内存无法完全识别
# 修复：在配置末尾追加 39位虚拟地址支持，物理对齐 1GB 内存空间
echo "Physical Fix: Locking Kernel 1024MB address space..."
echo "CONFIG_ARM64_VA_BITS_39=y" >> .config

# 5. 物理拦截：确保没有重复的无线驱动配置冲突
sed -i '/CONFIG_PACKAGE_wpa-supplicant/d' .config
echo "CONFIG_PACKAGE_wpad-mesh-openssl=y" >> .config

echo "DIY-Part2: All physical fixes applied for SL-3000 1024M DDR4 Edition."
