#!/bin/bash
set -e

# 1. 物理路径溯源
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
# 自动定位 ATF 源码根目录
ATF_DIR=$(find "$WORKSPACE/source-repo" -maxdepth 2 -name "plat" -type d | head -n 1 | xargs dirname)
OPENWRT_DIR=$(find "$WORKSPACE/source-repo" -maxdepth 2 -name "immortalwrt" -type d | head -n 1)
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

# 2. ATF 物理构建 (增加 fip 目标)
cd "$ATF_DIR"
echo "🛠️ 启动 ATF 物理构建 (包含 FIP 封装)..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
# 关键修复：增加 'all fip' 确保生成 fip.bin
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all fip -j$(nproc)

# 3. 产物物理搜寻 (兼容 .bin 和 .img)
RELEASE_DIR=$(find . -name "release" -type d | grep "mt7981" | head -n 1)
echo "🔍 正在扫描产物目录: $RELEASE_DIR"

# 像素级对齐：BL2 可能叫 bl2.bin 或 bl2.img
BL2_RAW=$(find "$RELEASE_DIR" -name "bl2.bin" -o -name "bl2.img" | head -n 1)
# FIP 必须生成，如果没生成则链路报错
FIP_RAW=$(find "$RELEASE_DIR" -name "fip.bin" | head -n 1)

if [ -n "$BL2_RAW" ] && [ -n "$FIP_RAW" ]; then
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1GB_RESCUE_32M.bin"
    echo "📦 发现产物: $BL2_RAW 和 $FIP_RAW，开始缝合..."
    
    # 物理缝合 32MB 救砖包
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    dd if="$BL2_RAW" of="$RESCUE_IMG" conv=notrunc
    # FIP 写入 3.5MB 偏移
    dd if="$FIP_RAW" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    
    cp -v "$BL2_RAW" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
    cp -v "$FIP_RAW" "$OUTPUT_DIR/rescue/fip-nor.bin"
else
    echo "❌ 链路中断：产物不全！"
    echo "目录列表内容如下："
    ls -R "$RELEASE_DIR"
    exit 1
fi

# 4. OpenWrt 编译
cd "$OPENWRT_DIR"
make -j$(nproc) V=s || exit 1

# 5. 导出
BIN_DIR="$OPENWRT_DIR/bin/targets/mediatek/filogic"
find "$BIN_DIR" -type f \( -name "*sl_3000*" -o -name "*.itb" \) -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ [Part 2] 全链路产物就绪"
