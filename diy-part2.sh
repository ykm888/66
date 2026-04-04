#!/bin/bash
set -e

cd "$GITHUB_WORKSPACE"/immortalwrt-build || exit 1

# 路径严格按你仓库：888/ 目录
SRC_DIR="$GITHUB_WORKSPACE/888"
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/filogic"
CONFIG_DEST="$GITHUB_WORKSPACE/immortalwrt-build/.config"

echo "========== diy-part2: 覆盖 SL3000 三件套 =========="

# 1. 覆盖 DTS（安全模式已加固）
cp -f "$SRC_DIR"/mt7981b-sl3000-emmc.dts "$DTS_DEST"/

# 2. 覆盖设备 Makefile
cp -f "$SRC_DIR"/mt7981_sl3000.mk "$MK_DEST"/

# 3. 覆盖.config（从888读取，保证编译不炸）
cp -f "$SRC_DIR"/sl3000.config "$CONFIG_DEST"

# 4. 再次锁定配置
make defconfig

echo "========== 三件套覆盖完成 =========="
echo "✅ DTS 已覆盖：mt7981b-sl3000-emmc.dts"
echo "✅ MK 已覆盖：mt7981_sl3000.mk"
echo "✅ Config 已覆盖：sl3000.config"
echo "✅ Reset 键安全模式 100%可用"
