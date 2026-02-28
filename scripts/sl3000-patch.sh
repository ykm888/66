#!/bin/bash

# 原文照抄原则：延续成功体系设置，执行救砖三件套补丁，物理修复 6.6 内核报错点
# 核心指令：物理路径死锁 [2026-02-27]
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：执行成功案例工程体系对齐..."

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

# --- 核心物理修复：内核配置强制覆盖 ---
# 锁定 target/linux/mediatek/filogic/config-6.6 路径
KERNEL_CONFIG="target/linux/mediatek/filogic/config-6.6"

if [ -f "$PATCH_SRC/config-6.6" ]; then
    cp -f "$PATCH_SRC/config-6.6" "$KERNEL_CONFIG"
    echo "物理审计：[成功] 已物理覆盖修复后的 config-6.6。"
else
    # 物理保底方案：执行内核级物理修正，防止 Error 2
    sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$KERNEL_CONFIG"
    sed -i 's/CONFIG_MTK_LVTS_THERMAL_DEBUGFS=y/# CONFIG_MTK_LVTS_THERMAL_DEBUGFS is not set/g' "$KERNEL_CONFIG"
    echo "物理审计：[警告] 未找到补丁文件，已执行 sed 物理强制修复。"
fi

# --- 三件套物理覆盖 (严格对齐锁定的路径) ---
# 1. 设备树物理对齐 (锁定名称：mt7981-sl-3000-emmc.dts)
if [ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
    echo "物理审计：[成功] 设备树物理路径对齐完成。"
fi

# 2. Makefile 物理对齐 (锁定名称：filogic.mk)
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] Makefile 物理路径对齐完成。"
fi

# 3. 标识锁定
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue/g' target/linux/mediatek/image/filogic.mk
fi

exit 0
