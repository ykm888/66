#!/bin/bash
# =========================================================
# SL-3000 救砖零件物理投递脚本 (2026 最终加固版)
# =========================================================

echo "--- [物理溯源]：正在投递 11 个零件至预埋区 ---"

# 1. 物理目录初始化
ATF_PATH="package/boot/arm-trusted-firmware-mediatek"
UBOOT_PATH="package/boot/uboot-mediatek"

mkdir -p $ATF_PATH/files $UBOOT_PATH/files

# 2. 强灌 Makefile (这是劫持编译流程的司令部)
[ -f 888/atf-Makefile ] && cp -f 888/atf-Makefile $ATF_PATH/Makefile
[ -f 888/uboot-Makefile ] && cp -f 888/uboot-Makefile $UBOOT_PATH/Makefile

# 3. 投递 ATF 1MB 偏移补丁零件
cp -f 888/bl2_dev_spi_nor.c $ATF_PATH/files/
cp -f 888/platform_def.h $ATF_PATH/files/
cp -f 888/platform.mk $ATF_PATH/files/
cp -f 888/bl2.mk $ATF_PATH/files/
cp -f 888/mt7981-spi2.dts $ATF_PATH/files/

# 4. 投递 U-Boot 分区对齐零件
cp -f 888/mt7981_sl3000_defconfig $UBOOT_PATH/files/
cp -f 888/mt7981-sl3000.dts $UBOOT_PATH/files/

# 5. 【核心修复】物理锁定包名，防止 Skipping
# 强制在 .config 结尾注入，确保优先级最高
echo "CONFIG_PACKAGE_arm-trusted-firmware-mediatek-mt7981-sl3000-nor=y" >> .config
echo "CONFIG_PACKAGE_uboot-mediatek-mt7981_sl3000=y" >> .config

# 6. 清理缓存，强制重新扫描 Makefile 变体
rm -rf tmp
echo "--- [物理溯源]：零件投递与激活指令已就位 ---"
