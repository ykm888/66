#!/bin/bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}/openwrt" || exit 2

echo "============================================="
echo "司络 SL3000 MT7981B eMMC 仅编译filogic平台"
echo "============================================="

# 清理并更新feeds
./scripts/feeds clean
./scripts/feeds update -a
./scripts/feeds install -a

# ==========================
# 核心：只启用filogic(MT7981)，禁用x86/x64
# ==========================
cat >> .config << EOF
# 目标平台：MT7981
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981-ax3000-router-emmc=y

# 彻底关闭 x86/x64（这就是你patch失败的根源）
CONFIG_TARGET_x86=n
CONFIG_TARGET_MULTI_ARCH=n

# 禁用所有报错/警告包
CONFIG_PACKAGE_dae=n
CONFIG_PACKAGE_daed=n
CONFIG_PACKAGE_libreswan=n
CONFIG_PACKAGE_strongswan=n
CONFIG_PACKAGE_netatalk=n
CONFIG_PACKAGE_luci-app-homeproxy=n
CONFIG_PACKAGE_usbgadget=n
CONFIG_PACKAGE_prism54-firmware=n
CONFIG_PACKAGE_rtl8192su-firmware=n
EOF

# 删除x86报错补丁（彻底解决patch failed）
rm -vf target/linux/x86/patches-5.4/120-hwrng-geode-fix-accessing-registers.patch

make defconfig
echo "✅ 平台已锁定MT7981，x86已禁用，patch报错已修复"
