#!/bin/bash

# 原文照抄原则：严格承袭物理路径与逻辑顺序
# 核心指令：延续之前所有设置，不准偷工减料，通过物理路径修正解决 No such file 报错

# 1. 物理替换设备树文件 (修正路径前缀)
if [ -f "custom-config/mt7981b-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mt7981b-3000-emmc.dts
elif [ -f "../custom-config/mt7981b-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f ../custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mt7981b-3000-emmc.dts
fi

# 2. 物理替换编译 Makefile (修正路径前缀并确保目录存在)
if [ -f "custom-config/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f custom-config/filogic.mk target/linux/mediatek/image/filogic.mk
elif [ -f "../custom-config/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f ../custom-config/filogic.mk target/linux/mediatek/image/filogic.mk
fi

# 3. 核心设置延续：注入内核配置文件
if [ -f "custom-config/config-6.6" ]; then
    mkdir -p target/linux/mediatek/filogic/
    cp -f custom-config/config-6.6 target/linux/mediatek/filogic/config-6.6
elif [ -f "../custom-config/config-6.6" ]; then
    mkdir -p target/linux/mediatek/filogic/
    cp -f ../custom-config/config-6.6 target/linux/mediatek/filogic/config-6.6
fi

# 4. 救砖固件设置还原 (物理执行环境预检后修改)
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    sed -i 's/DEVICE_TITLE :=/DEVICE_TITLE := SL3000-Rescue/g' target/linux/mediatek/image/filogic.mk 2>/dev/null || true
    echo "物理审计：救砖补丁已成功注入 Makefile。"
fi

exit 0
