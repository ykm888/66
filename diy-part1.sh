#!/bin/bash
set -e

# 进入源码根目录
cd "$GITHUB_WORKSPACE"/immortalwrt-build || exit 1

echo "========== diy-part1: 清理冲突依赖 =========="

# 关闭所有报错插件（修复 mbedtls / 依赖不存在）
sed -i 's/CONFIG_PACKAGE_libreswan=.*/CONFIG_PACKAGE_libreswan=n/' .config
sed -i 's/CONFIG_PACKAGE_strongswan=.*/CONFIG_PACKAGE_strongswan=n/' .config
sed -i 's/CONFIG_PACKAGE_homeproxy=.*/CONFIG_PACKAGE_homeproxy=n/' .config
sed -i 's/CONFIG_PACKAGE_netatalk=.*/CONFIG_PACKAGE_netatalk=n/' .config
sed -i 's/CONFIG_PACKAGE_usbgadget=.*/CONFIG_PACKAGE_usbgadget=n/' .config
sed -i 's/CONFIG_PACKAGE_qrtr=.*/CONFIG_PACKAGE_qrtr=n/' .config
sed -i 's/CONFIG_PACKAGE_kmod-qrtr-smd=.*/CONFIG_PACKAGE_kmod-qrtr-smd=n/' .config
sed -i 's/CONFIG_PACKAGE_kmod-qrtr-mhi=.*/CONFIG_PACKAGE_kmod-qrtr-mhi=n/' .config

# 更新 feeds 避免依赖错乱
./scripts/feeds clean
./scripts/feeds update -a
./scripts/feeds install -a

make defconfig
