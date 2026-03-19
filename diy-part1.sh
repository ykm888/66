#!/bin/bash
set -e

# ========== 1. 物理路径初始化 ==========
WORKSPACE="$GITHUB_WORKSPACE"
SOURCE_DIR="$WORKSPACE/source-repo"
CONFIG_DIR="$WORKSPACE/main-repo/888"
OUTPUT_DIR="$WORKSPACE/output"
BUILD_DIR="$WORKSPACE/immortalwrt-build"

# 物理路径定位 (ykm888 2410 分支基于 5.4 内核)
DTS_PATH_54="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
IMAGE_PATH="target/linux/mediatek/image"

mkdir -p $OUTPUT_DIR/firmware

# ========== 2. 源码物理对齐 ==========
echo "=== 正在建立物理编译基座 ==="
rm -rf $BUILD_DIR && mkdir -p $BUILD_DIR
# 使用 rsync 确保软链接和隐藏文件 100% 同步
rsync -a $SOURCE_DIR/immortalwrt/ $BUILD_DIR/
cd $BUILD_DIR

# ========== 3. 依赖净化 (解决 Broken Pipe 与 Error 2) ==========
echo "=== 正在清理冲突 Feeds ==="
# 禁用导致 5.4 分支 Makefile 丢失的源
sed -i 's/^src-git telephony/#src-git telephony/g' feeds.conf.default
sed -i 's/^src-git video/#src-git video/g' feeds.conf.default

./scripts/feeds update -a

# 暴力物理删除：彻底清除已知会导致 abort-due-to-no-makefile 的包
PROBLEM_PKGS="gst1-plugins-good gst1-plugins-bad gst1-libav kamailio python-docker python-jsonschema onionshare luci-app-homeproxy"
for pkg in $PROBLEM_PKGS; do
    find feeds/ -type d -name "$pkg" -exec rm -rf {} \; 2>/dev/null || true
done

./scripts/feeds install -a

# ========== 4. 注册 SL3000 三件套 ==========
echo "=== 正在注入 SL3000 512M 救砖 Profile ==="
mkdir -p "$DTS_PATH_54"

# (A) 注入 DTS 并物理锁定 512M 内存寄存器 (0x20000000)
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc.dts" "$DTS_PATH_54/"
sed -i 's/<0x40000000 0x[0-9a-fA-F]*>/<0x40000000 0x20000000>/g' "$DTS_PATH_54/mt7981-sl-3000-emmc.dts"

# (B) 注入设备定义 (自动识别 mt7981.mk 或 filogic.mk)
TARGET_MK="$IMAGE_PATH/mt7981.mk"
[ ! -f "$TARGET_MK" ] && TARGET_MK="$IMAGE_PATH/filogic.mk"

# 清理旧定义防止 Makefile 冲突
sed -i '/Device\/sl_3000-emmc/,/endef/d' "$TARGET_MK"

cat >> "$TARGET_MK" <<EOF

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC (512MB rescue)
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := kmod-usb3 kmod-usb-storage kmod-usb-storage-uas \\
    f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\
    luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000-emmc
EOF

# ========== 5. 配置锁定与预温阶段 ==========
cp -f "$CONFIG_DIR/sl3000.config" .config
echo "CONFIG_TARGET_mediatek=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic=y" >> .config
echo "CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y" >> .config

# 强制通过 oldconfig
yes "" | make oldconfig
make defconfig

# 【核心修复】：单线程预编译 base-files，防止并行 Error 2
echo "=== 正在执行单线程核心包预编译 ==="
make package/base-files/compile -j1 V=s

# 保存路径供脚本二使用
echo $PWD > "$WORKSPACE/build_path.txt"
