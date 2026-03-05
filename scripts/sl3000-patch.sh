#!/bin/bash
# 延续 2026-03-02 指令：SL-3000 物理修复逻辑

PATCH_DIR="target/linux/mediatek/patches-6.6"

echo "🧹 1. 物理清淤：切除 1703 坏补丁防止 Hunk 失败..."
rm -f "$PATCH_DIR"/*1703*v6.9-net-phy*

echo "🛠️ 2. 物理修复 API：强制对齐 ethtool_keee 结构体..."
# 解决 Linux 6.6 网络栈编译冲突
find "$PATCH_DIR" -type f -exec sed -i 's/struct ethtool_eee/struct ethtool_keee/g' {} +
find "$PATCH_DIR" -type f -exec sed -i 's/\.supported/\.supported_u32/g' {} +

echo "🧠 3. 物理锁定 1024M 内存 DTS 定义..."
DTS_FILE=$(find target/linux/mediatek/dts/ -name "*sl-3000-emmc.dts")
if [ -f "$DTS_FILE" ]; then
    # 原文照抄：锁定 1024M 物理内存
    sed -i 's/reg = <0 0x40000000 0 0x[0-9a-fA-F]*>/reg = <0 0x40000000 0 0x40000000>/g' "$DTS_FILE"
fi

echo "📦 4. U-Boot 1024M 源码物理对齐..."
# 延续上一版原文照抄，修改 PKG 源码
sed -i "s|PKG_SOURCE_URL:=.*|PKG_SOURCE_URL:=https://github.com/ykm888/66.git|g" package/boot/uboot-mediatek/Makefile
sed -i "s|PKG_SOURCE_VERSION:=.*|PKG_SOURCE_VERSION:=sl3000-uboot-base|g" package/boot/uboot-mediatek/Makefile
