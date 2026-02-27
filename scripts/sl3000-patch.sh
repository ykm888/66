#!/bin/bash
# File: scripts/sl3000-patch.sh

echo "执行仓库源最高级别物理修复：锁定 SL-3000 并执行核弹级 Kconfig 闭环"

# 1. 物理粉碎：清理旧缓存，确保索引重建
rm -rf tmp
rm -f .config .config.old
# 绝杀：物理删除 x86 源码路径，防止系统逻辑回跳
rm -rf target/linux/x86

# 2. 强制同步三件套路径
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

[ -f "../custom-config/mt7981b-3000-emmc.dts" ] && cp -f "../custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f "../custom-config/filogic.mk" "$MK_DEST"
[ -f "../custom-config/sl3000.config" ] && cp -f "../custom-config/sl3000.config" ".config"

# 3. 物理切断：抹除 ASR3000 冗余定义
sed -i '/Device\/abt_asr3000/,/endef/d' "$MK_DEST"

# 4. 物理修正 IP (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 【定向清洗】处理索引并静默警告
make defconfig > /dev/null 2>&1 || true

if [ -d "tmp" ]; then
    find tmp/ -name "*.in" -type f -exec sed -i 's/^[[:space:]]*//' {} +
fi

# 6. 【核心修复】使用官方脚本强制合并配置，彻底终结交互询问
# 物理注入：直接在内核配置模板中开启必需项
sed -i '/MTD_OF_PARTS_AIROHA/d' target/linux/mediatek/config-6.6
echo "CONFIG_MTD_OF_PARTS_AIROHA=y" >> target/linux/mediatek/config-6.6
echo "CONFIG_MTD_CMDLINE_PARTS=y" >> target/linux/mediatek/config-6.6

# 物理强制刷新：强制同步 .config 与内核配置，不留任何 NEW 选项
./scripts/kconfig.pl 'm+' '+' .config /dev/null > .config.new
mv .config.new .config

# 7. 最终锁定（物理强显模式）
if make defconfig; then
    echo "================================================="
    echo "物理审计成功：SL-3000 架构锁定，交互死锁已物理清除！"
    echo "================================================="
else
    echo "严重警报：make defconfig 失败，正在执行物理强推..."
    # 强制尝试最后一次，不带输出过滤以便查看真实原因
    make defconfig V=s || exit 1
fi

echo "物理修复完成。"
