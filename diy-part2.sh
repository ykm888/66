#!/bin/bash
# =========================================================
# SL-3000 23.05 救砖预埋脚本 (像素级对齐)
# =========================================================

echo "--- [物理溯源]：正在执行 23.05 零件物理预埋 ---"

# 1. 清理并创建 23.05 物理预埋区
# OpenWrt 在编译包时，会自动将 package/xxx/files/ 下的内容覆盖到源码 src 目录
rm -rf openwrt/package/boot/arm-trusted-firmware-mediatek/files
rm -rf openwrt/package/boot/uboot-mediatek/files
mkdir -p openwrt/package/boot/arm-trusted-firmware-mediatek/files
mkdir -p openwrt/package/boot/uboot-mediatek/files

# 2. 劫持 Makefile (23.05 版本专用)
# 确保你的 888/atf-Makefile 里的 URL 指向了你截图中的 ykm888/66.git
cp -f 888/atf-Makefile openwrt/package/boot/arm-trusted-firmware-mediatek/Makefile
cp -f 888/uboot-Makefile openwrt/package/boot/uboot-mediatek/Makefile

# 3. 物理投递零件 (针对 ATF)
# 这些文件会在 compile 阶段物理覆盖你底层库中的对应文件
[ -f 888/bl2_dev_spi_nor.c ] && cp -f 888/bl2_dev_spi_nor.c openwrt/package/boot/arm-trusted-firmware-mediatek/files/
[ -f 888/platform_def.h ] && cp -f 888/platform_def.h openwrt/package/boot/arm-trusted-firmware-mediatek/files/
[ -f 888/platform.mk ] && cp -f 888/platform.mk openwrt/package/boot/arm-trusted-firmware-mediatek/files/
[ -f 888/bl2.mk ] && cp -f 888/bl2.mk openwrt/package/boot/arm-trusted-firmware-mediatek/files/
[ -f 888/mt7981-spi2.dts ] && cp -f 888/mt7981-spi2.dts openwrt/package/boot/arm-trusted-firmware-mediatek/files/

# 4. 物理投递零件 (针对 U-Boot)
[ -f 888/mt7981_sl3000_defconfig ] && cp -f 888/mt7981_sl3000_defconfig openwrt/package/boot/uboot-mediatek/files/
[ -f 888/mt7981-sl3000.dts ] && cp -f 888/mt7981-sl3000.dts openwrt/package/boot/uboot-mediatek/files/

# 5. 强制 23.05 配置对齐
# 如果不存在 sl3000.config，则通过追加方式硬写
if [ ! -f 888/sl3000.config ]; then
cat >> openwrt/.config <<EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y
CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y
CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-sl3000-nor=y
EOF
fi

echo "--- [物理溯源]：23.05 预埋完成，地基已就绪 ---"
