#!/bin/bash
set -e

# 1. 路径自动定位
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
# 定义 888 目录的绝对路径
CONFIG_DIR="$WORKSPACE/main-repo/888"
OPENWRT_DIR="$WORKSPACE/source-repo/immortalwrt"

echo "=== [Part 1] 正在处理 888 目录下的硬件三件套 ==="

# 2. 验证 888 目录是否存在
if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ 错误：找不到 888 目录，路径为: $CONFIG_DIR"
    echo "📂 当前 main-repo 结构如下："
    ls -R "$WORKSPACE/main-repo"
    exit 1
fi

# 3. 物理注入 DTS 和 Makefile
echo "📦 正在注入 DTS 与 Makefile..."
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"

[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && \
    cp -v "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"

[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] && \
    cp -v "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 4. 强制锁定架构并应用 8000 行配置
echo "⚙️ 正在应用 sl3000.config 并物理锁定架构..."
cd "$OPENWRT_DIR"
rm -f .config

if [ -f "$CONFIG_DIR/sl3000.config" ]; then
    cp -v "$CONFIG_DIR/sl3000.config" .config
    
    # 🔴 核心修复：粉碎 x86 默认标记，强制开启 MediaTek 路径
    sed -i 's/CONFIG_TARGET_x86_64=y/# CONFIG_TARGET_x86_64 is not set/' .config
    sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config
    
    {
      echo "CONFIG_TARGET_mediatek=y"
      echo "CONFIG_TARGET_mediatek_filogic=y"
      echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-spi-nor=y"
    } >> .config
else
    echo "❌ 错误：在 $CONFIG_DIR 中未发现 sl3000.config"
    exit 1
fi

# 5. 更新 Feeds
echo "=== ⚡ 更新并安装系统 Feeds ==="
./scripts/feeds update -a
./scripts/feeds install -a

# 6. 执行最终对齐
echo "=== ⚙️ 执行 make defconfig (计算依赖树) ==="
make defconfig

echo "✅ [Part 1] 成功：硬件三件套已就绪，架构锁定为 ARM64 (MT7981)"
