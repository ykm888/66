#!/bin/bash
# SL-3000 物理硬化脚本 - 像素级对齐修复版

# 1. 物理环境初始化
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# 2. 跨分支物理搬运硬化零件
echo "Physical Surgery: Cloning hardening sources..."
git clone -b sl3000-clean-source --depth 1 https://github.com/ykm888/66.git hardening_src

# 3. 【核心修正】物理占位：先建立本地目录
mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

# 4. 物理抢救 Makefile 模具并强行本地化
# 只有拿到 Makefile，系统才会承认这个包存在，从而消除 Dependency Warning
if [ -d feeds/mediatek/arm-trusted-firmware-mediatek ]; then
    cp -rf feeds/mediatek/arm-trusted-firmware-mediatek/Makefile package/boot/arm-trusted-firmware-mediatek/
    # 物理篡改：切断远程下载，锁定本地编译
    sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=./g' package/boot/arm-trusted-firmware-mediatek/Makefile
fi

if [ -d feeds/mediatek/uboot-mediatek ]; then
    cp -rf feeds/mediatek/uboot-mediatek/Makefile package/boot/uboot-mediatek/
    sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=./g' package/boot/uboot-mediatek/Makefile
fi

# 5. 物理注入硬化源码
cp -rf hardening_src/atf/* package/boot/arm-trusted-firmware-mediatek/
cp -rf hardening_src/u-boot/* package/boot/uboot-mediatek/

# 6. 物理清场：卸载官方影子包
./scripts/feeds uninstall arm-trusted-firmware-mediatek uboot-mediatek

# 7. 物理注入 888 核心定义 (DTS/MK)
[ -d ../888 ] && find target/linux/mediatek/ -type d -name "dts" -exec cp -f ../888/mt7981-sl-3000-emmc.dts {} \;
[ -f ../888/filogic.mk ] && cp -f ../888/filogic.mk target/linux/mediatek/image/

# 8. 兼容性补丁：抹除 Werror
find package/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +

rm -rf hardening_src
echo "Physical Surgery: Completed successfully."
