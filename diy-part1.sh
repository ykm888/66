#!/bin/bash
set -e

# ========== 1. 物理路径初始化 ==========
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
CONFIG_DIR="$WORKSPACE/main-repo/888"
BUILD_DIR="$WORKSPACE/immortalwrt-build"

# ========== 2. 源码物理同步 ==========
echo "=== 正在建立物理编译基座 ==="
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
[ -f "$SOURCE_DIR/Makefile" ] && REAL_SOURCE="$SOURCE_DIR" || REAL_SOURCE="$SOURCE_DIR/immortalwrt"
rsync -a "$REAL_SOURCE/" "$BUILD_DIR/"
cd "$BUILD_DIR"

# ========== 3. 5G 模块切除与 Feeds 净化 ==========
echo "=== 正在清理冲突源 (含 5g-modem) ==="
rm -rf package/5g-modem
find . -type d -name "rd05a1" -exec rm -rf {} \; 2>/dev/null || true

sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default
./scripts/feeds update -a
./scripts/feeds install -a

# ========== 4. SL3000 512M 专项注入 (MK文件关联) ==========
echo "=== 正在注入设备定义与 DTS ==="
DTS_PATH="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
IMAGE_PATH="target/linux/mediatek/image"
mkdir -p "$DTS_PATH"

# (A) 注入 DTS 并物理锁定 512M 内存
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc.dts" "$DTS_PATH/"
sed -i 's/<0x40000000 0x[0-9a-fA-F]*>/<0x40000000 0x20000000>/g' "$DTS_PATH/mt7981-sl-3000-emmc.dts"

# (B) 注入 .mk 文件并建立 Makefile 关联
cp -f "$CONFIG_DIR/mt7981_sl3000.mk" "$IMAGE_PATH/"
TARGET_MK="$IMAGE_PATH/mt7981.mk"
[ ! -f "$TARGET_MK" ] && TARGET_MK="$IMAGE_PATH/filogic.mk"

if ! grep -q "mt7981_sl3000.mk" "$TARGET_MK"; then
    echo "" >> "$TARGET_MK"
    echo "include mt7981_sl3000.mk" >> "$TARGET_MK"
fi

# ========== 5. 配置深度净化与锁定 ==========
cp -f "$CONFIG_DIR/sl3000.config" .config
# 删除 5G 残留和导致递归依赖的项
sed -i '/5g-modem/d; /quectel/d; /simcom/d; /rooter/d; /rd05a1/d' .config
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config

# ========== 6. 【核心修复】地基先行策略 ==========
echo "=== 正在执行稳健配置预检 ==="
yes "" | make oldconfig
make defconfig

echo "=== 正在强制安装编译工具链 (解决 ld-musl 缺失) ==="
# 先跑 prepare 建立目录结构
make prepare -j$(nproc)
# 物理强制编译并安装工具链基础库，必须 -j1 保证文件写入 staging_dir
make package/libs/toolchain/compile -j1 V=s

# 保存路径供 Part2 使用
echo $PWD > "$WORKSPACE/build_path.txt"
