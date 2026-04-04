#!/bin/bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}" || exit 1

echo "============================================="
echo " 司络 SL3000 | MT7981B + 1GB DDR + 32MB SPI + 128GB eMMC"
echo "============================================="

# 进入源码（和yml里path: openwrt严格对应）
cd "${GITHUB_WORKSPACE}/openwrt" || { echo "ERROR: openwrt 不存在" >&2; exit 2; }

# 清理并更新feeds
./scripts/feeds clean
./scripts/feeds update -a
./scripts/feeds install -a

# 禁用冲突包
cat >> .config << EOF
CONFIG_PACKAGE_libreswan=n
CONFIG_PACKAGE_strongswan=n
CONFIG_PACKAGE_homeproxy=n
CONFIG_PACKAGE_netatalk=n
CONFIG_PACKAGE_usbgadget=n
CONFIG_PACKAGE_qrtr=n
EOF

make defconfig

echo "✅ diy-part1.sh 完成"
