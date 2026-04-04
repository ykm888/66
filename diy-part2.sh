#!/bin/bash
# 2版修正：全链路自动溯源路径对齐脚本
# 原则：物理锁定 1024MB 内存，自动探测配置目录

set -e

# 1. 物理路径自动探测
TOP_DIR="$GITHUB_WORKSPACE"
echo "=== 正在全链路溯源配置文件 ==="

# 动态寻找包含 mt7981_sl3000.mk 的目录
REAL_CONFIG_DIR=$(find "$TOP_DIR/main" -name "mt7981_sl3000.mk" -exec dirname {} + | head -n 1)

if [ -z "$REAL_CONFIG_DIR" ]; then
    echo "❌ 溯源失败：在 main 仓库中未找到 mt7981_sl3000.mk"
    echo "当前目录结构如下："
    ls -R "$TOP_DIR/main"
    exit 1
fi

echo "✅ 成功锁定配置路径: $REAL_CONFIG_DIR"

SOURCE_DIR="$TOP_DIR/immortalwrt-build/source-repo"
OUTPUT_DIR="$TOP_DIR/output"
mkdir -p "$OUTPUT_DIR"

# 2. 注入硬件定义 (DTS & MK)
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_DEST"

# 复制 DTS (优先匹配 emmc 版本)
cp -v "$REAL_CONFIG_DIR"/*sl3000*.dts "$DTS_DEST/" || echo "⚠️ 未找到匹配的 DTS 文件"

# 注入 MK 设备定义 (先清理冲突再追加)
sed -i '/Device\/sl_3000-emmc/,/endef/d' target/linux/mediatek/image/filogic.mk
cat "$REAL_CONFIG_DIR/mt7981_sl3000.mk" >> target/linux/mediatek/image/filogic.mk

# 3. 物理 Patch：锁定 1024MB DDR4 内存初始化
echo "=== 正在执行 EMI 物理锁定 Patch ==="
ATF_DIR="$SOURCE_DIR/arm-trusted-firmware"
MEM_FILE="$ATF_DIR/plat/mediatek/mt7981/drivers/dram/mt7981_mem_init.c"

if [ -f "$MEM_FILE" ]; then
    cat > "$MEM_FILE" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
void mtk_mem_init(void) {
    extern int mt7981_use_ddr4;
    extern int mt7981_ddr_size_limit;
    mt7981_use_ddr4 = 1;         // 强制开启 DDR4 训练
    mt7981_ddr_size_limit = 1024; // 锁定 1024MB 内存识别
    NOTICE("EMI: SL3000-1024M-DDR4-CUSTOM-FIXED\n");
}
EOF
    echo "✅ ATF 内存补丁注入成功"
fi

# 4. 交叉编译底层引导
export CROSS_COMPILE=aarch64-linux-gnu-

echo "=== 编译 ATF (BL2) ==="
cd "$ATF_DIR"
# 注意：BOARD 名字需对应你源码中的定义，通常为 rfb 或自定义名
make PLAT=mt7981 BOARD=sl3000-nor-1024M all || make PLAT=mt7981 BOARD=mt7981-spim-nor-rfb all
cp build/mt7981/release/bl2.img "$OUTPUT_DIR/bl2-nor.bin"

echo "=== 编译 U-Boot (FIP) ==="
cd "$SOURCE_DIR/u-boot"
if [ -f "configs/mt7981_sl3000_defconfig" ]; then
    make mt7981_sl3000_defconfig
else
    make mt7981_spim_nor_rfb_defconfig
fi
make -j$(nproc)
cp fip.bin "$OUTPUT_DIR/fip-nor.bin"

echo "✅ diy-part2.sh: 底层物理产物已就绪"
