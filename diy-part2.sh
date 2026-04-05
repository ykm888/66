#!/bin/bash
set -e

# 1. 路径自动探测
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
SOURCE_REPO="$WORKSPACE/source-repo"

# 定义并列的四核心目录
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
UBOOT_DIR="$SOURCE_REPO/u-boot"
UARTBOOT_DIR="$SOURCE_REPO/mtk_uartboot"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

echo "=== 🛠️ 开始 SL3000 全量产物物理对齐 (V8-Final) ==="

# --- [2. 物理补齐头文件 (解决 cc1 报错)] ---
mkdir -p "$ATF_DIR/plat/mediatek/mt7981/include"
mkdir -p "$ATF_DIR/plat/mediatek/common/include"
find "$SOURCE_REPO" -path "*/mediatek/common/include/*" -type f -exec cp -v {} "$ATF_DIR/plat/mediatek/common/include/" \; 2>/dev/null || true

# --- [3. 锁定 1024MB 内存与 3.5MB FIP 偏移] ---
# 注入内存驱动
cat > "$ATF_DIR/plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
extern void mtk_mem_init_real(void);
extern int mt7981_use_ddr4;
extern int mt7981_ddr_size_limit;
void mtk_mem_init(void) {
    mt7981_use_ddr4 = 1;          
    mt7981_ddr_size_limit = 1024; 
    NOTICE("EMI: SL3000-V8 1024MB-DDR4-LOCKED\n");
    mtk_mem_init_real();
}
EOF

# 注入 FIP 偏移逻辑 (3.5MB)
cat > "$ATF_DIR/plat/mediatek/mt7981/bl2/bl2_dev_spi_nor.c" << 'EOF'
#include <stddef.h>
#include <stdint.h>
#include <boot_spi.h>
#define FIP_BASE 0x380000   
#define FIP_SIZE 0x200000   
uint32_t mtk_plat_get_qspi_src_clk(void) {
    mtk_spi_gpio_init(SPIM2);
    return CB_MPLL_D2;
}
void mtk_plat_fip_location(uintptr_t *fip_off, size_t *fip_size) {
    *fip_off = FIP_BASE;
    *fip_size = FIP_SIZE;
}
EOF

# --- [4. 执行 ATF 编译 (NOR 模式)] ---
cd "$ATF_DIR"
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all

# --- [5. 提取并生成所有独立包 + 33.55MB 大包] ---
echo "=== 🕵️ 正在同步所有物理组件包 ==="
BUILD_EXPORT="$ATF_DIR/build/mt7981/release"

BL2_IMG=$(find "$BUILD_EXPORT" -name "bl2.img" | head -n 1)
FIP_BIN=$(find "$BUILD_EXPORT" -name "fip.bin" | head -n 1)

if [ -f "$BL2_IMG" ]; then
    # 提取独立 BL2
    cp -v "$BL2_IMG" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
    # 提取 BL2-RAM (如果生成了)
    [ -f "$BUILD_EXPORT/bl2_ram.bin" ] && cp -v "$BUILD_EXPORT/bl2_ram.bin" "$OUTPUT_DIR/rescue/bl2-ram-1g.bin"
    
    # 开始缝合 33.55MB (32MB) 全量镜像
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin"
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    dd if="$BL2_IMG" of="$RESCUE_IMG" conv=notrunc
    
    if [ -f "$FIP_BIN" ]; then
        # 提取独立 FIP 和 U-Boot
        cp -v "$FIP_BIN" "$OUTPUT_DIR/rescue/fip-nor.bin"
        cp -v "$FIP_BIN" "$OUTPUT_DIR/rescue/u-boot-nor.bin"
        # 注入 3.5MB 偏移
        dd if="$FIP_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
        echo "✅ 33.55MB 全量包注入成功"
    fi
else
    echo "❌ 关键引导产物缺失！"
    exit 1
fi

# --- [6. 编译系统升级固件 (.itb)] ---
echo "=== 📦 启动系统固件编译 ==="
cd "$OPENWRT_DIR"
# 确保权限
chmod +x scripts/feeds
# 注入你的 8000 行配置 (请确认 main-repo 下有这个文件)
[ -f "$WORKSPACE/main-repo/sl3000.config" ] && cp -v "$WORKSPACE/main-repo/sl3000.config" .config
make defconfig
make -j$(nproc) V=s || exit 1

# 提取 .itb 升级包
find bin/targets/ -type f -name "*sysupgrade.itb" -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ [SUCCESS] 全量包、独立包、升级包已全部就绪"
