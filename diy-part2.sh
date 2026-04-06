#!/bin/bash
# SL3000 Physical Recovery Alignment Script (Full Traceability Version)
set -e  # 准则：任何一步失败立即熔断

# 1. 环境上下文定义
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
SOURCE_REPO="$WORKSPACE/source-repo"
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output"

# 物理清理，防止旧产物干扰
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/rescue"

echo "=== [诊断] 启动 ATF 1024M 内存物理训练补丁 ==="

# 2. ATF 源码层溯源修改
cd "$ATF_DIR"
MEM_INIT_FILE="plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c"
if [ -f "$MEM_INIT_FILE" ]; then
    # 强制修改 DRAM 初始化参数为 1024MB
    sed -i 's/DRAM_SIZE_512M/DRAM_SIZE_1024M/g' "$MEM_INIT_FILE"
    sed -i 's/0x20000000/0x40000000/g' "$MEM_INIT_FILE"
    echo "✅ 内存训练补丁应用成功: 1024MB DDR4"
else
    echo "❌ 溯源失败：找不到 $MEM_INIT_FILE"
    exit 1
fi

# 3. 执行物理级 ATF 编译
echo "🛠️ 正在执行 ATF 物理构建 (Target: SPI-NOR)..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all -j$(nproc)

# 4. 产物物理校验与 32MB 实心缝合
BUILD_EXPORT="$ATF_DIR/build/mt7981/release"
BL2_IMG=$(find "$BUILD_EXPORT" -name "bl2.img" | head -n 1)
FIP_BIN=$(find "$BUILD_EXPORT" -name "fip.bin" | head -n 1)

if [ -f "$BL2_IMG" ] && [ -f "$FIP_BIN" ]; then
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1GB_RESCUE_32M.bin"
    echo "📦 正在执行像素级缝合: $RESCUE_IMG"
    # 生成 32MB 全物理镜像 (33554432 Bytes)
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    # BL2 写入头部 (Offset 0)
    dd if="$BL2_IMG" of="$RESCUE_IMG" conv=notrunc
    # FIP (U-Boot) 写入 3.5MB 偏移处 (0x380000)
    dd if="$FIP_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    
    cp -v "$BL2_IMG" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
    cp -v "$FIP_BIN" "$OUTPUT_DIR/rescue/fip-nor.bin"
else
    echo "❌ 链路中断：ATF 构建未产出核心镜像 (BL2/FIP)"
    ls -R "$ATF_DIR/build/"
    exit 1
fi

# 5. OpenWrt 固件生成
cd "$OPENWRT_DIR"
echo "🛠️ 正在构建 OpenWrt 系统层..."
make -j$(nproc) V=s || exit 1

# 6. 最终导出审计
echo "🚚 正在执行全链路产物导出..."
BIN_DIR="$OPENWRT_DIR/bin/targets/mediatek/filogic"
find "$BIN_DIR" -type f \( -name "*sl_3000*" -o -name "*.itb" \) -exec cp -v {} "$OUTPUT_DIR/" \;

# 物理检查
if [ ! -f "$RESCUE_IMG" ]; then
    echo "❌ 最终审计失败：救砖镜像丢失！"
    exit 1
fi

echo "✅ 全链路溯源构建成功！"
