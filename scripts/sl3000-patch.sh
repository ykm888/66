#!/bin/bash

# 1. 物理拦截：切除 Kernel 6.6 核心报错点
# 审计：修正内核 6.6 在 MT7981 驱动中关于 WiFi 离线定义的物理冲突，防止编译中断
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 物理劫持：重定向 U-Boot 源码源至 1024M 专修分支
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：重定向 U-Boot 源码至 sl3000-uboot-base..."
    # 物理改写源码地址与版本，绕过官方默认源码，编译器将直接匹配你的 mt7981_emmc_defconfig
    sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g' "$UBOOT_MK"
    sed -i 's|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g' "$UBOOT_MK"
    sed -i 's|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g' "$UBOOT_MK"
fi

# 3. 物理注入配置并执行【依赖性自动更新】
# 审计：确保 1024M 内存定义在 .config 中生效，并通过 olddefconfig 物理对齐 Kconfig 依赖
if [ -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" .config
    echo "物理注入：已加载 sl3000.config，正在执行物理依赖检查 (olddefconfig)..."
    make olddefconfig
else
    echo "物理警告：未找到 sl3000.config，请检查 main 分支路径"
fi
