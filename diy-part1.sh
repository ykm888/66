#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
OUTPUT="$WORKSPACE/output"

mkdir -p "$OUTPUT"/atf
mkdir -p "$OUTPUT"/uboot

# 只装最基础工具，不搞多余
sudo apt update && sudo apt install -y gcc-aarch64-linux-gnu make libssl-dev
