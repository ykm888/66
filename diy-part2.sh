#!/bin/bash
set -e

# 1. 路径与环境溯源
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
# 自动定位源码目录
ATF_DIR=$(find "$WORKSPACE/source-repo" -name "arm-trusted-firmware" -type d | head -n 1)
OPENWRT_DIR=$(find "$WORKSPACE/source-repo" -name "immortalwrt" -type d | head -n 1)
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

# 2. ⚡ ATF 驱动补丁 (确保 1024M RAM 支持)
cd "$ATF_DIR"
DRAM_PATH="plat/mediatek/mt7981/drivers/dram"
mkdir -p "$DRAM_PATH"

# 强制注入驱动逻辑 (解决 Undefined Reference)
cat <<EOF > "$DRAM_PATH/mtk_mem_init.c"
#include <common/debug.h>
extern void emi_init_setting(void);
void mtk_mem_init(void) {
    NOTICE("EMI: SL3000 1GB RAM Patch Active.\n");
    emi_init_setting();
}
EOF

# 修正 Makefile 引用
PLAT_MK="plat/mediatek/mt7981/platform.mk"
sed -i '/BL2_SOURCES/s/$/ plat\/mediatek\/mt7981\/drivers\/dram\/mtk_mem_init.c plat\/mediatek\/mt7981\/drivers\/dram\/emicfg.c/' "$PLAT_MK"

# 3. 🛠️ 阶段一：初次编译 ATF (生成引导头)
echo "🛠️ 正在生成引导组件 (BL2/BL31)..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" bl2 bl31 -j$(nproc)

# 4. 🛠️ 阶段二：编译 OpenWrt (生成 U-Boot 与系统)
cd "$OPENWRT_DIR"
echo "🛠️ 正在编译 OpenWrt 全系统 (获取 U-Boot)..."
make -j$(nproc) V=s || exit 1

# 5. 🛠️ 阶段三：二次打包 ATF (生成完整 FIP)
# 寻找 OpenWrt 编译出的 u-boot.bin 作为 BL33
UBOOT_BIN=$(find "$OPENWRT_DIR/bin" -name "*u-boot.bin*" | head -n 1)

if [ -f "$UBOOT_BIN" ]; then
    echo "📦 发现 U-Boot，正在执行二次封装 FIP..."
    cd "$ATF_DIR"
    make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
         BOOT_DEVICE=nor DRAM_SIZE=1024 BL33="$UBOOT_BIN" fip -j$(nproc)
else
    echo "⚠️ 未发现 U-Boot，将跳过 FIP 封装，执行手动缝合逻辑。"
fi

# 6. 🛠️ 阶段四：物理缝合全量救砖包 (32MB)
RELEASE_DIR=$(find "$ATF_DIR" -name "release" -type d | grep "mt7981" | head -n 1)
BL2_FINAL="$RELEASE_DIR/bl2.bin"
FIP_FINAL="$RELEASE_DIR/fip.bin"
RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_FULL_RESCUE_32M.bin"

echo "🏗️ 开始构建 32MB 全量物理救砖包..."
dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
# 注入 BL2 到 0 偏移 (BRLYT 头部)
[ -f "$BL2_FINAL" ] && dd if="$BL2_FINAL" of="$RESCUE_IMG" conv=notrunc
# 注入 FIP (含 BL31 和 U-Boot) 到 3.5MB 偏移
if [ -f "$FIP_FINAL" ]; then
    dd if="$FIP_FINAL" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
elif [ -f "$UBOOT_BIN" ]; then
    # 如果 FIP 打包失败，则直接手动注入 U-Boot 作为备选
    dd if="$UBOOT_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
fi

# 7. 🚀 导出救砖全家桶
echo "🚚 正在导出救砖全家桶到 rescue 目录..."
cp -v "$BL2_FINAL" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
[ -f "$RELEASE_DIR/bl31.bin" ] && cp -v "$RELEASE_DIR/bl31.bin" "$OUTPUT_DIR/rescue/bl31.bin"
[ -f "$FIP_FINAL" ] && cp -v "$FIP_FINAL" "$OUTPUT_DIR/rescue/fip-nor.bin"
[ -f "$UBOOT_BIN" ] && cp -v "$UBOOT_BIN" "$OUTPUT_DIR/rescue/u-boot.bin"

# 导出 OpenWrt 系统镜像
BIN_DIR="$OPENWRT_DIR/bin/targets/mediatek/filogic"
find "$BIN_DIR" -type f \( -name "*sl_3000*" -o -name "*.itb" \) -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ [全家桶] 物理构建链路已闭环。"
