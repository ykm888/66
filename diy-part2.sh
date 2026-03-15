#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理死锁脚本 (禁用 EOF 版)
# =========================================================

SRC_DIR="$(pwd)/888"
TARGET_DIR="$(pwd)/openwrt"

echo "--- [1/4] 物理强灌：覆盖 Makefile 与注入零件 ---"
# 物理覆盖核心编译描述文件
cp -f "$SRC_DIR/atf-Makefile" "$TARGET_DIR/package/boot/arm-trusted-firmware-mediatek/Makefile"
cp -f "$SRC_DIR/uboot-Makefile" "$TARGET_DIR/package/boot/uboot-mediatek/Makefile"

# 注入 U-Boot 设备树与配置
mkdir -p "$TARGET_DIR/package/boot/uboot-mediatek/files"
cp -f "$SRC_DIR/mt7981_sl3000_defconfig" "$TARGET_DIR/package/boot/uboot-mediatek/files/"
cp -f "$SRC_DIR/mt7981-sl-3000-emmc.dts"  "$TARGET_DIR/package/boot/uboot-mediatek/files/"

echo "--- [2/4] 架构纠偏：物理杀除 x86 锁定 MT7981 ---"
# 清空旧配置，防止 x86 架构残留
true > "$TARGET_DIR/.config"

# 使用 printf 逐行注入核心架构参数，确保 100% 识别为 MT7981
printf "CONFIG_TARGET_mediatek=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek_filogic=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_TARGET_mediatek_filogic_DEVICE_mediatek_mt7981-rfb-flash=y\n" >> "$TARGET_DIR/.config"

# 锁定救砖零件变体
printf "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-nor-ddr4=y\n" >> "$TARGET_DIR/.config"
printf "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y\n" >> "$TARGET_DIR/.config"

echo "--- [3/4] 物理爆破：清除索引缓存 ---"
# 彻底删除 tmp，迫使系统重新扫描刚才灌入的架构配置
rm -rf "$TARGET_DIR/tmp"

echo "--- [4/4] 状态验证 ---"
grep "CONFIG_TARGET_mediatek=y" "$TARGET_DIR/.config" && echo "✅ 架构已物理锁定：MediaTek MT7981"
