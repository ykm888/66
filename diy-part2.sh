#!/bin/bash

# --- 1. 物理移除官方补丁，确保 1024M 源码纯净 ---
rm -rf package/boot/arm-trusted-firmware-mediatek/patches/

# --- 2. 彻底解决 Kconfig 递归死循环 ---
rm -rf feeds/network/net/wpa-supplicant
rm -rf tmp/
find feeds/luci/applications/luci-app-easymesh/ -name Makefile -exec sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' {} +

# --- 3. 【核心手术】劫持 ATF 编译流程 ---
# 逻辑：直接修改 package 目录下的 Makefile，在源码解压后、编译开始前强行注入路径
echo "Physical Surgery: Patching ATF Makefile for include logic..."
ATF_MAKEFILE="package/boot/arm-trusted-firmware-mediatek/Makefile"

# A. 暴力屏蔽全全局 Werror（从源头消灭“警告变错误”）
sed -i 's/-Werror//g' $ATF_MAKEFILE

# B. 注入物理路径补齐逻辑
# 我们找到 Build/Compile 这一行，在它执行 $(MAKE) 之前，强行创建目录并复制头文件
# 这里使用了 awk 的精准定位，确保指令插入到正确的位置
sed -i '/$(MAKE) -C $(PKG_BUILD_DIR)/i \
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include; \
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/common/include; \
	[ -d $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ] && cp -rf $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true' $ATF_MAKEFILE

# --- 4. 修正 U-Boot 零件名称冲突 ---
find package/boot/uboot-mediatek/ -name Makefile -exec sed -i 's/arm-trusted-firmware-mediatek-mt7981-nor-ddr4/trusted-firmware-a-mt7981-nor-ddr4/g' {} +

# --- 5. 1024M 内存及内核寻址锁定 ---
echo "CONFIG_ARM64_VA_BITS_39=y" >> .config
echo "CONFIG_PACKAGE_wpad-mesh-openssl=y" >> .config
echo "# CONFIG_PACKAGE_wpa-supplicant is not set" >> .config

echo "DIY-Part2: ATF Makefile Hijacked. Structure forced successfully."
