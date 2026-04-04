#!/bin/bash
set -euo pipefail

# 路径定义（基于 GitHub Actions 默认路径）
WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
CONFIG_DIR="$WORKSPACE/main-repo/888"
OUTPUT_DIR="$WORKSPACE/output"
IMMORTALWRT_BUILD="$WORKSPACE/immortalwrt-build"

# 1. 建立目录结构
mkdir -p $OUTPUT_DIR/atf $OUTPUT_DIR/uboot $OUTPUT_DIR/firmware

# 2. 验证核心配置文件是否存在
echo "=== 物理审计：验证配置文件 ==="
[ -f "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" ] || { echo "❌ 缺少 DTS"; exit 1; }
[ -f "$CONFIG_DIR/sl3000.config" ] || { echo "❌ 缺少 Config"; exit 1; }
[ -f "$CONFIG_DIR/mt7981_sl3000.mk" ] || { echo "❌ 缺少 .mk 设备定义"; exit 1; }

# 3. 准备系统源码
echo "=== 准备 ImmortalWrt 源码 ==="
rm -rf $IMMORTALWRT_BUILD
cp -r $SOURCE_DIR/immortalwrt $IMMORTALWRT_BUILD
cd $IMMORTALWRT_BUILD

# 4. 更新并安装 Feeds
sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default
./scripts/feeds update -a
./scripts/feeds install -a

# 5. 清理占用空间大的冗余包（确保固件小于 25MB）
PROBLEM_PKGS="aardvark-dns bottom cargo-c dufs eza fish lsd python3 rustdesk-server"
for pkg in $PROBLEM_PKGS; do
    find feeds/ -type d -name "$pkg" -exec rm -rf {} \; 2>/dev/null || true
done

# 6. 注入设备树与设备定义
echo "=== 注入 SL3000 硬件描述 ==="
DTS_TARGET="target/linux/mediatek/files-6.6/arch/arm64/boot/dts/mediatek"
mkdir -p $DTS_TARGET
cp -v $CONFIG_DIR/mt7981b-sl3000-emmc.dts $DTS_TARGET/
cp -v $CONFIG_DIR/mt7981b-sl3000-emmc.dts target/linux/mediatek/dts/

# 追加 Makefile 设备定义
cat $CONFIG_DIR/mt7981_sl3000.mk >> target/linux/mediatek/image/filogic.mk

# 7. 注入并强制修正配置文件
cp -v $CONFIG_DIR/sl3000.config .config
{
    echo "CONFIG_TARGET_mediatek=y"
    echo "CONFIG_TARGET_mediatek_filogic=y"
    echo "CONFIG_TARGET_mediatek_filogic_DEVICE_mt7981_sl3000_emmc=y"
} >> .config

make defconfig
echo $PWD > $WORKSPACE/build-dir.txt
echo "✅ 脚本 A 执行完毕"
