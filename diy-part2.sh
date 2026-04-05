#!/bin/bash
set -e

# 1. 路径自动定位
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
SOURCE_REPO="$WORKSPACE/source-repo"

# 定义 4 个核心子目录路径
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
UBOOT_DIR="$SOURCE_REPO/u-boot"
UARTBOOT_DIR="$SOURCE_REPO/mtk_uartboot"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

echo "=== 🛠️ 开始 SL3000 全路径物理对齐 (V6) ==="

# --- [1. 物理打通头文件断层 (解决 cc1 报错)] ---
echo "正在执行物理补齐: $ATF_DIR"
# 强行创建 ATF 预期的目录结构
mkdir -p "$ATF_DIR/plat/mediatek/mt7981/include"
mkdir -p "$ATF_DIR/plat/mediatek/common/include"

# 关键：从整个 source-repo 中抓取所有 mediatek 相关的头文件并同步到 ATF 目录
# 这样无论头文件是在 u-boot 还是在其他地方，ATF 都能看到它们
find "$SOURCE_REPO" -path "*/mediatek/common/include/*" -type f -exec cp -v {} "$ATF_DIR/plat/mediatek/common/include/" \; 2>/dev/null || true

# --- [2. 锁定 1024MB 内存与 3.5MB 偏移] ---
# 重写 ATF 内存驱动 (锁定 1GB DDR4)
cat > "$ATF_DIR/plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
extern void mtk_mem_init_real(void);
extern int mt7981_use_ddr4;
extern int mt7981_ddr_size_limit;
void mtk_mem_init(void) {
    mt7981_use_ddr4 = 1;          
    mt7981_ddr_size_limit = 1024; 
    NOTICE("EMI: SL3000-V6 1024MB-DDR4-LOCKED\n");
    mtk_mem_init_real();
}
EOF

# 重写 SPI-NOR 寻址逻辑 (对齐 3.5MB)
cat > "$ATF_DIR/plat/mediatek/mt7981/bl2/bl2_dev_spi_nor.c" << 'EOF'
#include <stddef.h>
#include <stdint.h>
#include <boot_spi.h>
#define FIP_BASE 0x380000   // 3.5MB 对齐
#define FIP_SIZE 0x200000   // 2MB 窗口
uint32_t mtk_plat_get_qspi_src_clk(void) {
    mtk_spi_gpio_init(SPIM2);
    return CB_MPLL_D2;
}
void mtk_plat_fip_location(uintptr_t *fip_off, size_t *fip_size) {
    *fip_off = FIP_BASE;
    *fip_size = FIP_SIZE;
}
EOF

# --- [3. 编译 ATF 救砖包] ---
cd "$ATF_DIR"
# 清理并强制开启“忽略缺失目录”警告
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
echo "正在执行 ATF 强制构建..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all

# 提取产物并缝合 32MB 实心包
BL2=$(find build/mt7981/release/ -name "bl2.img" | head -n 1)
FIP=$(find build/mt7981/release/ -name "fip.bin" | head -n 1)

if [ -f "$BL2" ] && [ -f "$FIP" ]; then
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin"
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    dd if="$BL2" of="$RESCUE_IMG" conv=notrunc
    dd if="$FIP" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    echo "✅ 32MB 救砖固件已生成: $RESCUE_IMG"
else
    echo "❌ ATF 编译可能未完全成功，检查日志"
    exit 1
fi

# --- [4. 打包 mtk_uartboot 工具] ---
if [ -d "$UARTBOOT_DIR" ]; then
    echo "正在打包串口救砖工具..."
    tar -czf "$OUTPUT_DIR/mtk_uartboot.tar.gz" -C "$SOURCE_REPO" mtk_uartboot
fi

# --- [5. 编译 ImmortalWrt 系统固件] ---
echo "=== 📦 开始编译 ImmortalWrt 系统固件 ==="
cd "$OPENWRT_DIR"
# 自动注入并执行 defconfig
make defconfig
make -j$(nproc) V=s || exit 1

# 提取最终 sysupgrade 产物
find bin/targets/ -type f -name "*sysupgrade*" -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ 全部构建任务成功结束"
