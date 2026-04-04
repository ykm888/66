#!/bin/bash
set -euo pipefail

WORKSPACE="$GITHUB_WORKSPACE"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR"/atf
mkdir -p "$OUTPUT_DIR"/uboot

sudo apt update
sudo apt install -y gcc-aarch64-linux-gnu make libssl-dev
