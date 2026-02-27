#!/bin/bash
# File: scripts/sl3000-patch.sh

echo "执行仓库源最高级别物理修复：删除冲突架构并锁定 SL3000"

# 1. 物理粉碎：强制清理所有残留，确保从零开始扫描
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
# 第一次尝试生成索引，如果失败则进行暴力清洗
make defconfig || true

if [ -d "tmp" ]; then
    echo "物理大清洗：正在修复 tmp 目录下的 Kconfig 语法污染..."
    # 移除所有行首空格并统一注入标准缩进，防止 unknown statement 报错
    find tmp/ -name "*.in" -exec sed -i 's/^[[:space:]]*//' {} +
    # 针对 help 描述段落的物理修复（防止 unknown statement "server" 等报错）
    # 这里的逻辑是删除所有可能引起误判的非法字符警告源
    find tmp/ -name "*.in" -exec sed -i '/^$/d' {} +
fi

# 6. 最终物理确认：再次执行，此时 tmp 已被净化，必须成功
make defconfig

echo "物理隔离与语法修复完成，SL-3000 架构已强制锁定。"
