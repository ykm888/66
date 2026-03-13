#!/bin/bash
# SL-3000 物理硬化脚本 - 像素级对齐版

# 1. 物理环境初始化
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# 2. 跨分支搬运硬化源码
echo "Physical Surgery: Cloning hardening sources..."
git clone -b sl3000-clean-source --depth 1 https://github.com/ykm888/66.git hardening_src

# 3. 建立物理包外壳 (防止依赖报错)
mkdir -p package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/uboot-mediatek

# 4. 物理抢救 Makefile 模具并本地化
# 只有先拿到 Makefile，系统才会承认这个包存在
echo "Physical Surgery: Localizing Makefiles..."
if [ -d feeds/mediatek/arm-trusted-firmware-mediatek ]; then
    cp -rf feeds/mediatek/arm-trusted-firmware-mediatek/Makefile package/boot/arm-trusted-firmware-mediatek/
    # 物理篡改：切断远程下载链接，锁定为本地 src
    sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=./g' package/boot/arm-trusted-firmware-mediatek/Makefile
fi

if [ -d feeds/mediatek/uboot-mediatek ]; then
    cp -rf feeds/mediatek/uboot-mediatek/Makefile package/boot/uboot-mediatek/
    sed -i 's/PKG_SOURCE_URL:=.*/PKG_SOURCE_URL:=./g' package/boot/uboot-mediatek/Makefile
fi

# 5. 注入物理源码到包内
cp -rf hardening_src/atf/* package/boot/arm-trusted-firmware-mediatek/
cp -rf hardening_src/u-boot/* package/boot/uboot-mediatek/

# 6. 物理清场
echo "Physical Surgery: Uninstalling shadow feeds..."
./scripts/feeds uninstall arm-trusted-firmware-mediatek uboot-mediatek

# 7. 物理注入 888 核心定义
[ -d ../888 ] && find target/linux/mediatek/ -type d -name "dts" -exec cp -f ../888/mt7981-sl-3000-emmc.dts {} \;
[ -f ../888/filogic.mk ] && cp -f ../888/filogic.mk target/linux/mediatek/image/

# 8. 兼容性补丁
find package/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +

rm -rf hardening_src
echo "Physical Surgery: Success."
