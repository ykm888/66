#!/bin/bash
set -e

# 1. 环境与路径对齐
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
SOURCE_REPO="$WORKSPACE/source-repo"
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

echo "=== 🛠️ 开始 SL3000 1G-32M 全量构建 (无USB版) ==="

# --- [2. 执行 ATF 物理修复与编译] ---
# (此处省略之前的 mtk_mem_init.c 和 bl2_dev_spi_nor.c 注入代码，保持不变)

cd "$ATF_DIR"
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all

# --- [3. 提取 33.55MB 全量镜像与独立小包] ---
BUILD_EXPORT="$ATF_DIR/build/mt7981/release"
BL2_IMG=$(find "$BUILD_EXPORT" -name "bl2.img" | head -n 1)
FIP_BIN=$(find "$BUILD_EXPORT" -name "fip.bin" | head -n 1)

if [ -f "$BL2_IMG" ] && [ -f "$FIP_BIN" ]; then
    echo "📦 正在缝合 33.55MB 物理镜像..."
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin"
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    dd if="$BL2_IMG" of="$RESCUE_IMG" conv=notrunc
    dd if="$FIP_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    
    echo "🚚 正在提取独立组件包..."
    cp -v "$BL2_IMG" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
    cp -v "$FIP_BIN" "$OUTPUT_DIR/rescue/fip-nor.bin"
    cp -v "$FIP_BIN" "$OUTPUT_DIR/rescue/u-boot-nor.bin"
    [ -f "$BUILD_EXPORT/bl2_ram.bin" ] && cp -v "$BUILD_EXPORT/bl2_ram.bin" "$OUTPUT_DIR/rescue/bl2-ram-1g.bin"
fi

# --- [4. 构建并提取系统升级固件 (.itb)] ---
echo "=== ⚙️ 启动 ImmortalWrt 系统固件构建 ==="
cd "$OPENWRT_DIR"

# 强制将 Part 1 注入的配置应用到当前编译
[ -f ".config" ] || cp -v "$WORKSPACE/main-repo/sl3000.config" .config
make defconfig

# 执行编译 (-j$(nproc) 利用全部 CPU 核心)
echo "正在进行系统级编译，请稍候..."
make -j$(nproc) V=s || (echo "❌ 编译失败"; exit 1)

# 提取生成的升级包
# 注意：路径匹配 sl_3000-emmc 或者是你 Makefile 中定义的名称
echo "🚚 正在提取最终升级固件..."
find bin/targets/mediatek/filogic/ -type f \( -name "*sysupgrade.itb" -o -name "*sysupgrade.bin" \) -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ [SUCCESS] 所有产物已就绪于 output/ 目录"
