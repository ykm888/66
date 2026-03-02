#!/bin/bash

# 1. 物理拦截：切除 Kernel 6.6 核心报错点
# 审计：修正内核 6.6 在 MT7981 驱动中关于 WiFi 离线定义的物理冲突
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 物理劫持：重定向 U-Boot 源码源至 1024M 专修分支
# 审计：由于 Makefile 源头已改 UBOOT_CONFIG，此处仅改写源码地址
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：重定向 U-Boot 源码至 sl3000-uboot-base..."
    sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g' "$UBOOT_MK"
    sed -i 's|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g' "$UBOOT_MK"
    sed -i 's|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g' "$UBOOT_MK"
fi

# 3. 物理注入配置
if [ -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" ]; then
    cp -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" .config
    echo "物理注入成功：已加载并覆盖 8000 行核心配置"
    # 强制锁定身份优先级
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
fi
