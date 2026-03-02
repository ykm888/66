#!/bin/bash

# 1. 物理拦截：切除 Kernel 6.6 核心报错点
# 审计：修正内核 6.6 在 MT7981 驱动中关于 WiFi 离线定义的物理冲突
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 物理劫持：重定向 U-Boot 源码源至 1024M 专修分支
UBOOT_MK="package/boot/uboot-mediatek/Makefile"
if [ -f "$UBOOT_MK" ]; then
    echo "物理注入：重定向 U-Boot 源码至 sl3000-uboot-base..."
    sed -i 's|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g' "$UBOOT_MK"
    sed -i 's|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g' "$UBOOT_MK"
    sed -i 's|PKG_MIRROR_HASH:=.*|PKG_MIRROR_HASH:=skip|g' "$UBOOT_MK"
fi

# 3. 【物理自愈核心】：清洗配置并强制锁定身份
if [ -f "$GITHUB_WORKSPACE/custom-config/sl3000.config" ]; then
    echo "物理自愈：执行 8000 行配置清洗，防止旧参数死锁..."
    
    # A. 物理清洗：剔除可能导致新版 OpenWrt 脚本崩溃的全局宏定义
    grep -v "CONFIG_VERSION_NUMBER" "$GITHUB_WORKSPACE/custom-config/sl3000.config" | \
    grep -v "CONFIG_BINARY_FOLDER" | \
    grep -v "CONFIG_SCHED_OMIT_FRAME_POINTER" > .config.tmp
    
    # B. 物理锁定：强制注入 SL-3000 1024M 核心身份（优先级最高）
    {
      echo "CONFIG_TARGET_mediatek=y"
      echo "CONFIG_TARGET_mediatek_filogic=y"
      echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y"
      echo "CONFIG_DEVICE_sl_3000-emmc=y"
      echo "CONFIG_NR_DRAM_BANKS=1"
    } >> .config.tmp
    
    mv .config.tmp .config
    echo "物理自愈：.config 已完成身份重塑"
fi
