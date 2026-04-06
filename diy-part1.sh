#!/bin/bash
set -e

# 1. 路径自动定位
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
OPENWRT_DIR="$WORKSPACE/source-repo/immortalwrt"
CONFIG_FILE="$SCRIPT_DIR/sl3000.config"

echo "=== [Part 1] 开始物理环境注入 ==="

# 2. 检查并注入 SL3000 核心组件
if [ ! -d "$OPENWRT_DIR" ]; then
    echo "❌ 错误：找不到源码目录 $OPENWRT_DIR"
    exit 1
fi

# 注入 DTS 和 Makefile 定义
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"
[ -f "$SCRIPT_DIR/mt7981b-sl3000-emmc.dts" ] && cp -v "$SCRIPT_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"
[ -f "$SCRIPT_DIR/mt7981_sl3000.mk" ] && cp -v "$SCRIPT_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 3. 注入 8000 行核心配置 (关键：先物理删除旧配置)
echo "=== ⚙️ 正在强制锁定 MT7981 架构配置 ==="
cd "$OPENWRT_DIR"
rm -f .config
if [ -f "$CONFIG_FILE" ]; then
    cp -v "$CONFIG_FILE" .config
    # 🔴 核心修复：强制关闭 x86 默认选项，开启 MediaTek 选项
    sed -i 's/CONFIG_TARGET_x86_64=y/# CONFIG_TARGET_x86_64 is not set/' .config
    sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config
    echo "CONFIG_TARGET_mediatek=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-spi-nor=y" >> .config
else
    echo "❌ 错误：未发现 $CONFIG_FILE"
    exit 1
fi

# 4. 更新 Feeds
echo "=== ⚡ 更新与安装系统 Feeds ==="
./scripts/feeds update -a

# 粉碎已知冲突包
PROBLEM_PKGS="aardvark-dns podman cargo-c python-cryptography ruby"
for pkg in $PROBLEM_PKGS; do
    find feeds/ -type d -name "$pkg" -exec rm -rf {} \; 2>/dev/null || true
done

./scripts/feeds install -a

# 5. 刷新配置
echo "=== ⚙️ 执行 make defconfig 补充依赖 ==="
make defconfig

echo "✅ [Part 1] 架构锁定与配置注入完成"
