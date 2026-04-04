#!/bin/bash
set -euo pipefail

# 完全沿用你自己的路径结构
WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
OUTPUT_DIR="$WORKSPACE/output"

# 交叉编译
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# 进入你自己的源码根目录
cd "$SOURCE_DIR"

# ==============================
# 编译 ATF（你仓库里的路径）
# ==============================
echo "=== 编译 ATF ==="
cd arm-trusted-firmware
make realclean
make PLAT=mt7981 all
cp build/mt7981/release/bl2.bin  $OUTPUT_DIR/atf/
cp build/mt7981/release/fip.bin  $OUTPUT_DIR/atf/

# ==============================
# 编译 U-Boot（你仓库里的路径）
# ==============================
echo "=== 编译 U-Boot ==="
cd ../u-boot
make distclean
make mt7981_sl3000_defconfig
make -j$(nproc)
cp u-boot.bin $OUTPUT_DIR/uboot/
# ==============================
echo "=== 救砖包生成完毕 ==="
ls -lh $OUTPUT_DIR/atf/ $OUTPUT_DIR/uboot/
