#!/bin/bash
set -e

# ========== 1. 物理路径初始化 ==========
WORKSPACE=$(pwd)
CONFIG_DIR="$WORKSPACE/main-repo/888"
FIRMWARE_DIR="$WORKSPACE/firmware-repo"
BUILD_DIR="$WORKSPACE/immortalwrt-build"
OUTPUT_DIR="$WORKSPACE/output"

# 建立物理基座
echo "=== 正在建立物理编译基座 ==="
rm -rf $BUILD_DIR && mkdir -p $BUILD_DIR
cp -a $FIRMWARE_DIR/. $BUILD_DIR/
cd $BUILD_DIR

# 物理路径定位 (基于 ykm888/2410 的 5.4 内核路径)
DTS_PATH="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
IMAGE_PATH="target/linux/mediatek/image"
mkdir -p "$DTS_PATH"

# ========== 2. 执行 SL3000 独立注册方案 ==========
echo "=== 正在注入 512M 救砖版三件套 ==="

# (A) 注入 DTS 并强制锁定 512M 内存寄存器 (0x20000000)
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc.dts" "$DTS_PATH/"
sed -i 's/<0x40000000 0x[0-9a-fA-F]*>/<0x40000000 0x20000000>/g' "$DTS_PATH/mt7981-sl-3000-emmc.dts"

# (B) 注入独立的 .mk 设备定义文件
cp -f "$CONFIG_DIR/mt7981_sl3000.mk" "$IMAGE_PATH/"

# (C) 物理关联：在主 mt7981.mk 末尾包含你的独立 mk
# 这样能 100% 确保编译系统识别到 SL3000 设备
MAIN_MK="$IMAGE_PATH/mt7981.mk"
if ! grep -q "mt7981_sl3000.mk" "$MAIN_MK"; then
    echo "=== 正在建立 Makefile 物理关联 ==="
    echo "" >> "$MAIN_MK"
    echo "include mt7981_sl3000.mk" >> "$MAIN_MK"
fi

# ========== 3. 配置锁定与 Feeds 净化 ==========
echo "=== 正在执行配置物理激活 ==="
cp -f "$CONFIG_DIR/sl3000.config" .config

# 强行追加核心配置，防止被 defconfig 剔除
cat >> .config <<EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y
CONFIG_LINUX_5_4=y
# 物理关闭可能导致 Actions 崩溃的 DEVEL 模式
# CONFIG_DEVEL is not set
EOF

# 净化 Feeds 解决 Broken Pipe 风险
./scripts/feeds update -a
rm -rf feeds/video feeds/telephony/onionshare*
./scripts/feeds update -i && ./scripts/feeds install -a

# 执行稳健的旧配置迁移
yes "" | make oldconfig
make defconfig

# ========== 4. 编译与产物搜集 ==========
echo "=== 物理准备就绪，启动全量编译 ==="
make -j$(nproc) V=s

echo "=== 正在执行产物搜集 ==="
# 递归搜索所有 .bin 并拷贝到输出目录
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} $OUTPUT_DIR/firmware/ \;

# 最终判定
if [ -z "$(ls -A $OUTPUT_DIR/firmware)" ]; then
    echo "❌ 物理错误：未发现任何生成的固件产物！"
    exit 1
fi
echo "✅ SL3000 V2 自动化发布版构建完成"
