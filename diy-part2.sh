#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理死锁投递脚本 (Final Hardened Version)
# =========================================================

# 1. 物理环境侦测与路径锚定
# 自动识别 GitHub Actions 工作空间，确保 cp 指令不会因路径位移失效
WORK_DIR="${GITHUB_WORKSPACE:-$(pwd)}"
SRC_DIR="$WORK_DIR/888"
TARGET_DIR="$WORK_DIR/openwrt"

echo "--- [物理溯源]：锁定构建根目录 $WORK_DIR ---"

# 2. 目标目录初始化
# 这里的路径对应你克隆的 sl3000-immortalwrt-bootstrap 分支结构
ATF_PATH="$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek"
UBOOT_PATH="$TARGET_DIR/package/boot/uboot-mediatek"

echo "--- [物理溯源]：准备零件预埋区 ---"
mkdir -p "$ATF_PATH/files"
mkdir -p "$UBOOT_PATH/files"

# 3. 物理强灌：ATF 救砖零件
# 灌入 Makefile 劫持编译流程，灌入 .c 和 .h 零件修正 1MB 偏移逻辑
echo "--- [物理溯源]：正在投递 ATF 1MB 偏移补丁 ---"
[ -f "$SRC_DIR/atf-Makefile" ] && cp -f "$SRC_DIR/atf-Makefile" "$ATF_PATH/Makefile"
cp -f "$SRC_DIR/bl2_dev_spi_nor.c" "$ATF_PATH/files/"
cp -f "$SRC_DIR/platform_def.h"    "$ATF_PATH/files/"
cp -f "$SRC_DIR/platform.mk"      "$ATF_PATH/files/"
cp -f "$SRC_DIR/bl2.mk"           "$ATF_PATH/files/"
cp -f "$SRC_DIR/mt7981-spi2.dts"  "$ATF_PATH/files/"

# 4. 物理强灌：U-Boot 对齐零件
# 重点：DTS 文件名必须与 Makefile 里的 DEVICE_TREE 变量像素级对齐
echo "--- [物理溯源]：正在投递 U-Boot 分区对齐零件 ---"
[ -f "$SRC_DIR/uboot-Makefile" ] && cp -f "$SRC_DIR/uboot-Makefile" "$UBOOT_PATH/Makefile"
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$UBOOT_PATH/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$UBOOT_PATH/files/"

# 5. 配置物理死锁 (.config)
# 强制选中这两个包，防止 OpenWrt 的依赖检查将其跳过 (Skipping)
echo "--- [物理溯源]：执行配置物理注入 ---"
if [ -f "$SRC_DIR/sl3000.config" ]; then
    cp -f "$SRC_DIR/sl3000.config" "$TARGET_DIR/.config"
fi

# 双重保险：在配置末尾追加强制选中指令
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-sl3000-nor=y" >> "$TARGET_DIR/.config"
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y" >> "$TARGET_DIR/.config"

# 6. 权限硬化与缓存清除
# 确保 Runner 有权读取新灌入的零件，并删除 tmp 强制重新索引 Makefile
chmod -R 755 "$ATF_PATH"
chmod -R 755 "$UBOOT_PATH"
rm -rf "$TARGET_DIR/tmp"

echo "--- [物理溯源]：11 个零件已成功通过物理死锁完成投递 ---"
