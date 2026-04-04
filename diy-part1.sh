#!/bin/bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}" || exit 1

echo "============================================="
echo " 司络 SL3000 | MT7981B + 1GB DDR + 128GB eMMC"
echo "============================================="

# 进入OpenWrt源码目录
cd "${GITHUB_WORKSPACE}/openwrt" || {
    echo "ERROR: 找不到 openwrt 目录" >&2
    exit 2
}

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

echo "✅ diy-part1.sh 执行完成"
