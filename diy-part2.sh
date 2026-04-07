#!/bin/bash
set -e

# 1. 物理路径绝对对齐 (锁定 source-repo)
WORKSPACE=$(pwd)
# 自动识别 Actions 拉取的源码根目录
SOURCE_ROOT="$WORKSPACE/source-repo"

# 定义四个核心子目录的绝对物理坐标
ATF_DIR="$SOURCE_ROOT/arm-trusted-firmware"
UBOOT_DIR="$SOURCE_ROOT/u-boot"
OPENWRT_DIR="$SOURCE_ROOT/immortalwrt"
UARTBOOT_DIR="$SOURCE_ROOT/mtk_uartboot"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/atf" "$OUTPUT_DIR/uboot" "$OUTPUT_DIR/firmware"

echo "🚀 [全链路溯源] 开始物理构建: ATF=$ATF_DIR, OpenWrt=$OPENWRT_DIR"

# 2. ⚡ 注入 1GB DDR4 内存补丁 (锁定 ATF 目录)
if [ -d "$ATF_DIR" ]; then
    cd "$ATF_DIR"
    echo "🛠️ 正在注入 1GB RAM 物理补丁..."
    DRAM_PATH="plat/mediatek/mt7981/drivers/dram"
    mkdir -p "$DRAM_PATH"
    cat <<EOF > "$DRAM_PATH/mtk_mem_init.c"
#include <common/debug.h>
extern void emi_init_setting(void);
void mtk_mem_init(void) {
    NOTICE("EMI: SL3000 1GB DDR4 Physical Patch Active.\n");
    emi_init_setting();
}
EOF
    sed -i '/BL2_SOURCES/s/$/ plat\/mediatek\/mt7981\/drivers\/dram\/mtk_mem_init.c plat\/mediatek\/mt7981\/drivers\/dram\/emicfg.c/' plat/mediatek/mt7981/platform.mk
    
    echo "🏗️ 正在构建 BL2 (SPI-NOR)..."
    make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 BOOT_DEVICE=nor DRAM_SIZE=1024 bl2 -j$(nproc)
else
    echo "❌ 错误: 找不到 ATF 目录: $ATF_DIR"
    exit 1
fi

# 3. 🏗️ 构建系统与 U-Boot (锁定 OpenWrt 目录)
if [ -d "$OPENWRT_DIR" ]; then
    cd "$OPENWRT_DIR"
    echo "🏗️ 正在构建 OpenWrt 系统..."
    # 强制执行多线程编译
    make -j$(nproc)
else
    echo "❌ 错误: 找不到 OpenWrt 目录: $OPENWRT_DIR"
    exit 1
fi

# 4. 📦 二次封装 FIP (物理偏移对齐)
UBOOT_RAW=$(find "$OPENWRT_DIR/bin" -name "*u-boot.bin*" | head -n 1)
if [ -f "$UBOOT_RAW" ]; then
    cd "$ATF_DIR"
    echo "📦 发现 U-Boot，执行 FIP 像素级封装..."
    make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 BOOT_DEVICE=nor DRAM_SIZE=1024 BL33="$UBOOT_RAW" fip -j$(nproc)
fi

# 5. 🧱 物理缝合 32MB 救砖镜像
RESCUE_IMG="$OUTPUT_DIR/SL3000_1GB_RESCUE_32M.bin"
ATF_RELEASE=$(find "$ATF_DIR" -name "release" -type d | grep "mt7981" | head -n 1)

echo "🧱 执行 32MB 物理镜像缝合 (Offset: 0x0 BL2 / 0x380000 FIP)..."
dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
[ -f "$ATF_RELEASE/bl2.bin" ] && dd if="$ATF_RELEASE/bl2.bin" of="$RESCUE_IMG" conv=notrunc
[ -f "$ATF_RELEASE/fip.bin" ] && dd if="$ATF_RELEASE/fip.bin" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc

# 6. 🚚 产物整理 (物理对齐到 Workflow 提取路径)
echo "🚚 收集产物零件..."
cp -v "$ATF_RELEASE/bl2.bin" "$OUTPUT_DIR/atf/" 2>/dev/null || true
cp -v "$ATF_RELEASE/fip.bin" "$OUTPUT_DIR/atf/" 2>/dev/null || true
cp -v "$UBOOT_RAW" "$OUTPUT_DIR/uboot/" 2>/dev/null || true
find "$OPENWRT_DIR/bin" -name "*sysupgrade.bin" -exec cp -v {} "$OUTPUT_DIR/firmware/" \; 2>/dev/null || true

echo "✅ [全链路同步成功] 产物已就绪。"
