#!/bin/bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}" || exit 1
cd "${GITHUB_WORKSPACE}/openwrt" || { echo "ERROR: openwrt 不存在" >&2; exit 2; }

# 拷贝你的配置（DTS、mk、config）
cp -f "${GITHUB_WORKSPACE}/main-repo/mt7981b-sl3000-emmc.dts" \
  target/linux/mediatek/dts/mt7981b-sl3000-emmc.dts

cp -f "${GITHUB_WORKSPACE}/main-repo/filogic.mk" \
  target/linux/mediatek/filogic.mk

cp -f "${GITHUB_WORKSPACE}/main-repo/sl3000-emmc.config" .config

make defconfig

echo "✅ diy-part2.sh 完成（配置已注入）"
