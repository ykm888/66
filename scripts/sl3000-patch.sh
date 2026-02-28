#!/bin/bash

# 原文照抄原则：延续成功体系，执行救砖三件套补丁，物理修复内核报错
# 物理路径死锁 [2026-02-27]
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始执行工程体系绝对路径补丁..."

# --- 延续成功设置：软件包物理注入 ---
{
    echo "CONFIG_PACKAGE_luci-app-ksmbd=y"
    echo "CONFIG_PACKAGE_luci-i18n-ksmbd-zh-cn=y"
    echo "CONFIG_PACKAGE_ksmbd-utils=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fsck=y"
    echo "CONFIG_PACKAGE_mkf2fs=y"
    echo "CONFIG_PACKAGE_kmod-mmc=y"
} >> .config

# --- 核心物理修复：内核配置精准命中 ---
KERNEL_CONFIG="target/linux/mediatek/filogic/config-6.6"

echo "物理审计：正在物理定位 -> $KERNEL_CONFIG"
if [ -f "$KERNEL_CONFIG" ]; then
    if [ -f "$PATCH_SRC/config-6.6" ]; then
        cp -f "$PATCH_SRC/config-6.6" "$KERNEL_CONFIG"
        echo "物理审计：[成功] 已执行物理覆盖。"
    else
        sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$KERNEL_CONFIG"
        sed -i 's/CONFIG_MTK_LVTS_THERMAL_DEBUGFS=y/# CONFIG_MTK_LVTS_THERMAL_DEBUGFS is not set/g' "$KERNEL_CONFIG"
        echo "物理审计：[成功] 已执行 sed 物理修正。"
    fi
else
    echo "物理审计：[错误] 目标路径不存在，尝试递归定位..."
    # 物理保底方案
    REAL_CONFIG=$(find . -name "config-6.6" | grep "mediatek" | head -n 1)
    if [ -n "$REAL_CONFIG" ]; then
        sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$REAL_CONFIG"
        echo "物理审计：[成功] 在 $REAL_CONFIG 完成保底修复。"
    fi
fi

# --- 三件套物理覆盖 ---
# 1. 设备树物理对齐
if [ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
fi

# 2. Makefile 物理对齐
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
fi

# 3. 标识锁定
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue/g' target/linux/mediatek/image/filogic.mk
fi

exit 0
