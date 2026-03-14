#!/bin/bash

# =========================================================
# 司络 SL-3000 (MT7981B) 物理加固脚本 - 路径解断版
# =========================================================

echo "Starting Physical Injection for SL-3000..."

# --- 1. 物理清场与包名对齐 ---
# 彻底清理旧的 ATF 包，防止系统默认源干扰
rm -rf package/boot/arm-trusted-firmware-mediatek
mkdir -p package/boot/arm-trusted-firmware-mediatek

# --- 2. 物理注入核心 Makefile ---
# 注入 ATF Makefile (使用真名注册逻辑)
[ -f "888/atf-Makefile" ] && cp -f 888/atf-Makefile package/boot/arm-trusted-firmware-mediatek/Makefile
# 注入 U-Boot Makefile
[ -f "888/uboot-Makefile" ] && cp -f 888/uboot-Makefile package/boot/uboot-mediatek/Makefile

# --- 3. 物理环境加固 ---
# 确保 888 零件仓库位于根目录，支持 Makefile 内部的 $(TOPDIR) 调用
if [ -d "888" ]; then
    echo "Physical directory 888 found, syncing to root..."
else
    echo "Error: Physical directory 888 not found in current path!"
    exit 1
fi

# 注入其他物理零件
[ -f "888/filogic.mk" ] && cp -f 888/filogic.mk target/linux/mediatek/image/filogic.mk
[ -d "target/linux/mediatek/dts/" ] && cp -f 888/*.dts target/linux/mediatek/dts/

# --- 4. 物理强推：配置硬核锁定 ---
[ -f "888/sl3000.config" ] && cp -f 888/sl3000.config .config
# 二次补强：确保真名包名不被 defconfig 剔除
echo "CONFIG_PACKAGE_trusted-firmware-a-mt7981-nor-ddr4=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000_nor=y" >> .config

# --- 5. 寻址坐标物理全局替换 ---
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/pad-to 512k/pad-to 1024k/g' {} +
find target/linux/mediatek/image/ -name "*.mk" -exec sed -i 's/seek=512/seek=1024/g' {} +

echo "Physical Injection Complete. Path Aligned."
