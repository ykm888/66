#!/bin/bash
#
# Copyright (C) 2024-2026 ykm888
# 物理修复终极版：物理零件注入与影子清场逻辑
#

# 1. 物理对齐：默认 IP 与主机名
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/SL-3000/g' package/base-files/files/bin/config_generate

# 2. 物理搬运：从硬化分支抓取零件 (ATF/U-Boot)
# 利用临时目录进行物理平移，确保 Makefile 位于第一层级
echo "Physical Surgery: Injecting hardened sources from sl3000-clean-source..."
git clone -b sl3000-clean-source --depth 1 https://github.com/ykm888/66.git hardening_src

# 注入 ATF 零件
mkdir -p package/boot/arm-trusted-firmware-mediatek/src
cp -rf hardening_src/atf/* package/boot/arm-trusted-firmware-mediatek/src/

# 注入 U-Boot 零件
mkdir -p package/boot/uboot-mediatek/src
cp -rf hardening_src/u-boot/* package/boot/uboot-mediatek/src/

# 3. 物理清场：彻底切断 feeds 影子干扰 (防止 Error 1 和零件回滚)
echo "Physical Surgery: Purging shadow packages from feeds..."
rm -rf feeds/mediatek/arm-trusted-firmware-mediatek
rm -rf feeds/mediatek/uboot-mediatek
rm -rf package/feeds/mediatek/arm-trusted-firmware-mediatek
rm -rf package/feeds/mediatek/uboot-mediatek

# 4. 物理对齐：注入 888 核心物理定义
[ -d 888 ] && find target/linux/mediatek/ -type d -name "dts" -exec cp -f 888/mt7981-sl-3000-emmc.dts {} \;
[ -f 888/filogic.mk ] && cp -f 888/filogic.mk target/linux/mediatek/image/

# 5. 物理抹除：Werror 警告屏蔽 (确保 GCC 13+ 兼容)
find package/ -name "Makefile" -exec sed -i 's/-Werror//g' {} +

# 6. 物理清理：刷新索引
rm -rf tmp
rm -rf hardening_src

echo "Physical Surgery: Surgery completed."
