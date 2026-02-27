#!/bin/bash
# File: scripts/sl3000-patch.sh

echo "正在执行终极整合修复逻辑..."

# 1. 物理粉碎残留索引 (根除 whitespace 警告)
rm -rf tmp
rm -f .config .config.old

# 2. 三件套路径物理同步
DTS_DEST="target/linux/mediatek/dts"
MK_DEST="target/linux/mediatek/image/filogic.mk"
mkdir -p "$DTS_DEST"

# 物理同步：从根目录的 custom-config 同步至源码对应位置
[ -f "../custom-config/mt7981b-3000-emmc.dts" ] && cp -f "../custom-config/mt7981b-3000-emmc.dts" "$DTS_DEST/mt7981b-3000-emmc.dts"
[ -f "../custom-config/filogic.mk" ] && cp -f "../custom-config/filogic.mk" "$MK_DEST"
[ -f "../custom-config/sl3000.config" ] && cp -f "../custom-config/sl3000.config" ".config"

# 3. 物理屏蔽：彻底抹除 ASR3000 硬件段防止干扰
sed -i '/Device\/abt_asr3000/,/endef/d' target/linux/mediatek/image/filogic.mk

# 4. 物理修改 IP 地址 (192.168.6.1)
sed -i 's/192.168.1.1/192.168.6.1/g' package/base-files/files/bin/config_generate

# 5. 强制物理重扫：确保内核 6.6 的 U-Boot 救砖驱动生效
make defconfig

echo "整合脚本执行完毕。"
