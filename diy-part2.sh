#!/bin/bash
set -e

# 路径对齐
ATF_DIR="$GITHUB_WORKSPACE/source-repo/arm-trusted-firmware"
OUTPUT_DIR="$GITHUB_WORKSPACE/output"
mkdir -p "$OUTPUT_DIR"

echo "=== 开始 SL3000 底层源码像素级修复 ==="

# 1. 物理锁定 1024MB DDR4 (重写 mtk_mem_init.c)
cat > "$ATF_DIR/plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
extern void mtk_mem_init_real(void);
extern int mt7981_use_ddr4;
extern int mt7981_ddr_size_limit;
void mtk_mem_init(void) {
    mt7981_use_ddr4 = 1;
    mt7981_ddr_size_limit = 1024;
    NOTICE("EMI: SL3000-V2 1024MB-DDR4-LOCKED\n");
    mtk_mem_init_real();
}
EOF

# 2. 物理锁定 3.5MB FIP 偏移 (重写 bl2_dev_spi_nor.c)
cat > "$ATF_DIR/plat/mediatek/mt7981/bl2/bl2_dev_spi_nor.c" << 'EOF'
#include <stddef.h>
#include <stdint.h>
#include <boot_spi.h>
#define FIP_BASE 0x380000   // 物理对齐 3.5MB
#define FIP_SIZE 0x200000   // 扩容 2MB 窗口
uint32_t mtk_plat_get_qspi_src_clk(void) {
    mtk_spi_gpio_init(SPIM2);
    return CB_MPLL_D2;
}
void mtk_plat_fip_location(uintptr_t *fip_off, size_t *fip_size) {
    *fip_off = FIP_BASE;
    *fip_size = FIP_SIZE;
}
EOF

# 3. 修复 ATF 头文件引用错误
cat > "$ATF_DIR/plat/mediatek/mt7981/bl2/bl2_plat_init.c" << 'EOF'
#include <common/debug.h>
#include <lib/mmio.h>
#include <platform_def.h>
#include <mt7981_gpio.h>
#include <pll.h>
#include <timer.h>
#include <emi.h>
#include <mtk_wdt.h>
struct initcall { void (*func)(void); };
#define INITCALL(_func) { .func = _func }
extern void mtk_mem_init(void);
static void arm_timer_init(void) { write_cntfrq_el0(ARM_TIMER_CLOCK_RATE); }
void bl2_el3_plat_arch_setup(void) {}
bool plat_is_my_cpu_primary(void) { return true; }
const struct initcall bl2_initcalls[] = {
	INITCALL(mtk_timer_init), INITCALL(arm_timer_init), INITCALL(mtk_wdt_init),
	INITCALL(mtk_pin_init), INITCALL(mt7981_set_default_pinmux),
	INITCALL(mtk_mem_init), INITCALL(NULL)
};
EOF

# 4. 编译 ATF 并执行缝合
cd "$ATF_DIR"
sed -i '/PLAT_INCLUDES/ s|$| -Iplat/mediatek/mt7981/include -Iplat/mediatek/common/include|' plat/mediatek/mt7981/platform.mk

# 编译 NOR 版本 (救砖专用)
make PLAT=mt7981 BOARD=sl3000 BOOT_DEVICE=nor DRAM_SIZE=1024 all

# 提取并缝合
BL2=$(find build/mt7981/release/ -name "bl2.img" | head -n 1)
FIP=$(find build/mt7981/release/ -name "fip.bin" | head -n 1)

if [ -f "$BL2" ] && [ -f "$FIP" ]; then
    echo "=== 正在缝合 32MB 救砖固件 ==="
    RESCUE_IMG="$OUTPUT_DIR/SL3000_1G_RESCUE_32M.bin"
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    dd if="$BL2" of="$RESCUE_IMG" conv=notrunc
    dd if="$FIP" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    echo "✅ 救砖固件生成成功: $RESCUE_IMG"
else
    echo "❌ 关键产物缺失，请检查 ATF 编译日志"
    exit 1
fi
