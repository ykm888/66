#!/bin/bash
# =========================================================
# SL-3000 物理清场脚本 (纠正 feeds 冲突)
# =========================================================

TARGET_DIR="$(pwd)/openwrt"

echo "--- [1/2] 物理粉碎冲突路径 ---"
# 删除所有可能导致索引冲突的同名 ATF 目录
rm -rf "$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek"
rm -rf "$TARGET_DIR/package/feeds/base/arm-trusted-firmware-mediatek"

echo "--- [2/2] 架构锁定初始设置 ---"
true > "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek=y\nCONFIG_TARGET_mediatek_filogic=y\nCONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y\n" >> "$TARGET_DIR/.config"

# 彻底清理旧的 tmp 缓存，迫使系统重新生成索引
rm -rf "$TARGET_DIR/tmp"
