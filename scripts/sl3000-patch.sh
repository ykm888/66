#!/bin/bash
# 物理审计：本地集成版 - 克隆 U-Boot 源码，打包放入 dl/，清淤、删除官方补丁、配置补充
set -e

echo "=== 物理清淤：粉碎旧缓存与冲突 ==="
rm -rf dl/u-boot-* 2>/dev/null || true
rm -rf build_dir/target-*/u-boot-* 2>/dev/null || true
rm -rf staging_dir/host/share/u-boot 2>/dev/null || true

echo "=== 删除官方补丁目录，确保无残留 ==="
rm -rf package/boot/uboot-mediatek/patches
mkdir -p package/boot/uboot-mediatek/patches

echo "=== 克隆自定义 U-Boot 源码到临时目录 ==="
rm -rf /tmp/uboot-src
git clone --depth 1 -b sl3000-uboot-base https://github.com/ykm888/66.git /tmp/uboot-src

echo "=== 验证关键文件 ==="
if [ ! -f /tmp/uboot-src/configs/mt7981_emmc_defconfig ]; then
    echo "错误：克隆后未找到 mt7981_emmc_defconfig！"
    exit 1
fi
echo "关键文件存在，继续。"

echo "=== 打包源码为 uboot-custom.tar.zst 并放入 dl/ 目录 ==="
mkdir -p dl
cd /tmp
# 打包目录本身，使用 zstd 压缩（级别 19 兼顾速度和体积）
tar -cf - uboot-src | zstd -19 -o $GITHUB_WORKSPACE/openwrt/dl/uboot-custom.tar.zst
rm -rf /tmp/uboot-src
echo "打包完成：$(ls -lh $GITHUB_WORKSPACE/openwrt/dl/uboot-custom.tar.zst)"

echo "=== 补充 .config 必要配置 ==="
cd $GITHUB_WORKSPACE/openwrt
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
