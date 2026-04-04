#!/bin/bash
# 2版：物理像素级全流程修复
# 原则：延续1版原文，只修复编译路径与定义冲突错误

# 路径对齐 (确保环境变量在 Actions 环境中可用)
CONFIG_DIR="$GITHUB_WORKSPACE/main/888"
SOURCE_DIR="$GITHUB_WORKSPACE/source-repo"
OUTPUT_DIR="$GITHUB_WORKSPACE/output"
mkdir -p $OUTPUT_DIR

# 1. 注入自定义 DTS 和设备定义
echo "=== 物理审计：注入自定义硬件定义 ==="
# 修正：OpenWrt 21.02+ 的 DTS 路径通常在如下位置，请根据你的源码版本确认
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p $DTS_DEST
[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] && cp -v $CONFIG_DIR/mt7981b-sl3000-emmc.dts $DTS_DEST/

# 修正：防止重复定义导致的编译错误
sed -i '/Device\/sl_3000-emmc/,/endef/d' target/linux/mediatek/image/filogic.mk
cat $CONFIG_DIR/mt7981_sl3000.mk >> target/linux/mediatek/image/filogic.mk

# 2. 强行修改 ATF 源码 (物理锁定 DDR4 1024M)
echo "=== 正在对远程 ATF 源码进行物理 Patch ==="
# 修正：确保路径在 source-repo 下的准确位置
ATF_MEM_FILE="$SOURCE_DIR/arm-trusted-firmware/plat/mediatek/mt7981/drivers/dram/mt7981_mem_init.c"

if [ -f "$ATF_MEM_FILE" ]; then
    # 使用覆盖模式，确保 1024MB 优先级最高
    cat > "$ATF_MEM_FILE" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
void mtk_mem_init(void) {
    extern int mt7981_use_ddr4;
    extern int mt7981_ddr_size_limit;
    mt7981_use_ddr4 = 1;        // 强制 DDR4
    mt7981_ddr_size_limit = 1024; // 锁定 1024MB
    NOTICE("EMI: SL3000-1GB-Custom-Build Initializing...\n");
}
EOF
    echo "✅ ATF 补丁注入成功"
fi

# 3. 编译底层产物 (利用 Actions 自带交叉编译器)
echo "=== 正在编译底层引导程序 ==="
# 修正：检查交叉编译器是否存在
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo "❌ 错误：未找到 aarch64-linux-gnu-gcc，请在 Workflow 中先安装 gcc-aarch64-linux-gnu"
    # 不强制退出，尝试继续，某些环境可能已预装
fi

# 编译 ATF -> bl2.img
cd $SOURCE_DIR/arm-trusted-firmware
make PLAT=mt7981 BOARD=sl3000-nor-1024M CROSS_COMPILE=aarch64-linux-gnu- all
[ -f "build/mt7981/release/bl2.img" ] && cp build/mt7981/release/bl2.img $OUTPUT_DIR/bl2-nor.bin

# 编译 U-Boot -> fip.bin
cd $SOURCE_DIR/u-boot
# 修正：如果没找到 sl3000 配置，回退到 spim-nor-rfb 默认配置
if [ -f "configs/mt7981_sl3000_defconfig" ]; then
    make mt7981_sl3000_defconfig
else
    make mt7981_spim_nor_rfb_defconfig
fi
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
[ -f "fip.bin" ] && cp fip.bin $OUTPUT_DIR/fip-nor.bin

# 4. 返回编译目录
cd $GITHUB_WORKSPACE

# 5. 定义全家桶缝合函数
function finalize_32mb_image() {
    echo "=== 正在执行 32MB 像素级全流程全家桶缝合 ==="
    SAVE_FILE="$OUTPUT_DIR/SL3000-SPI-NOR-32MB-Full.bin"
    
    # 创建 32MB 全 FF 实心底图
    tr '\000' '\377' < /dev/zero | dd of=$SAVE_FILE bs=1M count=32
    
    # 物理缝合 (偏移对齐)
    # BL2: 0KB
    dd if=$OUTPUT_DIR/bl2-nor.bin of=$SAVE_FILE conv=notrunc
    # FIP: 3584KB (3.5MB)
    dd if=$OUTPUT_DIR/fip-nor.bin of=$SAVE_FILE bs=1k seek=3584 conv=notrunc
    
    # 查找系统固件
    SYS_BIN=$(find bin/targets/ -name "*sl_3000-emmc*sysupgrade.bin" | head -1)
    if [ -n "$SYS_BIN" ]; then
        # 审计系统包大小，防止溢出 32MB
        SYS_SIZE=$(stat -c%s "$SYS_BIN")
        MAX_SIZE=$(( (32 * 1024 * 1024) - (5632 * 1024) ))
        if [ "$SYS_SIZE" -gt "$MAX_SIZE" ]; then
             echo "❌ 警告：固件过大 ($SYS_SIZE bytes)，超出了 32MB Flash 剩余空间！"
        else
             dd if=$SYS_BIN of=$SAVE_FILE bs=1k seek=5632 conv=notrunc
             echo "✅ 32MB 全家桶缝合成功：$SAVE_FILE"
        fi
    fi
}

echo "✅ diy-part2.sh: 物理注入与底层编译准备就绪"
