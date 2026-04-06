#!/bin/bash
set -e

# 1. 物理路径自寻址
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
# 自动定位 888 目录和 OpenWrt 目录
CONFIG_DIR=$(find "$WORKSPACE" -type d -name "888" | head -n 1)
OPENWRT_DIR=$(find "$WORKSPACE" -type d -name "immortalwrt" | head -n 1)

echo "=== [Part 1] 物理对齐: 888=$CONFIG_DIR, OpenWrt=$OPENWRT_DIR ==="

# 2. 注入 DTS 和 Makefile
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"

[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && \
    cp -fv "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"

[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] && \
    cp -fv "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 3. 强制锁定架构 (物理粉碎 x86)
cd "$OPENWRT_DIR"
rm -f .config .config.old

if [ -f "$CONFIG_DIR/sl3000.config" ]; then
    cp -v "$CONFIG_DIR/sl3000.config" .config
    sed -i 's/CONFIG_TARGET_x86_64=y/# CONFIG_TARGET_x86_64 is not set/' .config
    sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config
    {
      echo "CONFIG_TARGET_mediatek=y"
      echo "CONFIG_TARGET_mediatek_filogic=y"
      echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-spi-nor=y"
    } >> .config
else
    echo "❌ 错误：找不到 sl3000.config"
    exit 1
fi

# 4. 更新 Feeds 并执行对齐
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
echo "✅ [Part 1] 成功锁定 ARM64 架构"
