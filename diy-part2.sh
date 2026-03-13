#!/bin/bash
# 物理修复脚本：硬化源码注入与路径校准

# 1. 物理修正 IP 与主机名
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# 2. 跨分支搬运硬化源码 (U-Boot/ATF)
echo "Physical Surgery: Fetching hardened sources from sl3000-clean-source..."
git clone -b sl3000-clean-source --depth 1 https://github.com/ykm888/66.git hardening_src

# 物理注入 ATF
mkdir -p package/boot/arm-trusted-firmware-mediatek/src
cp -rf hardening_src/atf/* package/boot/arm-trusted-firmware-mediatek/src/

# 物理注入 U-Boot
mkdir -p package/boot/uboot-mediatek/src
cp -rf hardening_src/u-boot/* package/boot/uboot-mediatek/src/

# 3. 影子包清场：卸载并物理删除 feeds 中的同名包，防止干扰
./scripts/feeds uninstall arm-trusted-firmware-mediatek uboot-mediatek
rm -rf package/feeds/mediatek/arm-trusted-firmware-mediatek
rm -rf package/feeds/mediatek/uboot-mediatek

# 4. 物理对齐 888 核心物理定义
[ -d ../888 ] && find target/linux/mediatek/ -type d -name "dts" -exec cp -f ../888/mt7981-sl-3000-emmc.dts {} \;
[ -f ../888/filogic.mk ] && cp -f ../888/filogic.mk target/linux/mediatek/image/

# 5. 抹除 Werror 警告 (防止 GCC 兼容性中断)
find package/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +

rm -rf hardening_src
echo "Physical Surgery: Completed."
