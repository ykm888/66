#!/bin/bash

# 1. 物理移除 ATF 官方补丁（你已手动删除，此处为绝对物理防线）
rm -rf package/boot/arm-trusted-firmware-mediatek/patches/

# 2. 彻底打破 Kconfig 递归死循环 (终极暴力法)
echo "Physical Surgery: Breaking Kconfig recursion..."
# 删除冲突源
rm -rf feeds/network/net/wpa-supplicant
# 强制将所有 feeds 里的 wpa-supplicant 引用替换为 wpad，物理切断依赖链
find feeds/ -name Makefile -exec sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' {} +

# 3. 劫持 ATF Makefile 物理路径 (解决 cc1 报错)
echo "Physical Surgery: Patching ATF Makefile for include paths..."
ATF_MAKEFILE="package/boot/arm-trusted-firmware-mediatek/Makefile"

if [ -f "$ATF_MAKEFILE" ]; then
    # 物理抹除 -Werror 标志，防止警告导致中断
    sed -i 's/-Werror//g' $ATF_MAKEFILE
    
    # 在编译指令执行前，注入 mkdir 和 cp 指令，物理补齐 apsoc_common/include
    # 确保 plat_def_fip_uuid.h 就在编译器嘴边
    sed -i '/$(MAKE) -C $(PKG_BUILD_DIR)/i \
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include; \
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/common/include; \
	[ -d $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ] && cp -rf $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true' $ATF_MAKEFILE
fi

# 4. 修正 U-Boot 零件名称冲突 (解决 which does not exist)
echo "Physical Fix: Aligning U-Boot dependency names..."
find package/boot/uboot-mediatek/ -name Makefile -exec sed -i 's/arm-trusted-firmware-mediatek-mt7981-nor-ddr4/trusted-firmware-a-mt7981-nor-ddr4/g' {} +

# 5. 1024M 内存及内核物理寻址锁定
echo "Physical Fix: Locking 1024M Address Space..."
echo "CONFIG_ARM64_VA_BITS_39=y" >> .config
# 物理确保无线配置不回滚
sed -i '/CONFIG_PACKAGE_wpa-supplicant/d' .config
echo "CONFIG_PACKAGE_wpad-mesh-openssl=y" >> .config

echo "DIY-Part2: Full physical fixes deployed."
