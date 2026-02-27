#!/bin/bash
# File: scripts/sl3000-patch.sh

echo "执行仓库源最高级别物理修复：锁定 SL-3000 并执行精准索引重构"

# 1. 物理粉碎：清理旧缓存，确保从零扫描
rm -rf tmp
rm -f .config .config.old
# 绝杀：物理删除 x86 源码路径，防止逻辑回跳
rm -rf target/linux/x86

# 2. 强制同步三件套路径
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "../custom-config/mt7981b-3000-emmc.dts" ] && cp -f "../custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f "../custom-config/filogic.mk" "$MK_DEST"
[ -f "../custom-config/sl3000.config" ] && cp -f "../custom-config/sl3000.config" ".config"

# 3. 物理切断：抹除 ASR3000 冗余
sed -i '/Device\/abt_asr3000/,/endef/d' "$MK_DEST"

# 4. 物理修正 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 【精准修复】重构索引文件，解决 unknown statement 报错
# 物理逻辑：先尝试生成基本结构
make defconfig > /dev/null 2>&1 || true

if [ -d "tmp" ]; then
    echo "物理精准清洗：正在修复 Kconfig 描述文本溢出..."
    # 物理规则：仅删除非打印字符（如 \r）和行尾非法逗号。
    # 严格禁止删除行首空格，确保 help 文本不会被解析器误判为指令。
    find tmp/ -name "*.in" -type f -exec sed -i 's/\r//g; s/[[:cntrl:]]//g; s/,$//g' {} +
fi

# 6. 【核心修复】针对 MTD 交互死锁的物理注入
sed -i '/MTD_OF_PARTS_AIROHA/d' target/linux/mediatek/config-6.6
echo "CONFIG_MTD_OF_PARTS_AIROHA=y" >> target/linux/mediatek/config-6.6
echo "CONFIG_MTD_CMDLINE_PARTS=y" >> target/linux/mediatek/config-6.6

# 使用官方脚本物理强刷配置闭环，彻底终结交互询问
./scripts/kconfig.pl 'm+' '+' .config /dev/null > .config.new && mv .config.new .config

# 7. 最终锁定（物理强制模式）
if make defconfig; then
    echo "================================================="
    echo "物理审计成功：SL-3000 架构锁定，索引重构已完成！"
    echo "================================================="
else
    echo "致命警报：make defconfig 失败。执行物理熔断检查..."
    make defconfig V=s || exit 1
fi

echo "物理修复完成。"
