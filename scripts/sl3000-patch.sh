#!/bin/bash
# File: scripts/sl3000-patch.sh

echo "执行仓库源最高级别物理修复：删除冲突架构并锁定 SL3000"

# 1. 物理粉碎：强制清理所有残留
rm -rf tmp
rm -f .config .config.old
# 核心修复：直接删除源码中的 x86 定义，防止系统逻辑跳转
rm -rf target/linux/x86

# 2. 强制同步三件套路径
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "../custom-config/mt7981b-3000-emmc.dts" ] && cp -f "../custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f "../custom-config/filogic.mk" "$MK_DEST"
[ -f "../custom-config/sl3000.config" ] && cp -f "../custom-config/sl3000.config" ".config"

# 3. 物理切断：抹除 ASR3000，确保 SL3000 是 Mediatek 下的唯一选择
sed -i '/Device\/abt_asr3000/,/endef/d' "$MK_DEST"

# 4. 物理修正 IP
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 解决 Whitespace 报错：生成索引后进行物理清洗
make defconfig
if [ -d "tmp" ]; then
    echo "物理大清洗：正在删除生成文件中的 Leading Whitespace..."
    find tmp/ -name "*.in" -exec sed -i 's/^[[:space:]]*//' {} +
fi

# 6. 最终物理确认：再次执行确保配置锁定在 SL-3000
make defconfig

echo "物理隔离完成，SL-3000 架构已强制锁定。"
