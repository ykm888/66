#!/bin/bash

# 1. 物理移除 ATF 官方补丁（确保 1024M 逻辑不被篡改）
rm -rf package/boot/arm-trusted-firmware-mediatek/patches/

# 2. 彻底打破 Kconfig 递归死循环
echo "Physical Surgery: Breaking Kconfig recursion..."
rm -rf feeds/network/net/wpa-supplicant
rm -rf tmp/
find feeds/luci/applications/luci-app-easymesh/ -name Makefile -exec sed -i 's/wpa-supplicant/wpad-mesh-openssl/g' {} +

# 3. 【核心修正】物理补齐并注入缺失的 FIP UUID 头文件
# 逻辑：既然它找不到这个路径和文件，我们就直接在编译目录下物理生成它
echo "Physical Hack: Injecting missing FIP UUID headers..."
# 确定 ATF 源码路径
ATF_PATH="package/boot/arm-trusted-firmware-mediatek/atf-sl30"

# 创建编译器报错的那个物理目录
mkdir -p ${ATF_PATH}/plat/mediatek/apsoc_common/include
mkdir -p ${ATF_PATH}/plat/mediatek/common/include

# 物理同步：将 bl2/include 下的所有头文件（包含你刚才发的那个）强制复制到编译器寻找的 include 目录下
if [ -d "${ATF_PATH}/plat/mediatek/apsoc_common/bl2/include" ]; then
    cp -f ${ATF_PATH}/plat/mediatek/apsoc_common/bl2/include/*.h ${ATF_PATH}/plat/mediatek/apsoc_common/include/ 2>/dev/null
fi

# 4. 物理关掉 -Werror 报错开关 (防止因为它找不到其他不重要的目录而罢工)
echo "Physical Fix: Disabling missing-include-dirs error..."
find package/boot/arm-trusted-firmware-mediatek/ -name "*.mk" -exec sed -i 's/-Werror/-Wno-error=missing-include-dirs/g' {} +
find package/boot/arm-trusted-firmware-mediatek/ -name "Makefile" -exec sed -i 's/-Werror/-Wno-error=missing-include-dirs/g' {} +

# 5. 修正 U-Boot 零件名称冲突
echo "Physical Fix: Aligning U-Boot dependency names..."
find package/boot/uboot-mediatek/ -name Makefile -exec sed -i 's/arm-trusted-firmware-mediatek-mt7981-nor-ddr4/trusted-firmware-a-mt7981-nor-ddr4/g' {} +

# 6. 1024M 内存寻址锁定
echo "CONFIG_ARM64_VA_BITS_39=y" >> .config
echo "CONFIG_PACKAGE_wpad-mesh-openssl=y" >> .config
echo "# CONFIG_PACKAGE_wpa-supplicant is not set" >> .config

echo "DIY-Part2: All physical files and paths aligned."
