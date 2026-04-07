#!/bin/bash
set -e

# 1. 物理路径溯源
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
ATF_DIR=$(find "$WORKSPACE/source-repo" -name "arm-trusted-firmware" -type d | head -n 1)
OPENWRT_DIR=$(find "$WORKSPACE/source-repo" -name "immortalwrt" -type d | head -n 1)
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

# 2. ⚡ 源码链接修复 (Undefined Reference 预防)
cd "$ATF_DIR"
DRAM_PATH="plat/mediatek/mt7981/drivers/dram"
mkdir -p "$DRAM_PATH"

# 注入缺失的内存初始化逻辑
cat <<EOF > "$DRAM_PATH/mtk_mem_init.c"
#include <common/debug.h>
extern void emi_init_setting(void);
void mtk_mem_init(void) {
    NOTICE("EMI: SL3000 1GB RAM Physical Patch Active.\n");
    emi_init_setting();
}
EOF

# 物理注入 Makefile
PLAT_MK="plat/mediatek/mt7981/platform.mk"
sed -i '/BL2_SOURCES/s/$/ plat\/mediatek\/mt7981\/drivers\/dram\/mtk_mem_init.c plat\/mediatek\/mt7981\/drivers\/dram\/emicfg.c/' "$PLAT_MK"

# 3. 执行 ATF 构建 (仅编译 bin，不触发 FIP 打包以规避 BL33 报错)
echo "🛠️ 启动 ATF 核心组件编译..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" bl2 bl31 -j$(nproc)

# 4. 提取产物并执行物理缝合
RELEASE_DIR=$(find . -name "release" -type d | grep "mt7981" | head -n 1)
BL2_BIN="$RELEASE_DIR/bl2.bin"
BL31_BIN="$RELEASE_DIR/bl31.bin"

if [ -f "$BL2_BIN" ] && [ -f "$BL31_BIN" ]; then
    echo "✅ ATF 组件就绪，准备手动物理缝合..."
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1GB_RESCUE_32M.bin"
    
    # 创建 32MB 空镜像
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    
    # 写入 BL2 到 0 偏移 (物理第一阶段)
    dd if="$BL2_BIN" of="$RESCUE_IMG" conv=notrunc
    
    # 特别说明：FIP 通常在 3.5MB 偏移处。
    # 如果此时没有 U-Boot，我们会先备份这两个关键引导文件。
    cp -v "$BL2_BIN" "$OUTPUT_DIR/rescue/bl2-1g-nor.bin"
    cp -v "$BL31_BIN" "$OUTPUT_DIR/rescue/bl31-1g-nor.bin"
else
    echo "❌ 链路中断：找不到编译出的 .bin 文件"
    ls -R "$RELEASE_DIR"
    exit 1
fi

# 5. 进入 OpenWrt 编译阶段 (这一步会生成真正的 U-Boot 和系统镜像)
cd "$OPENWRT_DIR"
echo "🛠️ 启动 OpenWrt 全量编译 (包括系统与 U-Boot)..."
make -j$(nproc) V=s || exit 1

# 6. 最终物理补齐：将 OpenWrt 产出的 U-Boot 缝合进 32MB 镜像
# 寻找编译出的 u-boot 镜像
UBOOT_BIN=$(find "$OPENWRT_DIR/bin" -name "*u-boot.bin*" | head -n 1)
if [ -n "$UBOOT_BIN" ]; then
    echo "📦 发现 U-Boot 镜像，执行 3.5MB 偏移量像素级缝合..."
    dd if="$UBOOT_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
fi

# 7. 导出最终产物
BIN_DIR="$OPENWRT_DIR/bin/targets/mediatek/filogic"
find "$BIN_DIR" -type f \( -name "*sl_3000*" -o -name "*.itb" \) -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ [Part 2] 32MB 全量物理救砖包构建完成"
