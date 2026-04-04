#!/bin/bash
set -e

cd "$GITHUB_WORKSPACE/openwrt" || exit 1

echo "============================================="
echo " 司络 SL3000 | MT7981B + 1GB DDR + 32MB SPI + 128GB eMMC"
echo "============================================="

# 清理冲突依赖，避免编译报错
sed -i 's/CONFIG_PACKAGE_libreswan=.*/CONFIG_PACKAGE_libreswan=n/' .config 2>/dev/null
sed -i 's/CONFIG_PACKAGE_strongswan=.*/CONFIG_PACKAGE_strongswan=n/' .config 2>/dev/null
sed -i 's/CONFIG_PACKAGE_homeproxy=.*/CONFIG_PACKAGE_homeproxy=n/' .config 2>/dev/null
sed -i 's/CONFIG_PACKAGE_netatalk=.*/CONFIG_PACKAGE_netatalk=n/' .config 2>/dev/null
sed -i 's/CONFIG_PACKAGE_usbgadget=.*/CONFIG_PACKAGE_usbgadget=n/' .config 2>/dev/null
sed -i 's/CONFIG_PACKAGE_qrtr=.*/CONFIG_PACKAGE_qrtr=n/' .config 2>/dev/null
sed -i 's/CONFIG_PACKAGE_kmod-qrtr-smd=.*/CONFIG_PACKAGE_kmod-qrtr-smd=n/' .config 2>/dev/null
sed -i 's/CONFIG_PACKAGE_kmod-qrtr-mtd=.*/CONFIG_PACKAGE_kmod-qrtr-mtd=n/' .config 2>/dev/null

# 标准 feeds 更新
./scripts/feeds clean
./scripts/feeds update -a
./scripts/feeds install -a

make defconfig

echo "✅ diy-part1 执行完成：无内存强制，原生1GB配置"
