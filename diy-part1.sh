#!/bin/bash
set -e

# 1. 路径自动定位
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"

# 核心：你的 OpenWrt 源码就在 source-repo 的子目录下
OPENWRT_DIR="$WORKSPACE/source-repo/immortalwrt"
CONFIG_DIR="$SCRIPT_DIR/888"

echo "=== 🔍 路径审计 ==="
echo "工作空间: $WORKSPACE"
echo "配置目录: $CONFIG_DIR"
echo "系统源码: $OPENWRT_DIR"

# 2. 检查 OpenWrt 目录是否存在 (防止路径层级理解错误)
if [ ! -d "$OPENWRT_DIR" ]; then
    echo "❌ 错误：在 $OPENWRT_DIR 找不到 OpenWrt 源码，请检查仓库结构！"
    # 尝试打印目录结构辅助排查
    ls -R "$WORKSPACE/source-repo" | head -n 20
    exit 1
fi

# 3. 注入三件套到对应的子目录
echo "=== 🚚 正在注入 SL3000 三件套 ==="
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts/"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image/"

cp -v "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"
cp -v "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"
cp -v "$CONFIG_DIR/sl3000.config" "$OPENWRT_DIR/.config"

# 4. 执行 Feeds 逻辑 (进入正确的子目录)
cd "$OPENWRT_DIR"

echo "=== ⚡ 更新系统 Feeds ==="
./scripts/feeds update -a

# 强力粉碎冲突包 (根据成功案例经验)
PROBLEM_PKGS="aardvark-dns podman cargo-c python-cryptography ruby"
for pkg in $PROBLEM_PKGS; do
    find feeds/ -type d -name "$pkg" -exec rm -rf {} \; 2>/dev/null || true
done

./scripts/feeds install -a

# 5. 刷新配置
echo "=== ⚙️ 刷新系统配置 ==="
make defconfig

echo "✅ Part 1 注入与配置完成"
