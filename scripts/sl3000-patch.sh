#!/bin/bash

# 原文照抄原则：严格承袭物理路径与逻辑顺序
# 核心指令：物理变量死锁路径，像素级对齐仓库源码文件名

# 物理路径锁定：使用 GitHub Workspace 绝对路径
PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：正在执行补丁源像素级对齐..."

# 1. 物理替换设备树文件 (锁定仓库源文件名：mt7981b-sl-3000-emmc.dts)
if [ -f "$PATCH_SRC/mt7981b-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    # 物理校准：确保源和目标文件名 100% 一致
    cp -f "$PATCH_SRC/mt7981b-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981b-sl-3000-emmc.dts
    echo "物理审计：[成功] 设备树补丁已物理覆盖仓库源码文件。"
else
    echo "物理审计：[严重错误] 未找到文件 $PATCH_SRC/mt7981b-sl-3000-emmc.dts"
fi

# 2. 物理替换编译 Makefile
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] filogic.mk 替换成功。"
fi

# 3. 核心设置延续：物理注入内核配置文件
if [ -f "$PATCH_SRC/config-6.6" ]; then
    mkdir -p target/linux/mediatek/filogic/
    cp -f "$PATCH_SRC/config-6.6" target/linux/mediatek/filogic/config-6.6
    echo "物理审计：[成功] 内核配置 config-6.6 已物理注入。"
fi

# 4. 救砖固件设置还原 (物理执行环境预检)
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    sed -i 's/DEVICE_TITLE :=/DEVICE_TITLE := SL3000-Rescue/g' target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] 救砖镜像标题已锁定。"
fi

exit 0
