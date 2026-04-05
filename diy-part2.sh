#!/bin/bash
set -e

# 1. 路径自动定位
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
SOURCE_REPO="$WORKSPACE/source-repo"
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

echo "=== 🛠️ 开始 SL3000 底层源码物理修复 (ATF) ==="

# --- [1. 锁定 1024MB 内存与 3.5MB 偏移] ---
# 强制重写核心驱动文件，确保 1GB 颗粒正常工作
cat > "$ATF_DIR/plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
extern void mtk_mem_init_real(void);
extern int mt7981_use_ddr4;
extern int mt7981_ddr_size_limit;
void mtk_mem_init(void) {
    mt7981_use_ddr4 = 1;          // 强制使用 DDR4
    mt7981_ddr_size_limit = 1024; // 锁定 1024MB
    NOTICE("EMI: SL3000-V3 1024MB-DDR4-LOCKED\n");
    mtk_mem_init_real();
}
EOF

# 锁定 SPI-NOR 寻址偏移 (3.5MB)
cat > "$ATF_DIR/plat/mediatek/mt7981/bl2/bl2_dev_spi_nor.c" << 'EOF'
#include <stddef.h>
#include <stdint.h>
#include <boot_spi.h>
#define FIP_BASE 0x380000   // 物理对齐 3.5MB
#define FIP_SIZE 0x200000   // 2MB FIP 窗口
uint32_t mtk_plat_get_qspi_src_clk(void) {
    mtk_spi_gpio_init(SPIM2);
    return CB_MPLL_D2;
}
void mtk_plat_fip_location(uintptr_t *fip_off, size_t *fip_size) {
    *fip_off = FIP_BASE;
    *fip_size = FIP_SIZE;
}
EOF

# --- [2. 修复 Makefile 包含路径 (解决报错关键)] ---
cd "$ATF_DIR"
# 安全修改：仅在未包含时追加，且避免在文件头部产生乱码
PLAT_MK="plat/mediatek/mt7981/platform.mk"
EXTRA_INC="-Iplat/mediatek/mt7981/include -Iplat/mediatek/common/include"

if ! grep -q "EXTRA_SL3000_INC" "$PLAT_MK"; then
    echo "" >> "$PLAT_MK"
    echo "EXTRA_SL3000_INC := $EXTRA_INC" >> "$PLAT_MK"
    echo "PLAT_INCLUDES += \$(EXTRA_SL3000_INC)" >> "$PLAT_MK"
    echo "✅ Makefile 路径补丁已安全挂载"
fi

# --- [3. 编译 ATF 救砖引导] ---
echo "正在编译 ATF (BOOT_DEVICE=nor)..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 BOOT_DEVICE=nor DRAM_SIZE=1024 all

# 提取并缝合 32MB 实心包
BL2=$(find build/mt7981/release/ -name "bl2.img" | head -n 1)
FIP=$(find build/mt7981/release/ -name "fip.bin" | head -n 1)

if [ -f "$BL2" ] && [ -f "$FIP" ]; then
    echo "=== 正在缝合 32MB 救砖固件 ==="
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin"
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    dd if="$BL2" of="$RESCUE_IMG" conv=notrunc
    dd if="$FIP" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    echo "✅ 救砖固件已生成: $RESCUE_IMG"
else
    echo "❌ 编译产物缺失，请检查 ATF 编译日志！"
    exit 1
fi

# --- [4. 编译 ImmortalWrt 系统固件] ---
echo "=== 📦 开始编译 ImmortalWrt 系统固件 ==="
cd "$OPENWRT_DIR"
# 确保权限
chmod +x scripts/feeds
# 注入 .config 并刷新
make defconfig
# 开始编译 (根据内存情况建议先尝试 -j$(nproc))
make -j$(nproc) V=s || exit 1

# 提取固件
find bin/targets/ -type f -name "*sysupgrade*" -exec cp -v {} "$OUTPUT_DIR/" \;
echo "✅ 全部构建任务成功结束"
