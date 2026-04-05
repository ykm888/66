#!/bin/bash
# =================================================================
# 脚本名称：diy-part2.sh
# 适用硬件：SL3000 (1GB DDR4 / 32MB SPI-NOR)
# 核心逻辑：物理修复 ATF 源码，锁定内存与偏移，执行 32MB 缝合
# =================================================================

set -e

# 1. 路径自动探测
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
SOURCE_REPO="$WORKSPACE/source-repo"

# 定义并列的四核心目录
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
UBOOT_DIR="$SOURCE_REPO/u-boot"
UARTBOOT_DIR="$SOURCE_REPO/mtk_uartboot"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p "$OUTPUT_DIR/rescue"

echo "=== 🛠️ 开始 SL3000 底层源码物理修复 (V7-Final) ==="

# --- [2. 物理补齐头文件与目录 (解决 cc1 报错)] ---
echo "正在执行路径物理对齐与头文件同步..."
mkdir -p "$ATF_DIR/plat/mediatek/mt7981/include"
mkdir -p "$ATF_DIR/plat/mediatek/common/include"

# 从整个 source-repo 搜寻并拷贝缺失的 common 头文件
find "$SOURCE_REPO" -path "*/mediatek/common/include/*" -type f -exec cp -v {} "$ATF_DIR/plat/mediatek/common/include/" \; 2>/dev/null || true

# --- [3. 锁定 1024MB 内存 (重写 mtk_mem_init.c)] ---
cat > "$ATF_DIR/plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
extern void mtk_mem_init_real(void);
extern int mt7981_use_ddr4;
extern int mt7981_ddr_size_limit;
void mtk_mem_init(void) {
    mt7981_use_ddr4 = 1;          // 强制开启 DDR4 模式
    mt7981_ddr_size_limit = 1024; // 强制锁定 1024MB
    NOTICE("EMI: SL3000-V7 1024MB-DDR4-LOCKED\n");
    mtk_mem_init_real();
}
EOF

# --- [4. 锁定 3.5MB FIP 偏移 (重写 bl2_dev_spi_nor.c)] ---
cat > "$ATF_DIR/plat/mediatek/mt7981/bl2/bl2_dev_spi_nor.c" << 'EOF'
#include <stddef.h>
#include <stdint.h>
#include <boot_spi.h>
#define FIP_BASE 0x380000   // 物理对齐 3.5MB (十六进制)
#define FIP_SIZE 0x200000   // 2MB FIP 空间
uint32_t mtk_plat_get_qspi_src_clk(void) {
    mtk_spi_gpio_init(SPIM2);
    return CB_MPLL_D2;
}
void mtk_plat_fip_location(uintptr_t *fip_off, size_t *fip_size) {
    *fip_off = FIP_BASE;
    *fip_size = FIP_SIZE;
}
EOF

# --- [5. 编译 ATF 救砖引导] ---
cd "$ATF_DIR"
# 安全清理，防止残留导致 Makefile 报错
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 clean

echo "正在执行 ATF 强制构建 (NOR 模式)..."
# 加入 CFLAGS 容错，防止路径警告中断编译
make CROSS_COMPILE=aarch64-linux-gnu- \
     PLAT=mt7981 BOARD=sl3000 \
     BOOT_DEVICE=nor DRAM_SIZE=1024 \
     CFLAGS="-Wno-error=missing-include-dirs" all

# --- [6. 提取产物并执行 32MB 像素级缝合] ---
echo "=== 🕵️ 扫描并缝合救砖镜像 ==="
BUILD_EXPORT="$ATF_DIR/build/mt7981/release"

# 动态搜寻 BL2 和 FIP (兼容不同 Makefile 输出)
BL2_IMG=$(find "$BUILD_EXPORT" -name "bl2.img" | head -n 1)
FIP_BIN=$(find "$BUILD_EXPORT" -name "fip.bin" | head -n 1)

if [ -f "$BL2_IMG" ]; then
    RESCUE_IMG="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin"
    # 1. 创建 32MB 实心包
    dd if=/dev/zero of="$RESCUE_IMG" bs=1M count=32
    # 2. 写入 BL2 (Offset 0)
    dd if="$BL2_IMG" of="$RESCUE_IMG" conv=notrunc
    # 3. 写入 FIP (Offset 3.5MB = 3584KB)
    if [ -f "$FIP_BIN" ]; then
        echo "正在将 FIP 注入 3.5MB 偏移处..."
        dd if="$FIP_BIN" of="$RESCUE_IMG" bs=1k seek=3584 conv=notrunc
    else
        echo "⚠️ 警告：未发现 FIP.bin，救砖包仅包含引导头。"
    fi
    echo "✅ 32MB 救砖固件已成功生成: $RESCUE_IMG"
else
    echo "❌ 严重错误：未发现 bl2.img，编译流程失败！"
    ls -R "$BUILD_EXPORT"
    exit 1
fi

# --- [7. 打包串口工具与编译系统固件] ---
if [ -d "$UARTBOOT_DIR" ]; then
    echo "正在归档串口救砖工具..."
    tar -czf "$OUTPUT_DIR/mtk_uartboot.tar.gz" -C "$SOURCE_REPO" mtk_uartboot
fi

echo "=== 📦 启动 ImmortalWrt 系统编译 ==="
cd "$OPENWRT_DIR"
# 注入 .config
cp -v "$SCRIPT_DIR/888/sl3000.config" "$OPENWRT_DIR/.config"
make defconfig
# 开启多线程编译
make -j$(nproc) V=s || exit 1

# 提取最终系统固件
find bin/targets/ -type f -name "*sysupgrade*" -exec cp -v {} "$OUTPUT_DIR/" \;

echo "✅ [SUCCESS] 全链路构建任务圆满结束"
