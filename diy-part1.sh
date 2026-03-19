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

if [ -f "$SOURCE_DIR/Makefile" ]; then
    REAL_SOURCE="$SOURCE_DIR"
elif [ -f "$SOURCE_DIR/immortalwrt/Makefile" ]; then
    REAL_SOURCE="$SOURCE_DIR/immortalwrt"
else
    echo "❌ 物理错误：找不到 OpenWrt 源码根目录"
    exit 1
fi

rsync -a "$REAL_SOURCE/" "$BUILD_DIR/"
cd "$BUILD_DIR"

# ========== 3. 依赖净化与 5G 彻底切除 ==========
echo "=== 正在执行降维打击：物理切除 5G 与冲突源 ==="
# 1. 物理删除目录 (预防性执行)
rm -rf package/5g-modem
find . -type d -name "rd05a1" -exec rm -rf {} \; 2>/dev/null || true

# 2. 禁用导致 Broken Pipe 的 Feeds
sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default
sed -i 's/^src-git video/#src-git video/g' feeds.conf.default

./scripts/feeds update -a
./scripts/feeds install -a

# ========== 4. SL3000 512M 专项注入 ==========
echo "=== 正在注入 SL3000 救砖 Profile ==="
DTS_PATH="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
mkdir -p "$DTS_PATH"

# (A) 注入 DTS 并物理锁定 512M 内存寄存器 (0x20000000)
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc.dts" "$DTS_PATH/"
sed -i 's/<0x40000000 0x[0-9a-fA-F]*>/<0x40000000 0x20000000>/g' "$DTS_PATH/mt7981-sl-3000-emmc.dts"

# (B) 注入设备定义 (自动识别 mt7981.mk 或 filogic.mk)
TARGET_MK="target/linux/mediatek/image/mt7981.mk"
[ ! -f "$TARGET_MK" ] && TARGET_MK="target/linux/mediatek/image/filogic.mk"

# 清理旧定义防止 Makefile 冲突
sed -i '/Device\/sl_3000-emmc/,/endef/d' "$TARGET_MK"

cat >> "$TARGET_MK" <<EOF

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC (512MB rescue)
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-storage f2fsck mkf2fs kmod-fs-f2fs kmod-mmc \\
    luci-app-ksmbd ksmbd-utils
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000-emmc
EOF

# ========== 5. .config 深度去噪 (核心修复) ==========
cp -f "$CONFIG_DIR/sl3000.config" .config

echo "=== 正在清除配置中的 5G 残留与递归依赖 ==="
# 移除所有可能导致 recursive dependency 的选项
sed -i '/5g-modem/d' .config
sed -i '/quectel/d' .config
sed -i '/simcom/d' .config
sed -i '/rooter/d' .config
sed -i '/rd05a1/d' .config
sed -i '/pcat-manager/d' .config

# 强制激活核心选项
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config
echo "CONFIG_LINUX_5_4=y" >> .config

# ========== 6. 稳定通过配置预检 ==========
yes "" | make oldconfig
make defconfig

# 预编译 base-files 防止并行 Error 2
make package/base-files/compile -j1 V=s
