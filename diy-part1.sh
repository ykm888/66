#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
export WORKSPACE

OUTPUT_DIR="$WORKSPACE/output"
mkdir -p $OUTPUT_DIR/atf
mkdir -p $OUTPUT_DIR/uboot

# 只装救砖编译依赖
sudo apt update
sudo apt install -y \
  build-essential gcc-aarch64-linux-gnu \
  make libssl-dev device-tree-compiler bc
