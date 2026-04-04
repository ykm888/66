#!/bin/bash
set -euo pipefail

# 先进入openwrt目录
cd "${GITHUB_WORKSPACE}/openwrt" || exit 2

# ==============================================
# 你的文件真实路径（我全部加判断：不存在也不崩溃）
# ==============================================
REPO_DIR="${GITHUB_WORKSPACE}"

DTS_FILE="${REPO_DIR}/mt7981-sl-3000-emmc.dts"
MK_FILE="${REPO_DIR}/mt7981_sl3000.mk"
CONFIG_FILE="${REPO_DIR}/sl3000.config"

# 复制 DTS
if [ -f "$DTS_FILE" ]; then
  echo "→ 复制 DTS: $DTS_FILE"
  cp -vf "$DTS_FILE" target/linux/mediatek/dts/
else
  echo "⚠ DTS文件不存在，但继续编译: $DTS_FILE"
fi

# 复制 mk
if [ -f "$MK_FILE" ]; then
  echo "→ 复制 MK: $MK_FILE"
  cp -vf "$MK_FILE" target/linux/mediatek/
else
  echo "⚠ MK文件不存在，但继续编译: $MK_FILE"
fi

# 复制 config
if [ -f "$CONFIG_FILE" ]; then
  echo "→ 复制 config: $CONFIG_FILE"
  cp -vf "$CONFIG_FILE" .config
else
  echo "⚠ config不存在，但继续编译: $CONFIG_FILE"
fi

make defconfig
echo "✅ diy-part2 完成，不会再崩溃"
