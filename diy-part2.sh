#!/bin/bash
set -e

# 1. 物理路径定义
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
ATF_DIR=$(find "$WORKSPACE/source-repo" -name "arm-trusted-firmware" -type d | head -n 1)
OPENWRT_DIR=$(find "$WORKSPACE/source-repo" -name "immortalwrt" -type d | head -n 1)
OUTPUT_DIR="$WORKSPACE/output"
RESCUE_DIR="$OUTPUT_DIR/rescue"

mkdir -p "$RESCUE_DIR"

# 2. ⚡ 物理注入 DDR4 1024M 补丁
cd "$ATF_DIR"
DRAM_PATH="plat/mediatek/mt7981/drivers/dram"
mkdir -p "$DRAM_PATH"

cat <<EOF > "$DRAM_PATH/mtk_mem_init.c"
#include <common/debug.h>
extern void emi_init_setting(void);
void mtk_mem_init(void) {
    NOTICE("EMI: SL3000 1GB RAM Patch Active.\n");
    emi_init_setting();
}
EOF

# 物理修改 Makefile
PLAT_MK="plat/mediatek/mt7981/platform.mk"
sed -i '/BL2_SOURCES/s/$/ plat\/mediatek\/mt7981\/drivers\/dram\/mtk_mem_init.c plat\/mediatek\/mt7981\/drivers\/dram\/emicfg.c/' "$PLAT_MK"

# 3. 🛠️ 阶段一：原子组件编译 (BL2/BL31)
echo "🛠️ 正在生成引导组件..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" bl2 bl31 -j$(nproc)

# 4. 🛠️ 阶段二：系统全量编译 (获取 U-Boot)
cd "$OPENWRT_DIR"
echo "🛠️ 正在编译 OpenWrt (全家桶核心)..."
make -j$(nproc) V=s || exit 1

# 5. 🛠️ 阶段三：全家桶零件“地毯式”搜寻与打包
echo "🔍 正在搜寻全家桶零件..."

# 搜索 U-Boot
UBOOT_RAW=$(find "$OPENWRT_DIR/bin" -name "*u-boot.bin*" | head -n 1)
[ -f "$UBOOT_RAW" ] && cp -v "$UBOOT_RAW" "$RESCUE_DIR/u-boot-sl3000.bin"

# 回到 ATF 目录打包 FIP
if [ -f "$UBOOT_RAW" ]; then
    cd "$ATF_DIR"
    echo "📦 发现 U-Boot，正在封装 FIP 零件..."
    make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
         BOOT_DEVICE=nor DRAM_SIZE=1024 BL33="$UBOOT_RAW" fip -j$(nproc)
fi

# 搜寻 ATF 产物
ATF_RELEASE=$(find "$ATF_DIR" -name "release" -type d | grep "mt7981" | head -n 1)
cp -v "$ATF_RELEASE/bl2.bin" "$RESCUE_DIR/bl2-1g-nor.bin" || true
cp -v "$ATF_RELEASE/bl31.bin" "$RESCUE_DIR/bl31-1g-nor.bin" || true
cp -v "$ATF_RELEASE/fip.bin" "$RESCUE_DIR/fip-nor.bin" || true

# 6. 🛠️ 阶段四：物理缝合 32MB 全量救砖包
FINAL_RESCUE="$RESCUE_DIR/SL3000_FULL_RESCUE_32M.bin"
echo "🏗️ 正在缝合终极救砖包..."
dd if=/dev/zero of="$FINAL_RESCUE" bs=1M count=32
# 0 地址注入 BL2
dd if="$ATF_RELEASE/bl2.bin" of="$FINAL_RESCUE" conv=notrunc
# 3.5MB 注入 FIP (含 BL31 和 U-Boot)
if [ -f "$ATF_RELEASE/fip.bin" ]; then
    dd if="$ATF_RELEASE/fip.bin" of="$FINAL_RESCUE" bs=1k seek=3584 conv=notrunc
elif [ -f "$UBOOT_RAW" ]; then
    dd if="$UBOOT_RAW" of="$FINAL_RESCUE" bs=1k seek=3584 conv=notrunc
fi

# 7. 🚀 整理所有导出产物
echo "🚚 正在导出所有镜像..."
BIN_DIR="$OPENWRT_DIR/bin/targets/mediatek/filogic"
find "$BIN_DIR" -type f \( -name "*sl_3000*" -o -name "*.itb" \) -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ [救砖全家桶] 所有零件已归仓。"
