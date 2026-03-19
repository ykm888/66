#!/bin/bash
set -e

# ========== 1. 路径初始化 ==========
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

# ========== 4. SL3000 512M 专项注入 (核心修改) ==========
echo "=== 正在注入设备定义: mt7981_sl3000.mk ==="
DTS_PATH="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
IMAGE_PATH="target/linux/mediatek/image"
mkdir -p "$DTS_PATH"

# (A) 注入 DTS 并物理锁定 512M 内存
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc.dts" "$DTS_PATH/"
sed -i 's/<0x40000000 0x[0-9a-fA-F]*>/<0x40000000 0x20000000>/g' "$DTS_PATH/mt7981-sl-3000-emmc.dts"

# (B) 注入 .mk 文件并建立 Makefile 关联
cp -f "$CONFIG_DIR/mt7981_sl3000.mk" "$IMAGE_PATH/"

# 自动探测主 Makefile 并 include 你的 mk
TARGET_MK="$IMAGE_PATH/mt7981.mk"
[ ! -f "$TARGET_MK" ] && TARGET_MK="$IMAGE_PATH/filogic.mk"

if ! grep -q "mt7981_sl3000.mk" "$TARGET_MK"; then
    echo "" >> "$TARGET_MK"
    echo "include mt7981_sl3000.mk" >> "$TARGET_MK"
    echo "✅ 已将 mt7981_sl3000.mk 注册至 $TARGET_MK"
fi

# ========== 5. 配置深度净化 ==========
cp -f "$CONFIG_DIR/sl3000.config" .config
# 清除 5G 残留防止递归依赖
sed -i '/5g-modem/d; /quectel/d; /simcom/d; /rooter/d; /rd05a1/d' .config
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config

# ========== 6. 地基加固 (解决 ld-musl 报错) ==========
yes "" | make oldconfig
make defconfig
echo "=== 执行预处理与工具链库预编译 ==="
make prepare -j$(nproc)
make package/libs/toolchain/compile -j1 V=s

# 保存路径
echo $PWD > "$WORKSPACE/build_path.txt"
