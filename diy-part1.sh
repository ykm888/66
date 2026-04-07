#!/bin/bash
set -e

# 1. 物理路径绝对对齐
WORKSPACE=$(pwd)
# 溯源：你的全量同步仓库被 Action 拉取到了 source-repo 目录
SOURCE_ROOT="$WORKSPACE/source-repo"
CONFIG_DIR="$SOURCE_ROOT/888"
OPENWRT_DIR="$SOURCE_ROOT/immortalwrt"

echo "=== [Part 1] 物理路径校验 ==="
echo "SOURCE_ROOT: $SOURCE_ROOT"
echo "CONFIG_DIR: $CONFIG_DIR"
echo "OPENWRT_DIR: $OPENWRT_DIR"

# 2. 检查并注入物理零件
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"

# 注入 DTS (强制重命名为 spi-nor 以对齐 .config)
if [ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ]; then
    cp -fv "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/mt7981b-sl3000-spi-nor.dts"
fi

# 注入 Makefile (Device 定义)
[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] && \
    cp -fv "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 3. 架构粉碎与配置注入
cd "$OPENWRT_DIR"
rm -f .config .config.old

# 查找 sl3000.config (尝试两个物理位置)
if [ -f "$CONFIG_DIR/sl3000.config" ]; then
    cp -v "$CONFIG_DIR/sl3000.config" .config
elif [ -f "$SOURCE_ROOT/sl3000.config" ]; then
    cp -v "$SOURCE_ROOT/sl3000.config" .config
else
    echo "❌ 错误：找不到物理配置文件 sl3000.config"
    exit 1
fi

# 修正架构锁定逻辑
sed -i 's/CONFIG_TARGET_x86_64=y/# CONFIG_TARGET_x86_64 is not set/' .config
sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config
{
  echo "CONFIG_TARGET_mediatek=y"
  echo "CONFIG_TARGET_mediatek_filogic=y"
  echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-spi-nor=y"
  echo "CONFIG_TARGET_RAM_SIZE_1024=y"
} >> .config

# 4. 执行物理对齐 (解决 scripts/feeds 找不到的问题)
# 此时已经在 $OPENWRT_DIR 目录下，物理存在 scripts 目录
./scripts/feeds update -a
./scripts/feeds install -a
make defconfig

echo "✅ [Part 1] 架构锁定与物理对齐成功"
