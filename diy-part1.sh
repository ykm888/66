#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p $OUTPUT_DIR/atf
mkdir -p $OUTPUT_DIR/uboot
mkdir -p $OUTPUT_DIR/mtk_uartboot

# 只装救砖编译依赖
sudo apt update
sudo apt install -y build-essential gcc-aarch64-linux-gnu make libssl-dev device-tree-compiler bc

echo "✅ 环境准备完成"
