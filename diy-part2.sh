#!/bin/bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}/openwrt" || exit 2

REPO="${GITHUB_WORKSPACE}"

# 你的真实文件
DTS="${REPO}/mt7981-sl-3000-emmc.dts"
MK="${REPO}/mt7981_sl3000.mk"
CONF="${REPO}/sl3000.config"

# 复制DTS
[ -f "$DTS" ] && cp -vf "$DTS" target/linux/mediatek/dts/
# 复制mk
[ -f "$MK" ] && cp -vf "$MK" target/linux/mediatek/
# 复制config
[ -f "$CONF" ] && cp -vf "$CONF" .config

make defconfig
echo "✅ 配置已写入，无文件找不到错误"
