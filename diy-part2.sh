#!/bin/bash
set -e

[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
WORKSPACE="$GITHUB_WORKSPACE"
BUILD_DIR="$WORKSPACE/immortalwrt-build"
OUTPUT_DIR="$WORKSPACE/output"

cd "$BUILD_DIR"

echo "=== 启动 SL3000 512M 正式编译 ==="
# 使用并行编译，如果失败自动回退单线程报错
make -j$(nproc) || make -j1 V=s

echo "=== 正在搜集并校验固件产物 ==="
mkdir -p "$OUTPUT_DIR/firmware"
# 物理搜索 sysupgrade 固件
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} "$OUTPUT_DIR/firmware/" \;

# 计算 MD5 校验
cd "$OUTPUT_DIR/firmware"
for file in *; do
    if [ -f "$file" ] && [ "${file##*.}" != "md5" ]; then
        md5sum "$file" > "${file}.md5"
    fi
done

echo "✅ SL3000 救砖固件物理构建全链路闭合完成"
