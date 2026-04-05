#!/bin/bash
# 1. 路径变量准备
WORKSPACE="$GITHUB_WORKSPACE"
CONFIG_DIR="$WORKSPACE/main/888" # 你的三件套所在目录
SOURCE_DIR="$WORKSPACE/immortalwrt"

echo "=== 开始 SL3000 三件套物理注入 ==="

# 2. 注入 DTS 设备树
# 路径对齐到 target/linux/mediatek/dts/
cp -v "$CONFIG_DIR/mt7981b-sl3000-emmc.dts" "$SOURCE_DIR/target/linux/mediatek/dts/"

# 3. 注入设备定义 (Makefile)
# 路径对齐到 target/linux/mediatek/image/
# 注意：如果 mk 文件是完整的设备定义，直接覆盖或追加
cp -v "$CONFIG_DIR/mt7981_sl3000.mk" "$SOURCE_DIR/target/linux/mediatek/image/"

# 4. 注入编译配置 (.config)
cp -v "$CONFIG_DIR/sl3000.config" "$SOURCE_DIR/.config"

# 5. Feeds 强力清理 (防止 Rust/Go 编译报错)
cd "$SOURCE_DIR"
./scripts/feeds update -a
PROBLEM_PKGS="aardvark-dns podman cargo-c python-cryptography ruby"
for pkg in $PROBLEM_PKGS; do
    find feeds/ -type d -name "$pkg" -exec rm -rf {} \; 2>/dev/null || true
done
./scripts/feeds install -a

# 6. 强制执行 defconfig 刷新配置
make defconfig
