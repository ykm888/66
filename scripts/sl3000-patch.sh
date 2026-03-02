#!/bin/bash

# 1. 物理拦截：切除 Kernel 6.6 编译报错点 (MTK_WIFI_CHIP_OFFLINE)
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 物理劫持：重定向 U-Boot 源码至本仓库的 sl3000-uboot-base 分支
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：正在重定向 U-Boot 源码源至 sl3000-uboot-base..."
    sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g' "$UBOOT_MK"
    sed -i 's|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g' "$UBOOT_MK"
    sed -i 's|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g' "$UBOOT_MK"
fi

# 3. 物理对齐：锁定使用 mt7981_sl_3000-emmc_defconfig (1024M)
MT7981_MK="target/linux/mediatek/image/mt7981.mk"
if [ -f "$MT7981_MK" ]; then
    sed -i 's/UBOOT_CONFIG:=.*/UBOOT_CONFIG:=mt7981_sl_3000-emmc/g' "$MT7981_MK"
fi

# 4. 物理覆盖：将 main 分支下的 8000 行 sl3000.config 注入编译生效位
if [ -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" .config
    echo "物理注入成功：已从 main 分支加载 sl3000.config"
fi
