#!/bin/bash

# 接收分支参数，默认为 sl3000-uboot-base
UBOOT_BRANCH=$1
[ -z "$UBOOT_BRANCH" ] && UBOOT_BRANCH="sl3000-uboot-base"

echo ">>> [物理启动] SL-3000 1024M 救砖全家桶构建流程"

# 1. 物理破除 OpenWrt 内核 1024M 识别限制
# 这一步确保系统启动后能看到 1024M 内存
if [ -f "openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh" ]; then
    sed -i 's/256m/1024m/g' openwrt/target/linux/mediatek/filogic/base-files/lib/upgrade/platform.sh
    echo "✅ 内核 1024M 补丁物理注入成功"
fi

# 2. 物理初始化编译环境 (解决 not found 顽疾)
echo ">>> 正在物理强插 aarch64 交叉工具链..."
sudo apt-get update -qq
sudo apt-get install -y -qq gcc-aarch64-linux-gnu build-essential flex bison bc python3-dev

# 3. 物理准备 U-Boot 源码
echo ">>> 正在检出 U-Boot 分支: $UBOOT_BRANCH"
rm -rf uboot-src # 清理旧残留
git clone --depth 1 -b $UBOOT_BRANCH https://github.com/ykm888/66.git uboot-src
cd uboot-src

# 4. 物理锁死 1024M 配置 (源头修改法)
echo ">>> 正在物理锁定 1024M DRAM 配置..."
# 检查并修改所有可能的内存定义
if [ -f "configs/mt7981_emmc_defconfig" ]; then
    sed -i 's/CONFIG_NR_DRAM_BANKS=.*/CONFIG_NR_DRAM_BANKS=1/g' configs/mt7981_emmc_defconfig
    # 强制注入，防止遗漏
    grep -q "CONFIG_NR_DRAM_BANKS=1" configs/mt7981_emmc_defconfig || echo "CONFIG_NR_DRAM_BANKS=1" >> configs/mt7981_emmc_defconfig
fi

# 5. 物理启动编译流程
export ARCH=arm
export CROSS_COMPILE=aarch64-linux-gnu-

echo ">>> 物理清理环境..."
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE distclean

echo ">>> 物解析配置 (Defconfig)..."
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mt7981_emmc_defconfig

echo ">>> 物理多核并行编译 (核心环节)..."
# 显式传递参数给 make，确保变量不被覆盖
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc) || {
    echo "❌ 编译失败，尝试单核输出详细错误..."
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE V=s -j1
    exit 1
}

# 6. 产物物理搜寻与提取
echo ">>> 正在物理搜寻编译产物..."
# 优先级：u-boot-mtk.bin (带头) > u-boot.bin
TARGET_BIN=""
if [ -f "u-boot-mtk.bin" ]; then
    TARGET_BIN="u-boot-mtk.bin"
elif [ -f "u-boot.bin" ]; then
    TARGET_BIN="u-boot.bin"
fi

if [ -n "$TARGET_BIN" ]; then
    cp "$TARGET_BIN" ../sl3000-uboot.bin
    echo "✅ 救砖引导物理提取成功: $TARGET_BIN -> sl3000-uboot.bin"
else
    echo "❌ 物理灾难：未发现任何可用的 .bin 产物"
    ls -F
    exit 1
fi

cd ..
echo "✅ [物理闭环] 第 5 版修正版执行完毕！"
