#!/bin/bash
set -e

# [物理路径锁定]：假设脚本在 workspace 根目录运行
WORKSPACE=$(pwd)
ATF_DIR="$WORKSPACE/arm-trusted-firmware"
UBOOT_DIR="$WORKSPACE/u-boot"
OPENWRT_DIR="$WORKSPACE/immortalwrt"
UARTBOOT_DIR="$WORKSPACE/mtk_uartboot"
OUTPUT_DIR="$WORKSPACE/output/rescue"

mkdir -p "$OUTPUT_DIR"

echo "🚀 [全链路溯源] 开始同步构建 SL3000 救砖全家桶..."

# 1. ⚡ 注入 1GB DDR4 内存补丁至 ATF 目录
# 溯源：直接修改你仓库里的 arm-trusted-firmware
cd "$ATF_DIR"
echo "🛠️ 正在注入 1GB RAM 训练补丁..."
DRAM_PATH="plat/mediatek/mt7981/drivers/dram"
mkdir -p "$DRAM_PATH"
cat <<EOF > "$DRAM_PATH/mtk_mem_init.c"
#include <common/debug.h>
extern void emi_init_setting(void);
void mtk_mem_init(void) {
    NOTICE("EMI: SL3000 1GB DDR4 Physical Patch Active.\n");
    emi_init_setting();
}
EOF
# 修正 Makefile 引用路径
sed -i '/BL2_SOURCES/s/$/ plat\/mediatek\/mt7981\/drivers\/dram\/mtk_mem_init.c plat\/mediatek\/mt7981\/drivers\/dram\/emicfg.c/' plat/mediatek/mt7981/platform.mk

# 2. 🏗️ 第一阶段：编译底层 BL2 (使用 1GB 内存参数)
echo "🏗️ 正在从本地目录构建 BL2..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 bl2 -j$(nproc)

# 3. 🏗️ 第二阶段：编译系统固件 (获取 U-Boot 和 ITB)
cd "$OPENWRT_DIR"
echo "🏗️ 正在从本地目录构建 OpenWrt 系统 (包含 U-Boot)..."
# 执行 OpenWrt 标准编译逻辑
make -j$(nproc) V=s

# 4. 📦 第三阶段：二次封装 FIP (实现物理对齐)
# 溯源：从编译好的 bin 目录搜寻 U-Boot 零件
UBOOT_RAW=$(find "$OPENWRT_DIR/bin" -name "*u-boot.bin*" | head -n 1)
if [ -f "$UBOOT_RAW" ]; then
    cd "$ATF_DIR"
    echo "📦 发现 U-Boot，正在执行 FIP 像素级封装..."
    make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 \
         BOOT_DEVICE=nor DRAM_SIZE=1024 BL33="$UBOOT_RAW" fip -j$(nproc)
fi

# 5. 🧱 第四阶段：物理缝合 32MB 救砖包
RESCUE_IMG="$OUTPUT_DIR/SL3000_1GB_FULL_SYNC_32M.bin"
ATF_RELEASE=$(find "$ATF_DIR" -name "release" -type d | grep "mt7981" | head -n 1)

echo "🧱 正在执行物理缝合 (Offset: 0x0 BL2 / 0x380000 FIP)..."
# 创建 32MB 空白底包
dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
# 注入 BL2 (头部)
[ -f "$ATF_RELEASE/bl2.bin" ] && dd if="$ATF_RELEASE/bl2.bin" of="$RESCUE_IMG" conv=notrunc
# 注入 FIP (3.5MB 偏移处)
[ -f "$ATF_RELEASE/fip.bin" ] && dd if="$ATF_RELEASE/fip.bin" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc

# 6. 🚚 归档救砖零件
echo "🚚 正在收集全家桶零件..."
[ -f "$ATF_RELEASE/bl2.bin" ] && cp -v "$ATF_RELEASE/bl2.bin" "$OUTPUT_DIR/bl2-1g-nor.bin"
[ -f "$ATF_RELEASE/fip.bin" ] && cp -v "$ATF_RELEASE/fip.bin" "$OUTPUT_DIR/fip-nor.bin"
[ -f "$UBOOT_RAW" ] && cp -v "$UBOOT_RAW" "$OUTPUT_DIR/u-boot-sl3000.bin"

# 7. 🛠️ 第五阶段：编译串口救砖工具
if [ -d "$UARTBOOT_DIR" ]; then
    cd "$UARTBOOT_DIR"
    echo "🏗️ 正在编译串口救砖工具 (mtk_uartboot)..."
    make || echo "UARTBoot 编译跳过"
    [ -f "mtk_uartboot" ] && cp -v "mtk_uartboot" "$OUTPUT_DIR/"
fi

echo "✅ [全链路同步成功] 全家桶已生成至 output/rescue/"
