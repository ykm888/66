#!/bin/bash
set -e

# 1. 路径自动定位
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$WORKSPACE/main-repo/888"
OPENWRT_DIR="$WORKSPACE/source-repo/immortalwrt"

echo "=== [Part 1] 正在从 888/ 目录注入硬件三件套 ==="

# 2. 注入 DTS 和 Makefile
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"

[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && \
    cp -v "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"

[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] && \
    cp -v "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 3. 强制锁定架构（防止误编译为 x86）
cd "$OPENWRT_DIR"
rm -f .config
if [ -f "$CONFIG_DIR/sl3000.config" ]; then
    cp -v "$CONFIG_DIR/sl3000.config" .config
    # 物理粉碎 x86 标记
    sed -i 's/CONFIG_TARGET_x86_64=y/# CONFIG_TARGET_x86_64 is not set/' .config
    sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config
    # 强制写入 SL3000 目标
    {
      echo "CONFIG_TARGET_mediatek=y"
      echo "CONFIG_TARGET_mediatek_filogic=y"
      echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-spi-nor=y"
    } >> .config
else
    echo "❌ 错误：在 $CONFIG_DIR 未发现 sl3000.config"
    exit 1
fi

# 4. 更新 Feeds 并执行 defconfig
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig
echo "✅ [Part 1] 架构已锁定为 ARM64 (MT7981)"
