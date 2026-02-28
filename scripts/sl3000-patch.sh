#!/bin/bash

# 原文照抄原则：严格承袭物理路径与逻辑顺序
# 核心指令：物理变量死锁路径，注入救砖设置

PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始 SL-3000 救砖固件全流程加固..."

# 1. 物理替换设备树文件 (精准对齐 mt7981-sl-3000-emmc.dts)
if [ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
    echo "物理审计：[成功] 设备树物理覆盖完成。"
fi

# 2. 物理替换编译 Makefile
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] filogic.mk 替换完成。"
fi

# 3. 核心设置延续：物理注入修复版内核配置文件 (config-6.6)
if [ -f "$PATCH_SRC/config-6.6" ]; then
    mkdir -p target/linux/mediatek/filogic/
    cp -f "$PATCH_SRC/config-6.6" target/linux/mediatek/filogic/config-6.6
    echo "物理审计：[成功] 完整版内核配置已物理注入。"
fi

# 4. 【救砖固件设置】物理修改设备标题
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    # 物理锁定 SL3000 救砖标题，确保生成的固件名称易于辨识
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue/g' target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] 救砖镜像标识已锁定。"
fi

exit 0
