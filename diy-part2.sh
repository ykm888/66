#!/bin/bash
set -e

# 1. 路径定义
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
SOURCE_REPO="$WORKSPACE/source-repo"
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

echo "=== [Part 2] 开始 ATF 1024M 补丁与 32MB 缝合 ==="

# 2. ATF 物理补丁 (强制 1024M 内存)
cd "$ATF_DIR"
if [ -f "plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c" ]; then
    sed -i 's/DRAM_SIZE_512M/DRAM_SIZE_1024M/g' plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c
    sed -i 's/0x20000000/0x40000000/g' plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c
fi

make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all

# 3. 缝合 32MB 全量救砖包
BUILD_EXPORT="$ATF_DIR/build/mt7981/release"
BL2_IMG=$(find "$BUILD_EXPORT" -name "bl2.img" | head -n 1)
FIP_BIN=$(find "$BUILD_EXPORT" -name "fip.bin" | head -n 1)

if [ -f "$BL2_IMG" ] && [ -f "$FIP_BIN" ]; then
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1GB_RESCUE_32M.bin"
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    dd if="$BL2_IMG" of="$RESCUE_IMG" conv=notrunc
    dd if="$FIP_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    cp -v "$BL2_IMG" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
    cp -v "$FIP_BIN" "$OUTPUT_DIR/rescue/fip-nor.bin"
fi

# 4. 编译系统固件
cd "$OPENWRT_DIR"
make -j$(nproc) V=s || { echo "❌ 编译失败"; exit 1; }

# 5. 🚚 强制提取产物 (关键修复)
echo "=== 正在提取最终产物 ==="
BIN_DIR="$OPENWRT_DIR/bin/targets/mediatek/filogic"
if [ -d "$BIN_DIR" ]; then
    # 模糊匹配设备名称，确保拷贝成功
    find "$BIN_DIR" -type f \( -name "*sl_3000*" -o -name "*.itb" \) -exec cp -v {} "$OUTPUT_DIR/" \;
else
    echo "❌ 错误：找不到编译产物目录 $BIN_DIR"
    exit 1
fi

# 最终物理检查：如果 output 为空，直接让 Action 报错
[ "$(ls -A "$OUTPUT_DIR")" ] || { echo "❌ 错误：output 目录为空，未生成任何固件！"; exit 1; }
echo "✅ [Part 2] 任务圆满完成"
