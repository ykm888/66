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

echo "=== [Part 2] ATF 路径自愈: $ATF_DIR ==="

# 2. 内存补丁 (自适应物理寻址)
cd "$ATF_DIR"
MEM_FILE=$(find . -name "mtk_mem_init.c" -print -quit)

if [ -n "$MEM_FILE" ]; then
    echo "⚙️ 发现内存驱动: $MEM_FILE，注入 1024M 训练补丁..."
    sed -i 's/DRAM_SIZE_512M/DRAM_SIZE_1024M/g' "$MEM_FILE"
    sed -i 's/0x20000000/0x40000000/g' "$MEM_FILE"
else
    echo "⚠️ 警告：未发现 mtk_mem_init.c，可能路径层级过深"
fi

# 3. ATF 物理构建
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all -j$(nproc)

# 4. 救砖包物理缝合 (BL2 + FIP)
RELEASE_DIR=$(find . -name "release" -type d | grep "mt7981" | head -n 1)
BL2_IMG=$(find "$RELEASE_DIR" -name "bl2.img" | head -n 1)
FIP_BIN=$(find "$RELEASE_DIR" -name "fip.bin" | head -n 1)

if [ -f "$BL2_IMG" ] && [ -f "$FIP_BIN" ]; then
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1GB_RESCUE_32M.bin"
    # 生成 32MB 救砖底包
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    dd if="$BL2_IMG" of="$RESCUE_IMG" conv=notrunc
    dd if="$FIP_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    cp -v "$BL2_IMG" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
    cp -v "$FIP_BIN" "$OUTPUT_DIR/rescue/fip-nor.bin"
else
    echo "❌ 链路中断：未生成 BL2/FIP 产物"
    exit 1
fi

# 5. OpenWrt 编译与产物提取
cd "$OPENWRT_DIR"
make -j$(nproc) V=s || exit 1

BIN_DIR="$OPENWRT_DIR/bin/targets/mediatek/filogic"
find "$BIN_DIR" -type f \( -name "*sl_3000*" -o -name "*.itb" \) -exec cp -v {} "$OUTPUT_DIR/" \;

[ "$(ls -A "$OUTPUT_DIR")" ] || exit 1
echo "✅ [Part 2] 全链路产物就绪"
