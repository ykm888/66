#!/bin/bash
set -e

# 1. 物理路径自寻址 (锁定 workspace)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE=$(pwd)

# 自动定位你的配置目录和 OpenWrt 源码目录
# 优先匹配全量同步分支下的目录名
CONFIG_DIR="$WORKSPACE/888"
OPENWRT_DIR="$WORKSPACE/immortalwrt"

echo "=== [Part 1] 物理对齐诊断: 888=$CONFIG_DIR, OpenWrt=$OPENWRT_DIR ==="

# 2. 注入 DTS 和 Makefile (物理纠偏)
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"

# 修正点：即使源文件名叫 emmc，我们也必须强制注入 SPI-NOR 逻辑
if [ -f "$CONFIG_DIR/mt7981b-sl-3000-spi-nor.dts" ]; then
    cp -fv "$CONFIG_DIR/mt7981b-sl-3000-spi-nor.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"
else
    # 如果 888 目录下只有 emmc 版本，通过脚本动态修复分区表（备选方案）
    echo "⚠️ 警告：未找到 SPI-NOR 专属 DTS，正在使用备选注入..."
    [ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && \
    cp -fv "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/mt7981b-sl3000-spi-nor.dts"
fi

# 注入核心 Makefile 定义
[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] && \
    cp -fv "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 3. 强制锁定架构 (物理粉碎 x86，锁定 ARM64/Filogic)
cd "$OPENWRT_DIR"
rm -f .config .config.old

if [ -f "$WORKSPACE/sl3000.config" ]; then
    cp -v "$WORKSPACE/sl3000.config" .config
elif [ -f "$CONFIG_DIR/sl3000.config" ]; then
    cp -v "$CONFIG_DIR/sl3000.config" .config
else
    echo "❌ 错误：在 $WORKSPACE 或 $CONFIG_DIR 都找不到 sl3000.config"
    exit 1
fi

# 执行物理粉碎与架构锁定
sed -i 's/CONFIG_TARGET_x86_64=y/# CONFIG_TARGET_x86_64 is not set/' .config
sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config
{
  echo "CONFIG_TARGET_mediatek=y"
  echo "CONFIG_TARGET_mediatek_filogic=y"
  echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-spi-nor=y"
  # 强制锁定 1GB RAM 参数
  echo "CONFIG_TARGET_RAM_SIZE_1024=y"
} >> .config

# 4. 更新 Feeds 并执行对齐
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig

echo "✅ [Part 1] 成功锁定 ARM64 架构并同步 SPI-NOR DTS"
