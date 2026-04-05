#!/bin/bash
# =================================================================
# 脚本定义：SL3000 三件套物理注入 (GitHub Actions 专用版)
# 修复点：自动识别 main-repo 与 source-repo 的相对位置
# =================================================================

# 1. 动态定位路径 (以当前脚本所在位置为基准)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"

# 你的 888 文件夹就在脚本同级的 888 目录下
CONFIG_DIR="$SCRIPT_DIR/888"
# 源码在 source-repo 目录下
SOURCE_DIR="$WORKSPACE/source-repo"

echo "=== 🔍 路径审计 ==="
echo "工作空间: $WORKSPACE"
echo "配置目录: $CONFIG_DIR"
echo "源码目录: $SOURCE_DIR"

# 2. 物理注入验证
if [ ! -d "$CONFIG_DIR" ]; then
    echo "❌ 错误：找不到配置目录 $CONFIG_DIR"
    exit 1
fi

# 3. 注入三件套 (确保目标目录存在)
mkdir -p "$SOURCE_DIR/target/linux/mediatek/dts/"
mkdir -p "$SOURCE_DIR/target/linux/mediatek/image/"

echo "=== 🚚 开始物理注入 ==="
cp -v "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$SOURCE_DIR/target/linux/mediatek/dts/" || exit 1
cp -v "$CONFIG_DIR/mt7981_sl3000.mk" "$SOURCE_DIR/target/linux/mediatek/image/" || exit 1
cp -v "$CONFIG_DIR/sl3000.config" "$SOURCE_DIR/.config" || exit 1

# 4. 执行 Feeds 逻辑
cd "$SOURCE_DIR"

echo "=== ⚡ 更新 Feeds ==="
./scripts/feeds update -a

# 强力粉碎冲突包
PROBLEM_PKGS="aardvark-dns podman cargo-c python-cryptography ruby"
for pkg in $PROBLEM_PKGS; do
    find feeds/ -type d -name "$pkg" -exec rm -rf {} \; 2>/dev/null || true
done

./scripts/feeds install -a

# 5. 刷新配置
echo "=== ⚙️ 刷新 defconfig ==="
make defconfig
