#!/bin/bash
set -e

# 1. 路径自动对齐
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
SOURCE_REPO="$WORKSPACE/source-repo"
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

echo "=== [Part 2] 开始物理修复 ATF 与 1GB 内存初始化 ==="

# 2. 物理注入 1024M 内存初始化补丁 (mtk_mem_init.c)
MEM_INIT_FILE="$ATF_DIR/plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c"
if [ -f "$MEM_INIT_FILE" ]; then
    echo "🔧 正在修改 mtk_mem_init.c 锁定 1024M 训练..."
    sed -i 's/DRAM_SIZE_512M/DRAM_SIZE_1024M/g' "$MEM_INIT_FILE"
    sed -i 's/0x20000000/0x40000000/g' "$MEM_INIT_FILE"
fi

# 3. 锁定 SPI-NOR 启动与 FIP 偏移 (bl2_dev_spi_nor.c)
NOR_DEV_FILE="$ATF_DIR/plat/mediatek/mt7981/drivers/spi_nor/bl2_dev_spi_nor.c"
if [ -f "$NOR_DEV_FILE" ]; then
    echo "🔧 正在修改 bl2_dev_spi_nor.c 锁定 FIP 偏移为 3.5MB (0x380000)..."
    sed -i 's/0x100000/0x380000/g' "$NOR_DEV_FILE"
    sed -i 's/0x200000/0x380000/g' "$NOR_DEV_FILE"
fi

# 4. 编译 ATF (MT7981 + 1GB RAM + SPI-NOR)
echo "🏗️ 正在编译定制版 ATF 引导程序..."
cd "$ATF_DIR"
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all

# 5. 提取并缝合 32MB 全量救砖镜像
BUILD_EXPORT="$ATF_DIR/build/mt7981/release"
BL2_IMG=$(find "$BUILD_EXPORT" -name "bl2.img" | head -n 1)
FIP_BIN=$(find "$BUILD_EXPORT" -name "fip.bin" | head -n 1)

if [ -f "$BL2_IMG" ] && [ -f "$FIP_BIN" ]; then
    echo "📦 正在缝合 32MB 像素级物理镜像..."
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin"
    # 创建 32MB 空文件
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    # 写入 BL2 (从 0 偏移开始)
    dd if="$BL2_IMG" of="$RESCUE_IMG" conv=notrunc
    # 写入 FIP (对齐到 3584k 即 3.5MB 偏移)
    dd if="$FIP_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    
    cp -v "$BL2_IMG" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
    cp -v "$FIP_BIN" "$OUTPUT_DIR/rescue/fip-nor.bin"
fi

# 6. 启动 OpenWrt 系统构建 (确保架构锁定)
echo "=== ⚙️ 启动系统级编译 (ARM64) ==="
cd "$OPENWRT_DIR"

# 再次确认架构锁定，防止编译为 x86
[ -f ".config" ] || cp -v "$WORKSPACE/main-repo/888/sl3000.config" .config
make defconfig

# 强制多线程编译
make -j$(nproc) V=s || make -j1 V=s

# 提取最终升级包 (.itb)
find bin/targets/mediatek/filogic/ -type f -name "*sl_3000-spi-nor*sysupgrade.itb" -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ [Part 2] 所有产物已就绪于 output/ 目录"
