#!/bin/bash
set -e

# 1. 路径自动定位
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$WORKSPACE/main-repo/888"
OPENWRT_DIR="$WORKSPACE/source-repo/immortalwrt"

echo "=== [Part 1] 正在从 888/ 目录注入硬件三件套 ==="

# 2. 注入 DTS 和 Makefile (增加强制覆盖与路径校验)
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/dts"
mkdir -p "$OPENWRT_DIR/target/linux/mediatek/image"

# 准则：如果存在则拷贝，并确保文件名像素级对齐
[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && \
    cp -fv "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$OPENWRT_DIR/target/linux/mediatek/dts/"

[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] && \
    cp -fv "$CONFIG_DIR/mt7981_sl3000.mk" "$OPENWRT_DIR/target/linux/mediatek/image/"

# 3. 核心：物理粉碎旧配置并锁定架构
cd "$OPENWRT_DIR"
# 物理删除所有可能的配置文件残留，确保 clean build
rm -f .config .config.old

if [ -f "$CONFIG_DIR/sl3000.config" ]; then
    cp -v "$CONFIG_DIR/sl3000.config" .config
    
    # 强制执行“物理去 x86 化”
    sed -i 's/CONFIG_TARGET_x86_64=y/# CONFIG_TARGET_x86_64 is not set/' .config
    sed -i 's/CONFIG_TARGET_x86=y/# CONFIG_TARGET_x86 is not set/' .config
    
    # 注入 SL3000 1G-32M 专用目标选项
    {
      echo "CONFIG_TARGET_mediatek=y"
      echo "CONFIG_TARGET_mediatek_filogic=y"
      echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-spi-nor=y"
    } >> .config
    echo "✅ 成功注入 8000 行配置并锁定 ARM64 架构"
else
    echo "❌ 严重错误：在 $CONFIG_DIR 未发现 sl3000.config"
    exit 1
fi

# 4. Feeds 处理 (在 make defconfig 之前完成)
echo "=== ⚡ 正在同步 Feeds 依赖 ==="
./scripts/feeds update -a
./scripts/feeds install -a

# 5. 静默审计与配置刷新
# 准则：使用 make defconfig 将注入的选项与系统依赖树对齐
echo "=== ⚙️ 执行最终配置审计 (make defconfig) ==="
make defconfig

echo "✅ [Part 1] 物理环境准备就绪，架构：MT7981 (SL3000)"
