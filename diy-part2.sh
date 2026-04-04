#!/bin/bash
# 2版：全链路溯源修复脚本
# 原则：set -e 熔断，确保物理产物生成

set -e

# 1. 路径定义
TOP_DIR="$GITHUB_WORKSPACE"
CONFIG_DIR="$TOP_DIR/main"
SOURCE_DIR="$TOP_DIR/immortalwrt-build/source-repo"
OUTPUT_DIR="$TOP_DIR/output"

echo "=== 正在注入 SL3000 硬件定义 (DTS & MK) ==="
DTS_PATH="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_PATH"
[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && cp -v "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$DTS_PATH/"

# 修正 MK 重复定义风险
sed -i '/Device\/sl_3000-emmc/,/endef/d' target/linux/mediatek/image/filogic.mk
cat "$CONFIG_DIR/mt7981_sl3000.mk" >> target/linux/mediatek/image/filogic.mk

# 2. 强制 Patch ATF (锁定 1024MB DDR4)
echo "=== 物理 Patch：锁定 1GB 内存初始化 ==="
MEM_INIT="$SOURCE_DIR/arm-trusted-firmware/plat/mediatek/mt7981/drivers/dram/mt7981_mem_init.c"
if [ -f "$MEM_INIT" ]; then
    cat > "$MEM_INIT" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
void mtk_mem_init(void) {
    extern int mt7981_use_ddr4;
    extern int mt7981_ddr_size_limit;
    mt7981_use_ddr4 = 1;         // 强制 DDR4
    mt7981_ddr_size_limit = 1024; // 锁定 1024MB
    NOTICE("EMI: SL3000-1GB-DDR4-FIXED-BY-GEMINI\n");
}
EOF
fi

# 3. 交叉编译底层产物
export CROSS_COMPILE=aarch64-linux-gnu-

echo "=== 编译 ATF (BL2) ==="
cd "$SOURCE_DIR/arm-trusted-firmware"
make PLAT=mt7981 BOARD=sl3000-nor-1024M all
cp build/mt7981/release/bl2.img "$OUTPUT_DIR/bl2-nor.bin"

echo "=== 编译 U-Boot (FIP) ==="
cd "$SOURCE_DIR/u-boot"
# 优先检查自定义配置
if [ -f "configs/mt7981_sl3000_defconfig" ]; then
    make mt7981_sl3000_defconfig
else
    make mt7981_spim_nor_rfb_defconfig
fi
make -j$(nproc)
cp fip.bin "$OUTPUT_DIR/fip-nor.bin"

echo "✅ 底层固件编译成功，产物已就绪"
