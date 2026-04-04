#!/bin/bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}" || exit 1
cd "${GITHUB_WORKSPACE}/openwrt" || exit 2

# ==============================
# 关键：文件都在仓库根目录，不是 main-repo
# ==============================
DTS_SRC="${GITHUB_WORKSPACE}/mt7981b-sl3000-emmc.dts"
MK_SRC="${GITHUB_WORKSPACE}/filogic.mk"
CONFIG_SRC="${GITHUB_WORKSPACE}/sl3000-emmc.config"

cp -f "$DTS_SRC" target/linux/mediatek/dts/
cp -f "$MK_SRC" target/linux/mediatek/filogic.mk
cp -f "$CONFIG_SRC" .config

make defconfig

echo "✅ diy-part2 执行成功"
