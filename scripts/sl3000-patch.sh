#!/bin/bash

# 原文照抄原则：基于成功体系，执行救砖三件套补丁，物理修复内核报错
# 物理路径锁定：target/linux/mediatek/filogic/config-6.6
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始对齐 SL-3000 救砖工程体系..."

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

# --- 核心物理修复：治理内核 Error 2 ---
# 锁定您指定的精确路径
KERNEL_CONFIG="target/linux/mediatek/filogic/config-6.6"

echo "物理审计：正在定位内核配置文件..."
if [ -f "$KERNEL_CONFIG" ]; then
    if [ -f "$PATCH_SRC/config-6.6" ]; then
        cp -f "$PATCH_SRC/config-6.6" "$KERNEL_CONFIG"
        echo "物理审计：[成功] 已通过 custom-config/config-6.6 文件进行物理覆盖。"
    else
        # 物理修正：开启 PCIe 支持，禁用 DebugFS
        sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$KERNEL_CONFIG"
        sed -i 's/CONFIG_MTK_LVTS_THERMAL_DEBUGFS=y/# CONFIG_MTK_LVTS_THERMAL_DEBUGFS is not set/g' "$KERNEL_CONFIG"
        echo "物理审计：[成功] 已对 $KERNEL_CONFIG 执行 sed 物理修正。"
    fi
else
    echo "物理审计：[重试] 尝试在 openwrt 子目录下定位..."
    # 兼容性备选路径
    ALT_CONFIG="openwrt/$KERNEL_CONFIG"
    if [ -f "$ALT_CONFIG" ]; then
        sed -i 's/# CONFIG_PCIE_MEDIATEK is not set/CONFIG_PCIE_MEDIATEK=y/g' "$ALT_CONFIG"
        sed -i 's/CONFIG_MTK_LVTS_THERMAL_DEBUGFS=y/# CONFIG_MTK_LVTS_THERMAL_DEBUGFS is not set/g' "$ALT_CONFIG"
        echo "物理审计：[成功] 已在子目录完成修正。"
    else
        echo "物理审计：[错误] 仍无法找到 config-6.6，请核对仓库结构！"
    fi
fi

# --- 三件套物理覆盖 ---
# 1. 设备树物理对齐
if [ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
    echo "物理审计：[成功] 设备树已覆盖。"
fi

# 2. Makefile 物理对齐
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] filogic.mk 已覆盖。"
fi

# 3. 标识锁定
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue/g' target/linux/mediatek/image/filogic.mk
fi

exit 0
