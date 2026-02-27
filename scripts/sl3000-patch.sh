#!/bin/bash

# 原文照抄原则：严格承袭物理路径与逻辑顺序
# 核心指令：针对 ykm99999/66 仓库物理路径进行精准补丁，严禁偷工减料

# 1. 物理替换设备树文件
if [ -f "../custom-config/mt7981b-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f ../custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mt7981b-3000-emmc.dts
fi

# 2. 物理替换编译 Makefile
if [ -f "../custom-config/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk
fi

# 3. 核心设置延续：注入内核配置文件 (锁定 6.6 内核路径)
if [ -f "../custom-config/config-6.6" ]; then
    mkdir -p target/linux/mediatek/filogic/
    cp -f ../custom-config/config-6.6 target/linux/mediatek/filogic/config-6.6
    echo "物理审计：内核配置 config-6.6 已物理注入。"
fi

# 4. 救砖固件设置还原
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    sed -i 's/DEVICE_TITLE :=/DEVICE_TITLE := SL3000-Rescue/g' target/linux/mediatek/image/filogic.mk 2>/dev/null || true
fi

exit 0
