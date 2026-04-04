#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
OUTPUT_DIR="$WORKSPACE/output"

echo "=== 复制救砖文件 ==="

find "$SOURCE_DIR" -name "bl2.bin"  2>/dev/null | head -1 | xargs -I {} cp {} "$OUTPUT_DIR"/atf/
find "$SOURCE_DIR" -name "bl2.img" 2>/dev/null | head -1 | xargs -I {} cp {} "$OUTPUT_DIR"/atf/
find "$SOURCE_DIR" -name "fip.bin"  2>/dev/null | head -1 | xargs -I {} cp {} "$OUTPUT_DIR"/atf/
find "$SOURCE_DIR" -name "u-boot.bin" 2>/dev/null | head -1 | xargs -I {} cp {} "$OUTPUT_DIR"/uboot/

echo "=== 完成 ==="
ls -lh "$OUTPUT_DIR"/atf/ "$OUTPUT_DIR"/uboot/
