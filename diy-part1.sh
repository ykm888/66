#!/bin/bash
set -e

# ========== 1. 路径与环境初始化 ==========
WORKSPACE=$(pwd)
CONFIG_DIR="$WORKSPACE/main-repo/888"
FIRMWARE_DIR="$WORKSPACE/firmware-repo"
BUILD_DIR="$WORKSPACE/immortalwrt-build"
OUTPUT_DIR="$WORKSPACE/output"

mkdir -p $OUTPUT_DIR/firmware

# 建立编译基座 (物理同步)
echo "=== 正在建立物理编译基座 ==="
rm -rf $BUILD_DIR && mkdir -p $BUILD_DIR
cp -a $FIRMWARE_DIR/. $BUILD_DIR/
cd $BUILD_DIR

# 物理路径定位 (ykm888 5.4内核专用)
DTS_PATH="target/linux/mediatek/files-5.4/arch/arm64/boot/dts/mediatek"
MK_FILE="target/linux/mediatek/image/mt7981.mk"
mkdir -p "$DTS_PATH"

# ========== 2. 512M 专项 DTS 注入与内存锁定 ==========
echo "=== 正在注入并配置 512M 专项 DTS ==="
# 物理复制并强制修改内存寄存器为 512MB (0x20000000)
cp -f "$CONFIG_DIR/mt7981-sl-3000-emmc.dts" "$DTS_PATH/mt7981-sl-3000-emmc.dts"
sed -i 's/<0x40000000 0x[0-9a-fA-F]*>/<0x40000000 0x20000000>/g' "$DTS_PATH/mt7981-sl-3000-emmc.dts"
# 物理修改 Model 标签
sed -i 's/model = ".*"/model = "SL-3000 eMMC (512MB Rescue)"/g' "$DTS_PATH/mt7981-sl-3000-emmc.dts"

# ========== 3. 物理注册 Device Profile (基于你的模板) ==========
echo "=== 正在 mt7981.mk 中物理注册设备链 ==="
# 清理旧定义防止冲突
sed -i '/Device\/sl_3000-emmc/,/endef/d' "$MK_FILE"

cat >> "$MK_FILE" <<EOF

define Device/sl_3000-emmc
  DEVICE_VENDOR := SL
  DEVICE_MODEL := 3000 eMMC (512MB rescue)
  DEVICE_DTS := mt7981-sl-3000-emmc
  DEVICE_DTS_DIR := \$(DTS_DIR)/mediatek
  SUPPORTED_DEVICES := sl,3000-emmc
  DEVICE_PACKAGES := \$(MT7981_USB_PKGS) f2fsck losetup mkf2fs kmod-fs-f2fs kmod-mmc \\
	luci-app-ksmbd luci-i18n-ksmbd-zh-cn ksmbd-utils
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += sl_3000-emmc
EOF

# ========== 4. 配置强制注入与依赖净化 ==========
echo "=== 正在执行配置物理强制锁定 ==="
cp -f "$CONFIG_DIR/sl3000.config" .config

# 物理追加救砖版核心配置 (100% 激活)
cat >> .config <<EOF
CONFIG_TARGET_mediatek=y
CONFIG_TARGET_mediatek_filogic=y
CONFIG_TARGET_mediatek_filogic_DEVICE_sl_3000-emmc=y
CONFIG_LINUX_5_4=y
# 物理切除内存大户 (GDB/STRACE/DEVEL)
# CONFIG_DEVEL is not set
# CONFIG_PACKAGE_gdb is not set
# CONFIG_PACKAGE_strace is not set
EOF

# Feeds 净化逻辑 (终结 Broken Pipe)
./scripts/feeds update -a
rm -rf feeds/video feeds/telephony/onionshare*
./scripts/feeds update -i && ./scripts/feeds install -a

# 执行稳健的 oldconfig
yes "" | make oldconfig
make defconfig

# ========== 5. 编译与产物物理搜集 ==========
echo "=== 物理准备就绪，启动全量编译 ==="
make -j$(nproc) V=s

echo "=== 正在执行产物物理搜集 ==="
find bin/targets/ -type f \( -name "*.bin" -o -name "*.img.gz" -o -name "*sysupgrade*" \) -exec cp -v {} $OUTPUT_DIR/firmware/ \;

# 最终完整性校验
[ -z "$(ls -A $OUTPUT_DIR/firmware)" ] && { echo "❌ 物理错误：未发现固件产物！"; exit 1; }
echo "✅ SL3000-512M 构建任务物理全链路闭环完成"
