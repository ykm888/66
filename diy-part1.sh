#!/bin/bash
set -e

# 1. 路径自动定位
# 假设脚本在 main-repo/ 下，WORKSPACE 是 main-repo 的父目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"

# 核心：你的源码在 source-repo 下的并列子目录中
SOURCE_REPO="$WORKSPACE/source-repo"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
# 你的 8000 行配置和 DTS 所在的目录
CONFIG_DIR="$SCRIPT_DIR"

echo "=== 🔍 [Part 1] 路径物理审计 ==="
echo "工作空间: $WORKSPACE"
echo "源码根目录: $SOURCE_REPO"
echo "OpenWrt 目录: $OPENWRT_DIR"

# 2. 严谨性检查
if [ ! -d "$OPENWRT_DIR" ]; then
    echo "❌ 错误：找不到 $OPENWRT_DIR，请确认仓库结构是否为 source-repo/immortalwrt"
    ls -F "$SOURCE_REPO"
    exit 1
fi

# 3. 注入 SL3000 核心组件 (物理对齐)
echo "=== 🚚 正在注入 SL3000 核心组件 ==="
# 针对 Filogic 架构的 DTS 存放路径
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"

# 拷贝 DTS 和设备定义 (请确认你的文件名与下面一致)
[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && cp -v "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"
[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] && cp -v "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 4. 执行 Feeds 逻辑
cd "$OPENWRT_DIR"

echo "=== ⚡ 更新与安装系统 Feeds ==="
./scripts/feeds update -a

# 强力粉碎已知冲突包 (清理编译环境)
PROBLEM_PKGS="aardvark-dns podman cargo-c python-cryptography ruby"
for pkg in $PROBLEM_PKGS; do
    find feeds/ -type d -name "$pkg" -exec rm -rf {} \; 2>/dev/null || true
done

./scripts/feeds install -a

# 5. 核心配置注入 (关键步骤：先删后拷，确保 8000 行配置生效)
echo "=== ⚙️ 注入并刷新 1024M 核心配置 ==="
if [ -f "$CONFIG_DIR/sl3000.config" ]; then
    rm -f .config
    cp -v "$CONFIG_DIR/sl3000.config" .config
    # 扩展：如果需要追加特定配置，可以在此处使用 sed 或 echo
    echo "CONFIG_TARGET_mediatek_filog=y" >> .config
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
else
    echo "⚠️ 警告：未在 $CONFIG_DIR 发现 sl3000.config，将使用默认配置！"
fi

# 执行刷新，补充依赖项
make defconfig

echo "✅ [Part 1] 物理注入与 Feeds 初始化成功"
