#!/bin/bash

# 原文照抄原则：延续之前所有软件包设置，物理执行救砖三件套补丁
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：执行 SL-3000 救砖逻辑与 DIY 设置延续..."

# --- 延续之前设置：软件包物理注入 (强制写入 .config) ---
{
    echo "CONFIG_PACKAGE_luci-app-ksmbd=y"
    echo "CONFIG_PACKAGE_luci-i18n-ksmbd-zh-cn=y"
    echo "CONFIG_PACKAGE_ksmbd-utils=y"
    echo "CONFIG_PACKAGE_kmod-fs-f2fs=y"
    echo "CONFIG_PACKAGE_f2fsck=y"
    echo "CONFIG_PACKAGE_mkf2fs=y"
    echo "CONFIG_PACKAGE_kmod-mmc=y"
} >> .config

# --- 三件套物理覆盖 ---
# 1. 物理替换设备树
if [ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
    echo "物理审计：[成功] 设备树已对齐。"
fi

# 2. 物理替换 Makefile
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] filogic.mk 已对齐。"
fi

# 3. 救砖标识锁定
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    # 物理锁定 SL3000 救砖标题
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue/g' target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] 救砖镜像标识已锁定。"
fi

exit 0
