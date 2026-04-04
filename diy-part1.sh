#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p $OUTPUT_DIR/atf
mkdir -p $OUTPUT_DIR/uboot
mkdir -p $OUTPUT_DIR/mtk_uartboot

# 只安装编译ATF/U-Boot需要的工具（极轻量）
sudo apt update
sudo apt install -y build-essential gcc-aarch64-linux-gnu \
  git make flex bison libssl-dev device-tree-compiler bc

# 记录路径给part2用
echo "$WORKSPACE" > $WORKSPACE/build-dir.txt
echo "✅ part1 环境准备完成（仅救砖工具链）"
