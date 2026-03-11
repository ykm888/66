#!/bin/bash

# 1. 物理移除 ATF 官方补丁
rm -rf package/boot/arm-trusted-firmware-mediatek/patches/

# 2. 彻底打破 Kconfig 递归死循环
echo "Physical Surgery: Breaking Kconfig recursion..."
# 删除冲突源
rm -rf feeds/network/net/wpa-supplicant
# 强制将所有 feeds 里的 wpa-supplicant 引用替换为 wpad
find feeds/ -name Makefile -exec sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' {} +

# 3. 劫持 ATF Makefile (解决 cc1 路径报错)
echo "Physical Surgery: Patching ATF Makefile for include paths..."
ATF_MAKEFILE="package/boot/arm-trusted-firmware-mediatek/Makefile"

if [ -f "$ATF_MAKEFILE" ]; then
    # 物理抹除 -Werror 标志
    sed -i 's/-Werror//g' $ATF_MAKEFILE
    
    # 在编译指令执行前，注入 mkdir 和 cp 指令
    # 注意：这里的 $(PKG_BUILD_DIR) 是 Makefile 的变量，不是 shell 变量，不要加反斜杠
    sed -i '/$(MAKE) -C $(PKG_BUILD_DIR)/i \
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include; \
	mkdir -p $(PKG_BUILD_DIR)/plat/mediatek/common/include; \
	[ -d $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include ] && cp -rf $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/bl2/include/*.h $(PKG_BUILD_DIR)/plat/mediatek/apsoc_common/include/ || true' $ATF_MAKEFILE
fi

# 4. 修正 U-Boot 零件名称冲突
echo "Physical Fix: Aligning U-Boot dependency names..."
find package/boot/uboot-mediatek/ -name Makefile -exec sed -i 's/arm-trusted-firmware-mediatek-mt7981-nor-ddr4/trusted-firmware-a-mt7981-nor-ddr4/g' {} +

# 5. 1024M 内存及内核物理寻址锁定
echo "Physical Fix: Locking 1024M Address Space..."
echo "CONFIG_ARM64_VA_BITS_39=y" >> .config
sed -i '/CONFIG_PACKAGE_wpa-supplicant/d' .config
echo "CONFIG_PACKAGE_wpad-mesh-openssl=y" >> .config

echo "DIY-Part2: Full physical fixes deployed."
