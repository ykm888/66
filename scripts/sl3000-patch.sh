#!/bin/bash

# 原文照抄原则：物理合并 DIY 逻辑与三件套补丁逻辑
# 核心指令：物理变量死锁路径，确保救砖固件生成

PATCH_SRC="${GITHUB_WORKSPACE}/custom-config"

echo "物理审计：开始 SL-3000 全能补丁合并执行..."

# --- 第一部分：DIY 逻辑合并 (原 diy-part2 逻辑) ---
# 注入软件列表到默认配置 (保留 luci-app-ksmbd 等)
echo "CONFIG_PACKAGE_luci-app-ksmbd=y" >> .config
echo "CONFIG_PACKAGE_luci-i18n-ksmbd-zh-cn=y" >> .config
echo "CONFIG_PACKAGE_ksmbd-utils=y" >> .config

# --- 第二部分：三件套物理覆盖 ---
# 1. 物理替换设备树
if [ -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" ]; then
    mkdir -p target/linux/mediatek/dts/
    cp -f "$PATCH_SRC/mt7981-sl-3000-emmc.dts" target/linux/mediatek/dts/mt7981-sl-3000-emmc.dts
    echo "物理审计：[成功] 设备树已对齐。"
fi

# 2. 物理替换编译 Makefile
if [ -f "$PATCH_SRC/filogic.mk" ]; then
    mkdir -p target/linux/mediatek/image/
    cp -f "$PATCH_SRC/filogic.mk" target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] filogic.mk 已对齐。"
fi

# 3. 物理注入修复版内核配置文件
if [ -f "$PATCH_SRC/config-6.6" ]; then
    mkdir -p target/linux/mediatek/filogic/
    cp -f "$PATCH_SRC/config-6.6" target/linux/mediatek/filogic/config-6.6
    echo "物理审计：[成功] 内核配置已对齐。"
fi

# --- 第三部分：救砖标识锁定 ---
if [ -f "target/linux/mediatek/image/filogic.mk" ]; then
    # 物理锁定 SL3000 救砖标题
    sed -i 's/DEVICE_MODEL := 3000 eMMC/DEVICE_MODEL := 3000-Rescue/g' target/linux/mediatek/image/filogic.mk
    echo "物理审计：[成功] 救砖镜像标识已锁定。"
fi

exit 0
