#!/bin/bash
# SL-3000 物理硬化脚本 - 最终物理补丁

# 1. 物理环境初始化
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# 2. 跨分支搬运硬化源码 (sl3000-clean-source)
echo "Physical Surgery: Cloning hardening sources..."
git clone -b sl3000-clean-source --depth 1 https://github.com/ykm888/66.git hardening_src

# 3. 物理建立包外壳 (预防 Dependency Error)
mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

# 4. 抢救并本地化 Makefile
# 这步确保了虽然源码换成你的，但编译体系依然认这两个包
if [ -d feeds/mediatek/arm-trusted-firmware-mediatek ]; then
    cp -rf feeds/mediatek/arm-trusted-firmware-mediatek/Makefile package/boot/arm-trusted-firmware-mediatek/
    sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=./g' package/boot/arm-trusted-firmware-mediatek/Makefile
fi

if [ -d feeds/mediatek/uboot-mediatek ]; then
    cp -rf feeds/mediatek/uboot-mediatek/Makefile package/boot/uboot-mediatek/
    sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=./g' package/boot/uboot-mediatek/Makefile
fi

# 5. 注入物理源码到包内部
cp -rf hardening_src/atf/* package/boot/arm-trusted-firmware-mediatek/
cp -rf hardening_src/u-boot/* package/boot/uboot-mediatek/

# 6. 物理清场
./scripts/feeds uninstall arm-trusted-firmware-mediatek uboot-mediatek

# 7. 注入 888 核心物理定义
[ -d ../888 ] && find target/linux/mediatek/ -type d -name "dts" -exec cp -f ../888/mt7981-sl-3000-emmc.dts {} \;
[ -f ../888/filogic.mk ] && cp -f ../888/filogic.mk target/linux/mediatek/image/

# 8. 兼容性补丁
find package/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +

rm -rf hardening_src
echo "Physical Surgery: Surgery completed."
