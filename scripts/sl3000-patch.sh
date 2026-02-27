#!/bin/bash
# File: scripts/sl3000-patch.sh

echo "执行物理级错误删除与架构锁定..."

# 1. 物理粉碎
rm -rf tmp
rm -f .config .config.old

# 2. 三件套同步
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "../custom-config/mt7981b-3000-emmc.dts" ] && cp -f "../custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f "../custom-config/filogic.mk" "$MK_DEST"
[ -f "../custom-config/sl3000.config" ] && cp -f "../custom-config/sl3000.config" ".config"

# 3. 【核心物理删除】强制抹除源码中所有 ASR3000 块
# 这一步如果不彻底，系统就会因为 ID 冲突跳转到 x86
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 4. 物理清理：删除 .config 中任何可能残留的 x86 定义
sed -i '/CONFIG_TARGET_x86/d' .config

# 5. 生成配置并执行 Whitespace 物理大清洗
make defconfig
if [ -d "tmp" ]; then
    echo "正在物理清洗生成文件中的空格错误..."
    find tmp/ -name "*.in" -exec sed -i 's/^[[:space:]]*//' {} +
fi

# 6. 二次锁定写入
make defconfig

echo "物理锁定完毕，SL-3000 环境已就绪。"
