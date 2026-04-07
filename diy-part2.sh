#!/bin/bash
set -e

# [物理路径定位]
WORKSPACE=$(pwd)
ATF_DIR="$WORKSPACE/source-repo/arm-trusted-firmware"
OPENWRT_DIR="$WORKSPACE/source-repo/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output/rescue"
mkdir -p "$OUTPUT_DIR"

# 1. ⚡ 注入 1GB DDR4 内存补丁 (解决链接错误)
cd "$ATF_DIR"
DRAM_PATH="plat/mediatek/mt7981/drivers/dram"
mkdir -p "$DRAM_PATH"
cat <<EOF > "$DRAM_PATH/mtk_mem_init.c"
#include <common/debug.h>
extern void emi_init_setting(void);
void mtk_mem_init(void) {
    NOTICE("EMI: SL3000 1GB DDR4 Patch Enabled.\n");
    emi_init_setting();
}
EOF
sed -i '/BL2_SOURCES/s/$/ plat\/mediatek\/mt7981\/drivers\/dram\/mtk_mem_init.c plat\/mediatek\/mt7981\/drivers\/dram\/emicfg.c/' plat/mediatek/mt7981/platform.mk

# 2. 🛠️ 编译第一阶段 (BL2)
echo "🏗️ 开始构建 BL2..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 BOOT_DEVICE=nor DRAM_SIZE=1024 bl2 -j$(nproc)

# 3. 🛠️ 编译第二阶段 (OpenWrt & U-Boot)
cd "$OPENWRT_DIR"
echo "🏗️ 开始构建 OpenWrt 系统..."
# 确保使用新的 .config
make -j$(nproc) V=s

# 4. 📦 自动化 FIP 封装 (将 U-Boot 喂给 ATF)
UBOOT_BIN=$(find "$OPENWRT_DIR/bin" -name "*u-boot.bin*" | head -n 1)
if [ -f "$UBOOT_BIN" ]; then
    cd "$ATF_DIR"
    echo "📦 发现 U-Boot，正在二次封装 FIP..."
    make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 BOOT_DEVICE=nor DRAM_SIZE=1024 BL33="$UBOOT_BIN" fip -j$(nproc)
fi

# 5. 🧱 物理缝合 32MB 终极救砖包
RESCUE_IMG="$OUTPUT_DIR/SL3000_1GB_RESCUE_32M.bin"
ATF_RELEASE=$(find "$ATF_DIR" -name "release" -type d | grep "mt7981" | head -n 1)

echo "🧱 执行像素级缝合..."
dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
# 注入 BL2 (0x0)
[ -f "$ATF_RELEASE/bl2.bin" ] && dd if="$ATF_RELEASE/bl2.bin" of="$RESCUE_IMG" conv=notrunc
# 注入 FIP (0x380000 / 3.5MB)
[ -f "$ATF_RELEASE/fip.bin" ] && dd if="$ATF_RELEASE/fip.bin" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc

# 6. 🚚 零件归仓
cp -v "$ATF_RELEASE/bl2.bin" "$OUTPUT_DIR/bl2-1g-nor.bin"
cp -v "$ATF_RELEASE/fip.bin" "$OUTPUT_DIR/fip-sl3000.bin"
cp -v "$UBOOT_BIN" "$OUTPUT_DIR/u-boot.bin"
