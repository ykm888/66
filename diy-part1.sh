#!/bin/bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}/openwrt" || exit 2

echo "============================================="
echo "司络 SL3000 MT7981B eMMC 编译脚本"
echo "============================================="

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
echo "✅ diy-part1 完成"
