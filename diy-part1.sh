#!/bin/bash
set -e

# ========== 1. 物理路径初始化 ==========
# 兼容 GitHub Actions 环境变量
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
WORKSPACE="$GITHUB_WORKSPACE"

SOURCE_DIR="$WORKSPACE/source-repo"
CONFIG_DIR="$WORKSPACE/main-repo/888"
BUILD_DIR="$WORKSPACE/immortalwrt-build"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/firmware"

# ========== 2. 源码物理同步 (路径自动探测) ==========
echo "=== 正在建立物理编译基座 ==="
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"

# 物理探测：检查源码是在 source-repo 根目录还是在子目录
if [ -f "$SOURCE_DIR/Makefile" ]; then
    REAL_SOURCE="$SOURCE_DIR"
elif [ -f "$SOURCE_DIR/immortalwrt/Makefile" ]; then
    REAL_SOURCE="$SOURCE_DIR/immortalwrt"
else
    echo "❌ 物理错误：在 $SOURCE_DIR 中找不到 OpenWrt 源码 (缺少 Makefile)"
    ls -R "$SOURCE_DIR" | head -n 20
    exit 1
fi

echo "✅ 发现源码路径: $REAL_SOURCE"
# 使用 . 确保同步目录下的所有内容
rsync -a "$REAL_SOURCE/" "$BUILD_DIR/"
cd "$BUILD_DIR"

# ========== 3. 依赖净化与三件套注入 (后续逻辑保持不变) ==========
# ... (此处接之前的 feeds 更新、DTS 注入和 Makefile 修改逻辑)
