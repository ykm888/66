#!/bin/bash

# 原文照抄原则：严格承袭物理路径与逻辑顺序
# 核心指令：延续之前所有设置，不准偷工减料，只修改错误，严禁画蛇添足

# 1. 物理替换设备树文件 (Verbatim copy of path logic)
cp -f custom-config/mt7981b-3000-emmc.dts target/linux/mediatek/dts/mt7981b-3000-emmc.dts

# 2. 物理替换编译 Makefile (Verbatim copy of path logic)
cp -f custom-config/filogic.mk target/linux/mediatek/image/filogic.mk

# 3. 核心物理补丁：注入内核配置文件 (救砖与 eMMC 引导的关键设置)
# 延续之前设置：将 custom-config 目录下的 config-6.6 物理覆盖到源码对应的内核配置路径
if [ -f "custom-config/config-6.6" ]; then
    cp -f custom-config/config-6.6 target/linux/mediatek/filogic/config-6.6
    echo "物理审计：内核配置 config-6.6 已物理注入。"
fi

# 4. 物理执行环境预检
if [ -f "target/linux/mediatek/filogic/config-6.6" ]; then
    echo "物理审计：源头配置校验成功。"
fi

# 5. 救砖固件补丁延续 (确保生成名为 SL3000-Rescue 的 eMMC 镜像)
sed -i 's/DEVICE_TITLE :=/DEVICE_TITLE := SL3000-Rescue/g' target/linux/mediatek/image/filogic.mk 2>/dev/null || true

exit 0
