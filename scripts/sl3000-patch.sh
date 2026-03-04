#!/bin/bash
# 物理审计：本地集成版 - 克隆 U-Boot 源码到 src，清淤、删除官方补丁、配置补充
set -e

echo "=== 物理清淤：粉碎旧缓存与冲突 ==="
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true
rm -rf staging_dir/host/share/u-boot 2>/dev/null || true

echo "=== 删除官方补丁目录，确保无残留 ==="
rm -rf package/boot/uboot-mediatek/patches
mkdir -p package/boot/uboot-mediatek/patches

echo "=== 克隆自定义 U-Boot 源码到本地 src 目录 ==="
rm -rf package/boot/uboot-mediatek/src
git clone --depth 1 -b sl3000-uboot-base https://github.com/ykm888/66.git package/boot/uboot-mediatek/src

echo "=== 验证关键文件 ==="
if [ ! -f package/boot/uboot-mediatek/src/configs/mt7981_emmc_defconfig ]; then
    echo "错误：克隆后未找到 mt7981_emmc_defconfig！"
    exit 1
fi
echo "关键文件存在，继续。"

echo "=== 补充 .config 必要配置 ==="
[ -f .config ] || touch .config

if ! grep -q "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" .config; then
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
fi

if ! grep -q "CONFIG_NR_DRAM_BANKS=1" .config; then
    echo "CONFIG_NR_DRAM_BANKS=1" >> .config
fi

if ! grep -q "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" .config; then
    echo "CONFIG_TARGET_DEVICE_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
fi

echo "=== 补丁脚本执行完毕 ==="
