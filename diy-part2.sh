#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKSPACE="$(dirname "$SCRIPT_DIR")"

# 路径定义
SOURCE_REPO="$WORKSPACE/source-repo"
OPENWRT_DIR="$SOURCE_REPO/immortalwrt"
ATF_DIR="$SOURCE_REPO/arm-trusted-firmware"
OUTPUT_DIR="$WORKSPACE/output"
mkdir -p "$OUTPUT_DIR/rescue"

echo "=== 🛠️ 开始底层源码物理修复 (ATF) ==="

# [1. 锁定 1024MB 内存与 3.5MB 偏移] 
# (此处 cat > 重构逻辑保持你之前的版本不变，确保物理对齐)
# ... [此处省略重复的 cat 逻辑，请保留你之前脚本里的物理修复代码] ...

# [2. 编译 ATF 救砖引导]
cd "$ATF_DIR"
sed -i '/PLAT_INCLUDES/ s|$| -Iplat/mediatek/mt7981/include -Iplat/mediatek/common/include|' plat/mediatek/mt7981/platform.mk

echo "正在编译 ATF (BOOT_DEVICE=nor)..."
make CROSS_COMPILE=aarch64-linux-gnu- PLAT=mt7981 BOARD=sl3000 BOOT_DEVICE=nor DRAM_SIZE=1024 all

# 提取并缝合 32MB 实心包
BL2=$(find build/mt7981/release/ -name "bl2.img" | head -n 1)
FIP=$(find build/mt7981/release/ -name "fip.bin" | head -n 1)

if [ -f "$BL2" ] && [ -f "$FIP" ]; then
    dd if=/dev/zero of="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin" bs=1M count=32
    dd if="$BL2" of="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin" conv=notrunc
    dd if="$FIP" of="$OUTPUT_DIR/rescue/SL3000_1G_RESCUE_32M.bin" bs=1k seek=3584 conv=notrunc
    echo "✅ 32MB 救砖固件生成成功"
fi

# [3. 编译 ImmortalWrt 固件]
echo "=== 📦 开始编译主系统固件 ==="
cd "$OPENWRT_DIR"
# 执行编译
make -j$(nproc) V=s || exit 1

# 提取最终固件产物
find bin/targets/ -type f -name "*sysupgrade*" -exec cp {} "$OUTPUT_DIR/" \;

echo "✅ 全部构建任务完成"
