#!/bin/bash
set -e

# ========== 1. 物理路径初始化 ==========
[ -z "$GITHUB_WORKSPACE" ] && GITHUB_WORKSPACE=$(pwd)
WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
CONFIG_DIR="$WORKSPACE/main-repo/888"
BUILD_DIR="$WORKSPACE/immortalwrt-build"

# ========== 2. 源码物理同步 (路径自适应) ==========
echo "=== 正在建立物理编译基座 ==="
rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
[ -f "$SOURCE_DIR/Makefile" ] && REAL_SOURCE="$SOURCE_DIR" || REAL_SOURCE="$SOURCE_DIR/immortalwrt"
rsync -a "$REAL_SOURCE/" "$BUILD_DIR/"
cd "$BUILD_DIR"

# ========== 3. 5G 模块切除与 Feeds 净化 ==========
echo "=== 正在清理 5G 冲突与递归依赖 ==="
rm -rf package/5g-modem
find . -type d -name "rd05a1" -exec rm -rf {} \; 2>/dev/null || true

sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default
./scripts/feeds update -a
./scripts/feeds install -a

# ========== 4. SL3000 设备定义注入 (含 .mk 关联) ==========
echo "=== 正在注入设备定义与 DTS ==="
DTS_PATH="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
IMAGE_PATH="target/linux/mediatek/image"
mkdir -p "$DTS_PATH"

# (A) 注入 DTS 并锁定 512M 内存 (0x20000000)
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc.dts" "$DTS_PATH/"
sed -i 's/<0x40000000 0x[0-9a-fA-F]*>/<0x40000000 0x20000000>/g' "$DTS_PATH/mt7981-sl-3000-emmc.dts"

# (B) 注入并注册 mt7981_sl3000.mk
cp -f "$CONFIG_DIR/mt7981_sl3000.mk" "$IMAGE_PATH/"
TARGET_MK="$IMAGE_PATH/mt7981.mk"
[ ! -f "$TARGET_MK" ] && TARGET_MK="$IMAGE_PATH/filogic.mk"
if ! grep -q "mt7981_sl3000.mk" "$TARGET_MK"; then
    echo "" >> "$TARGET_MK"
    echo "include mt7981_sl3000.mk" >> "$TARGET_MK"
fi

# ========== 5. 配置净化与锁定 ==========
cp -f "$CONFIG_DIR/sl3000.config" .config
# 物理剔除 .config 中所有 5G/Modem 残留以防递归依赖
sed -i '/5g-modem/d; /quectel/d; /simcom/d; /rooter/d; /rd05a1/d; /pcat-manager/d' .config
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config

# ========== 6. 【关键修复】手动预编译核心地基 ==========
echo "=== 正在执行稳健配置预检 ==="
yes "" | make oldconfig
make defconfig

echo "=== 正在优先预编译核心依赖 (解决 ld-musl 与 ustream-ssl 报错) ==="
make prepare -j$(nproc)
# 顺序不可乱：工具链 -> 加密库 -> 基础流库 -> 基础文件
make package/libs/toolchain/compile -j1 V=s
make package/libs/mbedtls/compile -j$(nproc) V=s
make package/libs/ustream-ssl/compile -j$(nproc) V=s
make package/base-files/compile -j1 V=s

# 保存路径供 Part2 使用
echo $PWD > "$WORKSPACE/build_path.txt"
