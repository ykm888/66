#!/bin/bash

# 原文照抄原则：严格承袭物理路径与逻辑顺序
# 核心指令：物理变量死锁路径，注入救砖设置，同步最新内核配置

PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始像素级补丁注入..."

# 1. 物理替换设备树文件
if [ -f "$PATCH_SRC/mt7981b-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f "$PATCH_SRC/mt7981b-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
    echo "物理审计：[成功] 设备树已注入。"
fi

# 2. 物理替换编译 Makefile
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] filogic.mk 替换成功。"
fi

# 3. 核心设置：注入修复后的内核配置文件
if [ -f "$PATCH_SRC/config-6.6" ]; then
    mkdir -p target/linux/mediatek/filogic/
    cp -f "$PATCH_SRC/config-6.6" target/linux/mediatek/filogic/config-6.6
    echo "物理审计：[成功] 内核配置已物理注入。"
fi

# 4. 【救砖固件设置】物理修改设备标题
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    sed -i 's/DEVICE_TITLE :=/DEVICE_TITLE := SL3000-Rescue/g' target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] 救砖镜像标题 SL3000-Rescue 已锁定。"
fi

exit 0
