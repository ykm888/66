#!/bin/bash
# 1版原文照抄，只修复物理错误

# 路径对齐
CONFIG_DIR="$GITHUB_WORKSPACE/main-repo/888"
SOURCE_DIR="$GITHUB_WORKSPACE/source-repo"
OUTPUT_DIR="$GITHUB_WORKSPACE/output"
mkdir -p $OUTPUT_DIR

# 1. 注入你的自定义 DTS 和 设备定义 (覆盖别人源码中的配置)
echo "=== 物理审计：注入你的自定义硬件定义 ==="
DTS_DEST="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p $DTS_DEST
cp -v $CONFIG_DIR/mt7981b-sl3000-emmc.dts $DTS_DEST/
cat $CONFIG_DIR/mt7981_sl3000.mk >> target/linux/mediatek/image/filogic.mk

# 2. 强行修改别人的 ATF 源码 (物理锁定 DDR4 1024M)
# 这一步非常重要，防止别人仓库默认配置不是 1GB
echo "=== 正在对远程 ATF 源码进行物理 Patch ==="
ATF_MEM_FILE="$SOURCE_DIR/arm-trusted-firmware/plat/mediatek/mt7981/drivers/dram/mtk_mem_init.c"

if [ -f "$ATF_MEM_FILE" ]; then
    cat > "$ATF_MEM_FILE" << 'EOF'
#include <plat/common/platform.h>
#include <common/debug.h>
void mtk_mem_init(void) {
    extern int mt7981_use_ddr4;
    extern int mt7981_ddr_size_limit;
    extern void mtk_mem_init_real(void);
    mt7981_use_ddr4 = 1;        // 强制 DDR4
    mt7981_ddr_size_limit = 1024; // 强制识别 1024MB 内存
    NOTICE("EMI: SL3000 Custom Build - Forced DDR4 1024MB\n");
    mtk_mem_init_real();
}
EOF
    echo "✅ ATF 补丁注入成功"
fi

# 3. 编译底层产物 (利用交叉编译器)
echo "=== 正在编译底层引导程序 ==="
export CROSS_COMPILE=aarch64-linux-gnu-
export ARCH=arm64

# 编译 ATF -> bl2.img
cd $SOURCE_DIR/arm-trusted-firmware
make PLAT=mt7981 BOARD=sl3000 all
cp build/mt7981/release/bl2.img $OUTPUT_DIR/bl2-nor.bin

# 编译 U-Boot -> fip.bin
cd $SOURCE_DIR/u-boot
make mt7981_sl3000_defconfig # 请确保别人仓库里有这个 defconfig，如果没有请改为 rfb 默认版
make -j$(nproc)
cp fip.bin $OUTPUT_DIR/fip-nor.bin

# 4. 回到 OpenWrt 根目录继续系统编译
cd $GITHUB_WORKSPACE/immortalwrt-build

# 5. 定义全家桶缝合函数
# 在 Actions 步骤最后调用此函数即可生成 32MB 实心包
function finalize_32mb_image() {
    echo "=== 正在执行 32MB 像素级全流程全家桶缝合 ==="
    # 创建底图
    tr '\000' '\377' < /dev/zero | dd of=$OUTPUT_DIR/Spi-flash-32MB-Full.bin bs=1M count=32
    
    # 物理缝合 (遵循 3.5MB 和 5.5MB 偏移量)
    dd if=$OUTPUT_DIR/bl2-nor.bin of=$OUTPUT_DIR/Spi-flash-32MB-Full.bin conv=notrunc
    dd if=$OUTPUT_DIR/fip-nor.bin of=$OUTPUT_DIR/Spi-flash-32MB-Full.bin bs=1k seek=3584 conv=notrunc
    
    # 查找刚刚编译好的系统固件
    SYS_BIN=$(find bin/targets/ -name "*sysupgrade.bin" | head -1)
    if [ -n "$SYS_BIN" ]; then
        dd if=$SYS_BIN of=$OUTPUT_DIR/Spi-flash-32MB-Full.bin bs=1k seek=5632 conv=notrunc
        echo "✅ 32MB 实心救砖包缝合成功：$OUTPUT_DIR/Spi-flash-32MB-Full.bin"
    else
        echo "❌ 警告：未找到系统固件，仅生成了底层引导包。"
    fi
}

echo "✅ diy-part2.sh: 物理注入与底层编译准备就绪"
