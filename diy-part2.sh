#!/bin/bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}" || exit 1
cd "${GITHUB_WORKSPACE}/openwrt" || {
    echo "ERROR: 找不到 openwrt 目录" >&2
    exit 2
}

# ====================== 你的真实文件名 ======================
BASE="${GITHUB_WORKSPACE}"

DTS_SRC="${BASE}/mt7981-sl-3000-emmc.dts"
MK_SRC="${BASE}/mt7981_sl3000.mk"
CONF_SRC="${BASE}/sl3000.config"

# 复制 DTS
cp -vf "${DTS_SRC}" target/linux/mediatek/dts/

# 复制 mk
cp -vf "${MK_SRC}" target/linux/mediatek/

# 复制 config
cp -vf "${CONF_SRC}" .config

make defconfig

echo "✅ diy-part2.sh 配置注入完成"
