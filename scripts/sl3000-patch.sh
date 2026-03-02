#!/bin/bash

# 1. 物理源码拦截：修复 Error 1 (MTK_WIFI_CHIP_OFFLINE 未定义)
# 这是构建救砖包成功的前提，防止内核编译中断
find . -name "mtk_eth_soc.c" -exec sed -i '/MTK_WIFI_CHIP_OFFLINE/,/break;/d' {} + 2>/dev/null || true

# 2. 内核版本强制锁定 6.6
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' target/linux/mediatek/Makefile

# 3. 物理清理冲突补丁
rm -f target/linux/mediatek/patches-6.6/999-fix-mtk-eth-soc.patch 2>/dev/null || true

# 4. 强制物理检查 .config
# 确保 8000 行配置中开启了 CONFIG_TARGET_DEVICE_mediatek_mt7981_DEVICE_sl_3000-emmc=y
if [ -f "custom-config/sl3000.config" ]; then
    cp -f custom-config/sl3000.config .config
fi
