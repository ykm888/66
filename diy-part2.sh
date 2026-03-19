#!/bin/bash
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
WORKSPACE="$GITHUB_WORKSPACE"
BUILD_DIR="$WORKSPACE/immortalwrt-build"
OUTPUT_DIR="$WORKSPACE/output"

if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ 物理死锁：找不到编译目录 $BUILD_DIR"
    exit 1
fi

cd "$BUILD_DIR"

echo "=== 启动全量并行编译 ==="
make -j$(nproc) || make -j1 V=s

echo "=== 正在搜集产物 ==="
mkdir -p "$OUTPUT_DIR/firmware"
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} "$OUTPUT_DIR/firmware/" \;

# 计算校验码
cd "$OUTPUT_DIR/firmware"
for file in *; do
    [ -f "$file" ] && [ "${file##*.}" != "md5" ] && md5sum "$file" > "${file}.md5"
done
