#!/bin/bash
# =========================================================
# SL-3000 救砖零件全链路溯源投递脚本 (绝对路径版)
# =========================================================

# 1. 物理环境侦测
# 如果在 GitHub Actions 环境中，使用物理根目录；否则使用当前工作目录
WORK_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
SRC_DIR="$WORK_DIR/888"
TARGET_DIR="$WORK_DIR/openwrt"

echo "--- [全链路溯源]：定位物理根目录: $WORK_DIR ---"

# 2. 零件投递目标定义
ATF_PATH="$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek"
UBOOT_PATH="$TARGET_DIR/package/boot/uboot-mediatek"

# 3. 物理熔断机制：检查零件源
if [ ! -d "$SRC_DIR" ]; then
    echo "❌ 像素级报错：无法找到零件源目录 $SRC_DIR"
    exit 1
fi

echo "--- [全链路溯源]：开始零件投递 ---"

# 4. 执行物理劫持与灌入
mkdir -p "$ATF_PATH/files" "$UBOOT_PATH/files"

# 劫持 Makefile
[ -f "$SRC_DIR/atf-Makefile" ] && cp -f "$SRC_DIR/atf-Makefile" "$ATF_PATH/Makefile"
[ -f "$SRC_DIR/uboot-Makefile" ] && cp -f "$SRC_DIR/uboot-Makefile" "$UBOOT_PATH/Makefile"

# 灌入 ATF 补丁零件 (5个)
cp -f "$SRC_DIR/bl2_dev_spi_nor.c" "$ATF_PATH/files/"
cp -f "$SRC_DIR/platform_def.h"    "$ATF_PATH/files/"
cp -f "$SRC_DIR/platform.mk"      "$ATF_PATH/files/"
cp -f "$SRC_DIR/bl2.mk"           "$ATF_PATH/files/"
cp -f "$SRC_DIR/mt7981-spi2.dts"  "$ATF_PATH/files/"

# 灌入 U-Boot 零件 (2个)
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$UBOOT_PATH/files/"
cp -f "$SRC_DIR/mt7981-sl3000.dts"       "$UBOOT_PATH/files/"

# 5. 配置文件 (.config) 物理锁死
CONF_FILE="$TARGET_DIR/.config"
if [ -f "$SRC_DIR/sl3000.config" ]; then
    cp -f "$SRC_DIR/sl3000.config" "$CONF_FILE"
fi

# 强行注入激活指令，防止 Skipping 再次发生
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-sl3000-nor=y" >> "$CONF_FILE"
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y" >> "$CONF_FILE"

# 6. 强制清理物理缓存
rm -rf "$TARGET_DIR/tmp"

echo "--- [全链路溯源]：11 个零件已成功完成像素级投递 ---"
