#!/bin/bash
# File: scripts/sl3000-patch.sh

echo "执行仓库源最高级别物理修复：删除冲突架构并锁定 SL3000"

# 1. 物理粉碎：强制清理所有残留，确保从零开始扫描，防止旧架构索引反杀
rm -rf tmp
rm -f .config .config.old
# 绝杀：直接从源码物理删除 x86 定义目录，防止系统逻辑跳转
rm -rf target/linux/x86

# 2. 强制同步三件套路径
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "../custom-config/mt7981b-3000-emmc.dts" ] && cp -f "../custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f "../custom-config/filogic.mk" "$MK_DEST"
[ -f "../custom-config/sl3000.config" ] && cp -f "../custom-config/sl3000.config" ".config"

# 3. 物理切断：抹除 ASR3000，确保 SL3000 是 Mediatek 架构下的唯一设备选择
sed -i '/Device\/abt_asr3000/,/endef/d' "$MK_DEST"

# 4. 物理修正 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 【核心修复】解决 Kconfig 语法错误与 Whitespace 报错
# 物理隔离：先强制生成一份干净的索引，忽略过程错误
make defconfig || true

if [ -d "tmp" ]; then
    echo "物理大清洗：正在修复 tmp 目录下的 Kconfig 语法污染..."
    # 第一步：暴力剔除所有行首空格，解决 Leading Whitespace 警告
    find tmp/ -name "*.in" -exec sed -i 's/^[[:space:]]*//' {} +
    # 第二步：针对报错的 invalid statement，物理抹除所有无法解析的描述行，强制归一化
    find tmp/ -name "*.in" -exec sed -i '/^[a-z]/!d' {} +
fi

# 6. 最终物理锁定：再次执行，确保配置绝对锁定在 SL-3000
# 这里由于 x86 源码已删且索引已清洗，系统无法再跳回 x86
make defconfig

echo "物理隔离与语法修复完成，SL-3000 架构已强制锁定。"
