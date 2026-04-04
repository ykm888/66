#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE="$WORKSPACE/source-repo"
OUTPUT="$WORKSPACE/output"

# ==============================
# 直接从你源码里拷贝现成救砖文件
# ==============================
echo "=== 复制预编译救砖文件 ==="

# 复制 bl2 fip u-boot
find "$SOURCE" -name "bl2.bin"  | head -1 | xargs -I {} cp {} "$OUT"/atf/
find "$SOURCE" -name "bl2.img"  | head -1 | xargs -I {} cp {} "$OUT"/atf/
find "$SOURCE" -name "fip.bin"  | head -1 | xargs -I {} cp {} "$OUT"/atf/
find "$SOURCE" -name "u-boot.bin" | head -1 | xargs -I {} cp {} "$OUT"/uboot/

echo "=== 救砖全家桶已打包 ==="
ls -lh "$OUT"/atf/ "$OUT"/uboot/
